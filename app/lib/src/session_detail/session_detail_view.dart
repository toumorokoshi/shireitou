/// The session view: header, timeline and follow-up input (AV-060 to
/// AV-067, AV-080 to AV-084).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../auth/sign_in_dialog.dart';
import '../connection_notices.dart';
import '../host_connection.dart';
import '../layout.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/pinned_store.dart';
import '../session_list/session_list_view.dart';
import '../session_list/status_badges.dart';
import '../shortcuts.dart';
import '../channels.dart';
import '../review/changes_pane.dart';
import '../review/review_pane_store.dart';
import '../review/review_logic.dart';
import '../runs/compare_screen.dart';
import '../runs/run_group_store.dart';
import '../runs/run_groups.dart';
import '../session_title.dart';
import 'chat_commands.dart';
import '../composer/config_fields.dart';
import 'chat_switcher.dart';
import 'editable_title.dart';
import 'message_settings.dart';
import 'pending_messages.dart';
import 'session_info.dart';
import 'session_inputs.dart';
import 'session_status_widgets.dart';
import 'source_links.dart';
import 'timeline_items.dart';
import 'timeline_parts.dart';
import 'todo_list.dart';
import 'todo_widgets.dart';
import 'tool_previews.dart';
import 'turn_markers.dart';
import 'turn_rail.dart';

/// Shows [session]: subscribes to it and its default chat while visible and
/// marks it read when opened (AV-023). Other chats of the session open
/// from the chat switcher (AV-069). The "Files changed" review (AV-100)
/// is a side pane when [reviewAsPane] (closed until the user opens it,
/// AV-003), else a tab.
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

/// How long an answer from the "Waiting for you" panel stays hidden
/// without the host removing its entry (the client's pending-action
/// timeout, AHP-022).
const answerConfirmTimeout = Duration(seconds: 30);

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

  /// Answers sent from the "Waiting for you" panel that the host has not
  /// confirmed yet, by entry id; hidden meanwhile. A timer shows each one
  /// again if the host never removes it.
  final _answered = <String, AnsweredPrompt>{};
  final _answerTimers = <String, Timer>{};

  /// Client tool executions this client already turned down, by entry id.
  final _declined = <String>{};

  /// Asks the follow-up box to take focus (Cmd/Ctrl+L, AV-140).
  final _composerFocus = ValueNotifier<int>(0);

  /// Opens the title's text field (the "Rename…" menu item, AV-073).
  final _renameRequests = ValueNotifier<int>(0);
  StreamSubscription<AppCommand>? _commands;

  String? get _chat => _selectedChat ?? _defaultChat;

  @override
  void initState() {
    super.initState();
    _connection = ref.read(hostConnectionProvider(context.host).notifier);
    _failures = _connection.failures.listen(_onFailure);
    _commands = ref.read(appCommandsProvider).stream.listen(_onCommand);
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

  /// Reports an undone action of this session (actions on other sessions
  /// are the session list's), and shows an answer the host refused in the
  /// "Waiting for you" panel again.
  void _onFailure(ActionFailure failure) {
    if (answerUndoneBy(_answered, failure) case final id?) {
      setState(() => _forgetAnswer(id));
    }
    final session = ref
        .read(hostConnectionProvider(context.host))
        .sessionChannels[widget.session]
        ?.state;
    final ours =
        failure.channel == widget.session ||
        failure.channel == _defaultChat ||
        failure.channel == _selectedChat ||
        (session?.chats.any((c) => c.resource == failure.channel) ?? false);
    if (ours) _showMessage(describeActionFailure(failure));
  }

  void _forgetAnswer(String id) {
    _answered.remove(id);
    _answerTimers.remove(id)?.cancel();
  }

  /// Sends [action], answering [entry] from the "Waiting for you" panel,
  /// and hides the entry until the host removes it (AV-083, AV-084). The
  /// chat may not be mirrored, so the client cannot apply the answer
  /// locally; a rejection, or no removal within the client's
  /// pending-action timeout, shows the entry again.
  void _answer(SessionInputRequest entry, JsonMap action) {
    final int seq;
    try {
      seq = _connection.dispatch(entry.chat, action);
    } on StateError catch (error) {
      _showMessage('Could not send that: ${error.message}');
      return;
    }
    if (!answerActionTypes.contains(action['type'])) return;
    setState(() {
      _forgetAnswer(entry.id);
      _answered[entry.id] = (chat: entry.chat, clientSeq: seq);
      _answerTimers[entry.id] = Timer(answerConfirmTimeout, () {
        if (!mounted || !_answered.containsKey(entry.id)) return;
        final open = ref
            .read(hostConnectionProvider(context.host))
            .sessionChannels[widget.session]
            ?.state
            .inputNeeded
            ?.any((e) => e.id == entry.id);
        setState(() => _forgetAnswer(entry.id));
        if (open != true) return;
        _showMessage(
          'The host did not confirm your answer. You can answer again.',
        );
      });
    });
  }

  /// Turns down tool executions the host delegated to this client, which
  /// provides no tools (see [ownClientExecutions]).
  void _declineOwnExecutions(SessionState? session) {
    for (final entry in ownClientExecutions(session, _connection.clientId)) {
      if (!_declined.add(entry.id)) continue;
      scheduleMicrotask(
        () => _dispatch(entry.chat, declineClientExecutionAction(entry)),
      );
    }
  }

  void _onCommand(AppCommand command) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    switch (command) {
      case AppCommand.stop:
        final chatUri = _chat;
        final chat = chatUri == null
            ? null
            : ref
                  .read(hostConnectionProvider(context.host))
                  .chatChannels[chatUri]
                  ?.state;
        if (chat == null || chat.interactivity == ChatInteractivity.readOnly) {
          return;
        }
        final action = stopAction(chat, DateTime.now());
        if (action != null) _dispatch(chatUri!, action);
      case AppCommand.focusComposer:
        _composerFocus.value++;
      case AppCommand.toggleReviewPane:
        if (widget.reviewAsPane) {
          unawaited(ref.read(reviewPaneOpenProvider.notifier).toggle());
        }
      case AppCommand.newSession ||
          AppCommand.searchSessions ||
          AppCommand.nextSession ||
          AppCommand.previousSession:
        // The session list handles these.
        break;
      case AppCommand.previousTurn || AppCommand.nextTurn:
        // The timeline handles these.
        break;
    }
  }

  @override
  void dispose() {
    unawaited(_failures?.cancel());
    unawaited(_commands?.cancel());
    for (final timer in _answerTimers.values) {
      timer.cancel();
    }
    _composerFocus.dispose();
    _renameRequests.dispose();
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

  Future<void> _signIn(AuthChallenge challenge) =>
      signInFromUi(context, _connection, challenge);

  void _setRead(bool read) => _dispatch(
    widget.session,
    SessionIsReadChangedAction(isRead: read).toJson(),
  );

  void _setArchived(bool archived) => _dispatch(
    widget.session,
    SessionIsArchivedChangedAction(isArchived: archived).toJson(),
  );

  /// Renames the session from [current] to [typed] (`session/titleChanged`,
  /// write-ahead: shown at once, rolled back if the host refuses it).
  void _rename(String current, String typed) {
    if (renameAction(current, typed) case final action?) {
      _dispatch(widget.session, action);
    }
  }

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
    // Answers the host has resolved need no tracking.
    for (final id in resolvedAnswers(_answered, sessionState)) {
      _forgetAnswer(id);
    }
    final prompts = unansweredPrompts(
      sessionPrompts(sessionState, chat),
      _answered,
    );
    _declineOwnExecutions(sessionState);
    final elsewhere = otherClientExecutions(sessionState, _connection.clientId);
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
        onSignIn: _signIn,
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
    // Panels above and below the timeline get at most a share of the
    // height and scroll past it, so a short phone screen (or one with the
    // keyboard up) never overflows; the timeline takes what is left.
    final conversation = LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (chats.length > 1 && !missing) ...[
              ChatSwitcher(
                chats: chats,
                selected: chatUri,
                onSelect: _selectChat,
                onMove:
                    supports(ProtocolFeature.moveChat) && sessionState != null
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
                onAnswer: _answer,
                onSignIn: _signIn,
                maxHeight: height == null ? null : height * 0.35,
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
                          ? const Center(
                              child: Text('Could not open this chat.'),
                            )
                          : timeline,
                    ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: height == null ? double.infinity : height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (chat != null && !missing)
                      if (latestTodoList(chat) case final todos?
                          when !todos.done) ...[
                        const Divider(height: 1),
                        TodoPanel(list: todos),
                      ],
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
                        focusRequests: _composerFocus,
                        working: chat.activeTurn != null,
                        draft: chat.draft,
                        models: models,
                        initialModel: lastModelSelection(chat),
                        sessionFields: sessionFields,
                        sessionValues: sessionState?.config?.values ?? const {},
                        onSessionSettingChanged: (id, value) => _dispatch(
                          widget.session,
                          SessionConfigChangedAction(config: {id: value})
                              .toJson(),
                        ),
                        onDraftChanged: (text) => _dispatch(
                          chatUri!,
                          draftAction(text, previous: chat.draft),
                        ),
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
                ),
              ),
            ),
          ],
        );
      },
    );
    final hasChanges = availableChangesets(
      sessionState,
      chat,
      chatChangesets: supports(ProtocolFeature.chatChangesets),
    ).isNotEmpty;
    final review = ChangesPane(session: widget.session, chat: chatUri);
    final runGroup = groupOf(ref.watch(runGroupsProvider), (
      host: context.host,
      session: widget.session,
    ));
    final sessionRef = (host: context.host, session: widget.session);
    final title = sessionTitleOf(
      session: sessionState,
      summary: summary,
      chat: chat,
    );
    final pinned = ref.watch(pinnedSessionsProvider).contains(sessionRef);
    final header = _Header(
      pinned: pinned,
      onPin: (pin) => ref
          .read(pinnedSessionsProvider.notifier)
          .setPinned(sessionRef, pinned: pin),
      runLabel: runGroup == null
          ? null
          : labelsOfRuns([runGroup])[(
              host: context.host,
              session: widget.session,
            )],
      onCompareRuns: runGroup == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompareRunsScreen(groupId: runGroup.id),
              ),
            ),
      title: title,
      onRename: (typed) => _rename(title, typed),
      renameRequests: _renameRequests,
      summary: summary,
      chat: chat,
      backgroundWork: supports(ProtocolFeature.backgroundWork)
          ? chat?.backgroundWork ?? const []
          : const [],
      canvases: supports(ProtocolFeature.canvases)
          ? chat?.canvases ?? const []
          : const [],
      mcpAlerts: mcpServerAlerts(sessionState),
      links: sourceLinksOf(session: sessionState?.meta, summary: summary?.meta),
      session: sessionState,
      clientExecutions: elsewhere,
      onSignIn: _signIn,
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
      final open = ref.watch(reviewPaneOpenProvider);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: header),
                    ReviewPaneToggle(
                      open: open,
                      changes: summary?.changes ?? chat?.changes,
                      onToggle: () => unawaited(
                        ref.read(reviewPaneOpenProvider.notifier).toggle(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const Divider(height: 1),
                Expanded(child: conversation),
              ],
            ),
          ),
          CollapsibleReviewPane(
            open: open,
            width: reviewPaneWidth,
            child: review,
          ),
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
    required this.pinned,
    required this.onPin,
    required this.runLabel,
    required this.onCompareRuns,
    required this.title,
    required this.onRename,
    required this.renameRequests,
    required this.summary,
    required this.chat,
    required this.backgroundWork,
    required this.canvases,
    required this.mcpAlerts,
    required this.links,
    required this.session,
    required this.clientExecutions,
    required this.onSignIn,
    required this.onOpenChat,
    required this.onStop,
    required this.onArchive,
    required this.onMarkUnread,
    required this.onDetails,
  });

  /// Whether the session is pinned to the top of the list (AV-028).
  final bool pinned;

  /// Pins the session (true) or unpins it (false).
  final ValueChanged<bool> onPin;

  /// "Run 2 of 3" for a parallel run (AV-045).
  final String? runLabel;
  final VoidCallback? onCompareRuns;

  /// The session's title (see [sessionTitleOf]).
  final String title;

  /// Renames the session to the typed text (AV-073).
  final ValueChanged<String> onRename;

  /// Opens the title's text field when it notifies.
  final ValueNotifier<int> renameRequests;
  final SessionSummary? summary;
  final ChatState? chat;
  final List<BackgroundWork> backgroundWork;
  final List<CanvasReference> canvases;
  final List<McpServerAlert> mcpAlerts;
  final SourceLinks links;
  final SessionState? session;
  final List<SessionToolClientExecutionRequest> clientExecutions;
  final SignIn onSignIn;
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
                EditableTitle(
                  title: title,
                  onRename: onRename,
                  editRequests: renameRequests,
                  style: theme.textTheme.titleLarge,
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
                    if (runLabel case final label?)
                      ActionChip(
                        avatar: const Icon(Icons.call_split, size: 16),
                        label: Text(label),
                        tooltip: 'Compare runs',
                        visualDensity: VisualDensity.compact,
                        onPressed: onCompareRuns,
                      ),
                    if (links.pullRequest case final pr?)
                      _LinkChip(
                        icon: Icons.call_merge,
                        label: pr.label,
                        tooltip: [?pr.title, pr.url].join('\n'),
                        url: pr.url,
                      ),
                    if (links.branch case BranchLink(:final name, :final url?))
                      _LinkChip(
                        icon: Icons.account_tree_outlined,
                        label: name,
                        tooltip: url,
                        url: url,
                      ),
                    if (canvases.isNotEmpty) CanvasChips(canvases: canvases),
                    if (mcpAlerts.isNotEmpty)
                      McpServerAlertChips(
                        alerts: mcpAlerts,
                        onSignIn: onSignIn,
                      ),
                    if (clientExecutions.isNotEmpty)
                      ClientExecutionChip(
                        executions: clientExecutions,
                        session: session,
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
            Tooltip(
              message: 'Stop (${shortcutLabel(AppCommand.stop)})',
              child: FilledButton.tonalIcon(
                onPressed: onStop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Session actions',
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => renameRequests.value++,
                child: const Text('Rename…'),
              ),
              PopupMenuItem(
                value: () => onArchive(!archived),
                child: Text(archived ? 'Unarchive' : 'Archive'),
              ),
              PopupMenuItem(
                value: onMarkUnread,
                child: const Text('Mark unread'),
              ),
              PopupMenuItem(
                value: () => onPin(!pinned),
                child: Text(pinLabel(pinned: pinned)),
              ),
              PopupMenuItem(
                value: onDetails,
                child: const Text('Session details'),
              ),
              if (onCompareRuns case final compare?)
                PopupMenuItem(
                  value: compare,
                  child: const Text('Compare runs'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A chip that opens [url] in the browser (a pull request or branch,
/// AV-105).
class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final String url;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: () => unawaited(
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    ),
  );
}

/// The turns, newest at the bottom, following new output unless the user
/// scrolled up (AV-066). Rows are built lazily and keyed, so finished
/// turns are not rebuilt while one streams and older turns paged in at
/// the top (AV-068) do not disturb the rows below. A [TurnRail] beside
/// the rows jumps to a user turn (AV-074); Cmd/Ctrl+Alt+↑/↓ step through
/// them, paging older turns in past the oldest loaded one.
class _Timeline extends ConsumerStatefulWidget {
  const _Timeline({
    super.key,
    required this.chat,
    required this.onAction,
    required this.onSignIn,
    required this.onOpenChat,
    required this.onLoadOlder,
  });

  final ChatState chat;
  final ValueChanged<JsonMap> onAction;
  final SignIn onSignIn;
  final OpenChat onOpenChat;
  final Future<void> Function() onLoadOlder;

  @override
  ConsumerState<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<_Timeline> {
  final _scroll = ScrollController();

  /// Knows every row's (measured or estimated) extent, so the list can
  /// jump to rows that were never built (AV-074).
  final _list = ListController();
  bool _awayFromLatest = false;

  /// The index of the turn in view (AV-074).
  int? _currentTurn;
  StreamSubscription<AppCommand>? _commands;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final away = _scroll.offset > 200;
      if (away != _awayFromLatest) setState(() => _awayFromLatest = away);
    });
    // The visible rows are known after layout, when the list notifies.
    _list.addListener(_scheduleCurrentTurn);
    _commands = ref.read(appCommandsProvider).stream.listen(_onCommand);
  }

  @override
  void dispose() {
    unawaited(_commands?.cancel());
    _scroll.dispose();
    _list.dispose();
    super.dispose();
  }

  TimelineRows get _rows => timelineItems(widget.chat);

  /// The timeline row of the oldest list item on screen.
  int? get _topRow {
    final range = _list.isAttached ? _list.visibleRange : null;
    if (range == null) return null;
    return _rows.length - 1 - range.$2;
  }

  void _scheduleCurrentTurn() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateCurrentTurn());

  void _updateCurrentTurn() {
    final top = _topRow;
    if (top == null) return;
    final current = currentTurn(turnMarkers(widget.chat, _rows), top);
    if (current != _currentTurn && mounted) {
      setState(() => _currentTurn = current);
    }
  }

  void _onCommand(AppCommand command) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    switch (command) {
      case AppCommand.previousTurn:
        unawaited(_step(-1));
      case AppCommand.nextTurn:
        unawaited(_step(1));
      case _:
        break;
    }
  }

  /// Scrolls to the user turn [delta] away from the one at the top of the
  /// screen; past the oldest loaded turn, pages older turns in first.
  Future<void> _step(int delta) async {
    final top = _topRow;
    if (top == null) return;
    final markers = turnMarkers(widget.chat, _rows);
    if (steppedTurn(markers, top, delta) case final index?) {
      _jumpTo(markers[index]);
    } else if (delta < 0) {
      await _loadOlderAndJump();
    }
  }

  /// Pages older turns in, then scrolls to the newest of them.
  Future<void> _loadOlderAndJump() async {
    if (widget.chat.turnsNextCursor == null) return;
    final oldest = turnMarkers(widget.chat, _rows).firstOrNull?.turnId;
    await widget.onLoadOlder();
    // The new rows are laid out on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final markers = turnMarkers(widget.chat, _rows);
      final before = markers.indexWhere((m) => m.turnId == oldest) - 1;
      if (before >= 0) _jumpTo(markers[before]);
    });
  }

  /// Scrolls so that [marker]'s message is at the top of the screen.
  void _jumpTo(TurnMarker marker) {
    if (!_list.isAttached || !_scroll.hasClients) return;
    final index = _rows.length - 1 - marker.row;
    // In the reversed list the trailing edge (alignment 1) is the top.
    if (MediaQuery.disableAnimationsOf(context)) {
      _list.jumpToItem(index: index, scrollController: _scroll, alignment: 1);
    } else {
      _list.animateToItem(
        index: index,
        scrollController: _scroll,
        alignment: 1,
        duration: (_) => const Duration(milliseconds: 250),
        curve: (_) => Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows.isEmpty) {
      return const Center(child: Text('No messages yet. Say something.'));
    }
    final markers = turnMarkers(widget.chat, rows);
    // Paged-in rows move the turns without changing the visible range.
    _scheduleCurrentTurn();
    // A reversed list keeps the newest row in view as it grows, and stays
    // put once the user scrolls up.
    final list = Stack(
      children: [
        // Rows use plain Text (not SelectableText): the area makes them
        // selectable, and on the web read-only text fields expose no text
        // to screen readers (or browser tests).
        SelectionArea(
          child: SuperListView.builder(
            controller: _scroll,
            listController: _list,
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
                  onSignIn: widget.onSignIn,
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
    // One turn needs no rail.
    if (markers.length < 2 && widget.chat.turnsNextCursor == null) return list;
    final current = _currentTurn;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: list),
        TurnRail(
          markers: markers,
          current: current != null && current < markers.length ? current : null,
          onSelect: (index) => _jumpTo(markers[index]),
          onLoadOlder: widget.chat.turnsNextCursor == null
              ? null
              : () => unawaited(_loadOlderAndJump()),
          compact:
              layoutTierFor(MediaQuery.sizeOf(context).width) ==
              LayoutTier.compact,
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
    this.focusRequests,
  });

  /// Takes focus whenever this changes (Cmd/Ctrl+L, AV-140).
  final Listenable? focusRequests;

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
    widget.focusRequests?.addListener(_takeFocus);
  }

  void _takeFocus() => _focus.requestFocus();

  @override
  void didUpdateWidget(FollowUpInput old) {
    super.didUpdateWidget(old);
    if (old.focusRequests != widget.focusRequests) {
      old.focusRequests?.removeListener(_takeFocus);
      widget.focusRequests?.addListener(_takeFocus);
    }
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
    widget.focusRequests?.removeListener(_takeFocus);
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
