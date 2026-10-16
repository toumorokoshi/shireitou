/// The session view: header, timeline and follow-up input (AV-060 to
/// AV-067, AV-080 to AV-084).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../connection_notices.dart';
import '../host_connection.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/session_list_view.dart';
import '../session_list/status_badges.dart';
import '../channels.dart';
import '../review/changes_pane.dart';
import '../review/review_logic.dart';
import 'chat_commands.dart';
import '../composer/config_fields.dart';
import 'chat_switcher.dart';
import 'message_settings.dart';
import 'pending_messages.dart';
import 'session_info.dart';
import 'session_inputs.dart';
import 'session_status_widgets.dart';
import 'timeline_items.dart';
import 'timeline_parts.dart';
import 'tool_previews.dart';

/// Shows [session]: subscribes to it and its default chat while visible and
/// marks it read when opened (AV-023). Other chats of the session open
/// from the chat switcher (AV-069). The "Files changed" review (AV-100)
/// is a side pane when [reviewAsPane], else a tab.
class SessionDetailView extends ConsumerStatefulWidget {
  /// Creates a [SessionDetailView]. Give it a key per session.
  const SessionDetailView({
    super.key,
    required this.session,
    this.reviewAsPane = false,
  });

  /// The session's URI as the catalogue lists it.
  final String session;

  /// Whether the review sits beside the timeline (wide layouts).
  final bool reviewAsPane;

  @override
  ConsumerState<SessionDetailView> createState() => _SessionDetailViewState();
}

/// Width of the review pane on wide layouts.
const reviewPaneWidth = 380.0;

class _SessionDetailViewState extends ConsumerState<SessionDetailView> {
  late final HostConnection _connection;
  StreamSubscription<ActionFailure>? _failures;

  /// The default chat, subscribed by `openSession`.
  String? _defaultChat;

  /// The chat the timeline shows; another chat is subscribed while open.
  String? _selectedChat;
  Object? _error;
  bool _opening = true;

  /// Set by "Mark unread", which stops marking the session read while it
  /// stays open.
  bool _keepUnread = false;

  String? get _chat => _selectedChat ?? _defaultChat;

  @override
  void initState() {
    super.initState();
    _connection = ref.read(hostConnectionProvider(context.host).notifier);
    _failures = _connection.failures.listen(
      (failure) => _showMessage(describeActionFailure(failure)),
    );
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final chat = await _connection.openSession(widget.session);
      if (!mounted) {
        _connection.closeSession(widget.session, chat);
        return;
      }
      setState(() {
        _defaultChat = chat;
        _opening = false;
      });
      final summary = ref
          .read(hostConnectionProvider(context.host))
          .sessions[widget.session];
      if (summary != null && !summary.status.isReadFlag) _setRead(true);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _opening = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_failures?.cancel());
    if (!_opening) _connection.closeSession(widget.session, _defaultChat);
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _dispatch(String channel, JsonMap action) {
    try {
      _connection.dispatch(channel, action);
    } on StateError catch (error) {
      _showMessage('Could not send that: ${error.message}');
    }
  }

  Future<void> _authenticate({
    required String resource,
    required String token,
  }) => _connection.authenticate(resource: resource, token: token);

  void _setRead(bool read) => _dispatch(
    widget.session,
    SessionIsReadChangedAction(isRead: read).toJson(),
  );

  void _setArchived(bool archived) => _dispatch(
    widget.session,
    SessionIsArchivedChangedAction(isArchived: archived).toJson(),
  );

  void _selectChat(String chat) =>
      setState(() => _selectedChat = chat == _defaultChat ? null : chat);

  Future<void> _moveChat(SessionState session, String chat, int delta) async {
    final destination = chatMoveDestination(
      widget.session,
      session,
      chat,
      delta,
    );
    if (destination == null) return;
    try {
      await _connection.moveChat(chat, destination);
    } on Object catch (error) {
      _showMessage('Could not move the chat: $error');
    }
  }

  Future<void> _loadOlder(String chat) async {
    try {
      await _connection.loadOlderTurns(chat);
    } on Object catch (error) {
      _showMessage('Could not load older turns: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // New turns clear IsRead; while the session is open, it stays read.
    ref.listen(
      hostConnectionProvider(context.host)
          .select((s) => s.sessions[widget.session]?.status.isReadFlag),
      (_, read) {
        if (read == false && !_opening && !_keepUnread) {
          // Not from inside the provider's notification.
          scheduleMicrotask(() => _setRead(true));
        }
      },
    );
    final summary = ref.watch(
      hostConnectionProvider(context.host)
          .select((s) => s.sessions[widget.session]),
    );
    final sessionState = ref.watch(
      hostConnectionProvider(context.host)
          .select((s) => s.sessionChannels[widget.session]?.state),
    );
    final chats = switchableChats(sessionState);
    // A chat the session no longer lists falls back to the default one.
    if (_selectedChat case final selected?
        when sessionState != null &&
            !chats.any((c) => c.resource == selected)) {
      _selectedChat = null;
    }
    final chatUri = _chat;
    final chat = chatUri == null
        ? null
        : ref.watch(
            hostConnectionProvider(context.host)
                .select((s) => s.chatChannels[chatUri]?.state),
          );
    final protocolVersion = ref.watch(
      hostConnectionProvider(context.host).select((s) => s.protocolVersion),
    );
    bool supports(ProtocolFeature f) => supportsFeature(protocolVersion, f);
    final prompts = sessionPrompts(sessionState, chat);
    // The host could not resume the session after a reconnect (AHP-004).
    final missing = ref.watch(
      hostConnectionProvider(context.host).select(
        (s) =>
            s.missingChannels.contains(widget.session) ||
            (chatUri != null && s.missingChannels.contains(chatUri)),
      ),
    );
    final summaryOfChat = chats.where((c) => c.resource == chatUri).firstOrNull;
    final readOnly =
        (chat?.interactivity ?? summaryOfChat?.interactivity) ==
        ChatInteractivity.readOnly;
    final timeline = switch ((chat, _error)) {
      _ when missing => const Center(
        child: Text('This session is no longer available on the host.'),
      ),
      (_, final error?) => Center(child: Text('Could not open: $error')),
      (null, _) when _opening || _selectedChat != null => const Center(
        child: CircularProgressIndicator(),
      ),
      (null, _) => const Center(child: Text('This session has no chat.')),
      (final chat?, _) => _Timeline(
        key: ValueKey(chatUri),
        chat: chat,
        onAction: (action) => _dispatch(chatUri!, action),
        onAuthenticate: _authenticate,
        onOpenChat: _selectChat,
        onLoadOlder: () => _loadOlder(chatUri!),
      ),
    };
    final pending = chat == null
        ? const <PendingMessageItem>[]
        : pendingMessages(chat);
    // Model and mode pickers (AV-041): models of the session's agent, and
    // the session settings that may change mid-session.
    final provider = summary?.provider ?? sessionState?.provider;
    final models = ref.watch(
      hostConnectionProvider(context.host).select(
        (s) =>
            s.root?.agents
                .where((a) => a.provider == provider)
                .firstOrNull
                ?.models ??
            const <SessionModelInfo>[],
      ),
    );
    final sessionFields = mutableSessionFields(sessionState?.config);
    final conversation = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chats.length > 1 && !missing) ...[
          ChatSwitcher(
            chats: chats,
            selected: chatUri,
            onSelect: _selectChat,
            onMove: supports(ProtocolFeature.moveChat) && sessionState != null
                ? (chat, delta) => _moveChat(sessionState, chat, delta)
                : null,
          ),
          const Divider(height: 1),
        ],
        if (prompts.isNotEmpty && !missing) ...[
          SessionInputPanel(
            prompts: prompts,
            session: sessionState,
            openChat: chatUri,
            onDispatch: _dispatch,
            onAuthenticate: _authenticate,
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: _selectedChat == null
              ? timeline
              : ChannelSubscriber(
                  key: ValueKey(_selectedChat),
                  channel: _selectedChat!,
                  kind: ChannelKind.chat,
                  builder: (context, failed) => failed && chat == null
                      ? const Center(child: Text('Could not open this chat.'))
                      : timeline,
                ),
        ),
        if (pending.isNotEmpty)
          PendingMessagesPanel(
            pending: pending,
            onAction: (action) => _dispatch(chatUri!, action),
          ),
        if (chat != null && readOnly)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('This chat is read-only.'),
          )
        else if (chat != null)
          FollowUpInput(
            key: ValueKey(chatUri),
            working: chat.activeTurn != null,
            draft: chat.draft,
            models: models,
            initialModel: lastModelSelection(chat),
            sessionFields: sessionFields,
            sessionValues: sessionState?.config?.values ?? const {},
            onSessionSettingChanged: (id, value) => _dispatch(
              widget.session,
              SessionConfigChangedAction(config: {id: value}).toJson(),
            ),
            onDraftChanged: (text) =>
                _dispatch(chatUri!, draftAction(text, previous: chat.draft)),
            onSend: (text, {required steer, model}) => _dispatch(
              chatUri!,
              sendMessageAction(
                chat,
                text: text,
                id: const Uuid().v4(),
                now: DateTime.now(),
                steer: steer,
                model: model,
              ),
            ),
          ),
      ],
    );
    final hasChanges = availableChangesets(
      sessionState,
      chat,
      chatChangesets: supports(ProtocolFeature.chatChangesets),
    ).isNotEmpty;
    final review = ChangesPane(session: widget.session, chat: chatUri);
    final header = _Header(
      summary: summary,
      chat: chat,
      backgroundWork: supports(ProtocolFeature.backgroundWork)
          ? chat?.backgroundWork ?? const []
          : const [],
      canvases: supports(ProtocolFeature.canvases)
          ? chat?.canvases ?? const []
          : const [],
      mcpAlerts: mcpServerAlerts(sessionState),
      onAuthenticate: _authenticate,
      onOpenChat: _selectChat,
      onStop: chat == null || readOnly
          ? null
          : () {
              final action = stopAction(chat, DateTime.now());
              if (action != null) _dispatch(chatUri!, action);
            },
      onArchive: _setArchived,
      onMarkUnread: () {
        _keepUnread = true;
        _setRead(false);
      },
      onDetails: () =>
          showSessionInfo(context, session: widget.session, chat: chatUri),
    );
    if (widget.reviewAsPane) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const Divider(height: 1),
                Expanded(child: conversation),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(width: reviewPaneWidth, child: review),
        ],
      );
    }
    if (!hasChanges || missing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          Expanded(child: conversation),
        ],
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const TabBar(
            tabs: [
              Tab(text: 'Conversation'),
              Tab(text: 'Files changed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [conversation, review],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title, agent, model, folder, status, activity and actions (AV-060).
class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.chat,
    required this.backgroundWork,
    required this.canvases,
    required this.mcpAlerts,
    required this.onAuthenticate,
    required this.onOpenChat,
    required this.onStop,
    required this.onArchive,
    required this.onMarkUnread,
    required this.onDetails,
  });

  final SessionSummary? summary;
  final ChatState? chat;
  final List<BackgroundWork> backgroundWork;
  final List<CanvasReference> canvases;
  final List<McpServerAlert> mcpAlerts;
  final Authenticate onAuthenticate;
  final OpenChat onOpenChat;
  final VoidCallback? onStop;
  final ValueChanged<bool> onArchive;
  final VoidCallback onMarkUnread;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = this.summary;
    final chat = this.chat;
    final status = chat?.status ?? summary?.status;
    final activity = chat?.activity ?? summary?.activity;
    final model = chat == null ? null : lastModelOf(chat);
    final usage = chat == null ? null : sessionUsage(chat);
    final archived = status?.isArchivedFlag ?? false;
    final details = [
      ?summary?.provider,
      ?model,
      if (summary != null) folderKeyOf(summary) ?? noFolderLabel,
      if (summary != null)
        if (worktreeInfoOf(summary).branch case final branch?) '⎇ $branch',
      if (usage != null && usage.input + usage.output > 0)
        '${usage.input} in · ${usage.output} out tokens',
      ?changesLabel(summary?.changes ?? chat?.changes),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary?.title ?? chat?.title ?? 'Session',
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  details.join(' · '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (status != null)
                      for (final badge in badgesFor(status))
                        StatusBadgeChip(badge: badge),
                    if (backgroundWork.isNotEmpty)
                      BackgroundWorkChip(
                        work: backgroundWork,
                        onOpenChat: onOpenChat,
                      ),
                    if (canvases.isNotEmpty) CanvasChips(canvases: canvases),
                    if (mcpAlerts.isNotEmpty)
                      McpServerAlertChips(
                        alerts: mcpAlerts,
                        onAuthenticate: onAuthenticate,
                      ),
                    if (activity != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          activity,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (chat?.activeTurn != null && onStop != null)
            FilledButton.tonalIcon(
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Session actions',
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => onArchive(!archived),
                child: Text(archived ? 'Unarchive' : 'Archive'),
              ),
              PopupMenuItem(
                value: onMarkUnread,
                child: const Text('Mark unread'),
              ),
              PopupMenuItem(
                value: onDetails,
                child: const Text('Session details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The turns, newest at the bottom, following new output unless the user
/// scrolled up (AV-066). Rows are built lazily and keyed, so finished
/// turns are not rebuilt while one streams and older turns paged in at
/// the top (AV-068) do not disturb the rows below.
class _Timeline extends StatefulWidget {
  const _Timeline({
    super.key,
    required this.chat,
    required this.onAction,
    required this.onAuthenticate,
    required this.onOpenChat,
    required this.onLoadOlder,
  });

  final ChatState chat;
  final ValueChanged<JsonMap> onAction;
  final Authenticate onAuthenticate;
  final OpenChat onOpenChat;
  final VoidCallback onLoadOlder;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  final _scroll = ScrollController();
  bool _awayFromLatest = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final away = _scroll.offset > 200;
      if (away != _awayFromLatest) setState(() => _awayFromLatest = away);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = timelineItems(widget.chat);
    if (rows.isEmpty) {
      return const Center(child: Text('No messages yet. Say something.'));
    }
    // A reversed list keeps the newest row in view as it grows, and stays
    // put once the user scrolls up.
    return Stack(
      children: [
        SelectionArea(
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: rows.length,
            findChildIndexCallback: (key) {
              if (key is! ValueKey<String>) return null;
              final index = rows.indexOfKey(key.value);
              return index == null ? null : rows.length - 1 - index;
            },
            itemBuilder: (context, index) {
              final item = rows[rows.length - 1 - index];
              return KeyedSubtree(
                key: ValueKey(item.key),
                child: buildTimelineItem(
                  item,
                  widget.onAction,
                  onAuthenticate: widget.onAuthenticate,
                  onOpenChat: widget.onOpenChat,
                  onLoadOlder: widget.onLoadOlder,
                ),
              );
            },
          ),
        ),
        if (_awayFromLatest)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              tooltip: 'Jump to latest',
              onPressed: () => _scroll.animateTo(
                0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }
}

/// Sends [text] with [model] (null for the host's default); [steer] asks
/// to deliver it at the agent's next step.
typedef SendMessage = void Function(
  String text, {
  required bool steer,
  ModelSelection? model,
});

/// The follow-up box (AV-080): Enter sends (or queues while working),
/// Cmd/Ctrl+Enter sends now while working, Shift+Enter adds a newline.
/// It starts from the chat's [draft] and syncs what the user types back
/// as the draft, debounced ([onDraftChanged], `chat/draftChanged`).
/// Above it, [MessageSettingsBar] picks the model (and its options) for
/// the next message, starting from [initialModel], and changes the
/// session's mutable settings.
class FollowUpInput extends StatefulWidget {
  /// Creates a [FollowUpInput].
  const FollowUpInput({
    super.key,
    required this.working,
    required this.onSend,
    this.draft,
    this.onDraftChanged,
    this.draftDelay = const Duration(milliseconds: 800),
    this.models = const [],
    this.initialModel,
    this.sessionFields = const [],
    this.sessionValues = const {},
    this.onSessionSettingChanged,
  });

  /// The agent's models; no pickers when empty and there are no
  /// [sessionFields].
  final List<SessionModelInfo> models;

  /// The model the chat last used (`Message.model`).
  final ModelSelection? initialModel;

  /// Session settings that may change mid-session.
  final List<ConfigField> sessionFields;

  /// Their current values.
  final Map<String, Object?> sessionValues;

  /// Changes a session setting (`session/configChanged`).
  final void Function(String id, Object? value)? onSessionSettingChanged;

  /// Whether a turn is running.
  final bool working;

  /// Called with the message text.
  final SendMessage onSend;

  /// The chat's draft, from this or another client.
  final Message? draft;

  /// Syncs the box's text as the draft; an empty string clears it.
  final ValueChanged<String>? onDraftChanged;

  /// How long typing must pause before the draft is synced.
  final Duration draftDelay;

  @override
  State<FollowUpInput> createState() => _FollowUpInputState();
}

class _FollowUpInputState extends State<FollowUpInput> {
  late final _text = TextEditingController(text: widget.draft?.text ?? '');
  late final _focus = FocusNode(onKeyEvent: _onKey);
  Timer? _draftTimer;

  /// The text last synced with the chat's draft (sent or adopted).
  late String _synced = widget.draft?.text ?? '';

  /// The model for the next message; follows [FollowUpInput.initialModel]
  /// until the user picks one.
  late ModelSelection? _model = widget.initialModel;
  bool _pickedModel = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(FollowUpInput old) {
    super.didUpdateWidget(old);
    if (!_pickedModel && widget.initialModel != old.initialModel) {
      _model = widget.initialModel;
    }
    final remote = widget.draft?.text ?? '';
    // Another client changed the draft, and the user has not typed since
    // the last sync: show theirs.
    if (remote != (old.draft?.text ?? '') &&
        remote != _text.text &&
        _text.text == _synced) {
      _synced = remote;
      _text.value = TextEditingValue(
        text: remote,
        selection: TextSelection.collapsed(offset: remote.length),
      );
    }
  }

  @override
  void dispose() {
    _flushDraft();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (widget.onDraftChanged == null || _text.text == _synced) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(widget.draftDelay, _flushDraft);
  }

  void _flushDraft() {
    _draftTimer?.cancel();
    _draftTimer = null;
    final text = _text.text;
    if (text == _synced) return;
    _synced = text;
    widget.onDraftChanged?.call(text);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed) return KeyEventResult.ignored;
    _send(steer: keyboard.isMetaPressed || keyboard.isControlPressed);
    return KeyEventResult.handled;
  }

  void _send({required bool steer}) {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, steer: steer, model: _model);
    _draftTimer?.cancel();
    final hadDraft = _synced.isNotEmpty || (widget.draft != null);
    _synced = '';
    _text.clear();
    // The message is sent, so the draft is cleared.
    if (hadDraft) widget.onDraftChanged?.call('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.models.isNotEmpty || widget.sessionFields.isNotEmpty)
        MessageSettingsBar(
          models: widget.models,
          model: _model,
          onModelChanged: (model) => setState(() {
            _model = model;
            _pickedModel = true;
          }),
          sessionFields: widget.sessionFields,
          sessionValues: widget.sessionValues,
          onSessionSettingChanged: widget.onSessionSettingChanged,
        ),
      _input(context),
    ],
  );

  Widget _input(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            focusNode: _focus,
            minLines: 1,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: widget.working
                  ? 'Queue a follow-up (Enter) or steer now (Ctrl/Cmd+Enter)'
                  : 'Send a follow-up (Enter; Shift+Enter for a newline)',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: widget.working ? 'Queue' : 'Send',
          icon: Icon(widget.working ? Icons.schedule_send : Icons.send),
          onPressed: () => _send(steer: false),
        ),
      ],
    ),
  );
}
