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
import 'chat_commands.dart';
import 'session_inputs.dart';
import 'session_status_widgets.dart';
import 'timeline_items.dart';
import 'timeline_parts.dart';

/// Shows [session]: subscribes to it and its default chat while visible and
/// marks it read when opened (AV-023).
class SessionDetailView extends ConsumerStatefulWidget {
  /// Creates a [SessionDetailView]. Give it a key per session.
  const SessionDetailView({super.key, required this.session});

  /// The session's URI as the catalogue lists it.
  final String session;

  @override
  ConsumerState<SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends ConsumerState<SessionDetailView> {
  late final HostConnection _connection;
  StreamSubscription<ActionFailure>? _failures;
  String? _chat;
  Object? _error;
  bool _opening = true;

  /// Set by "Mark unread", which stops marking the session read while it
  /// stays open.
  bool _keepUnread = false;

  @override
  void initState() {
    super.initState();
    _connection = ref.read(hostConnectionProvider.notifier);
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
        _chat = chat;
        _opening = false;
      });
      final summary = ref.read(hostConnectionProvider).sessions[widget.session];
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
    if (!_opening) _connection.closeSession(widget.session, _chat);
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

  @override
  Widget build(BuildContext context) {
    // New turns clear IsRead; while the session is open, it stays read.
    ref.listen(
      hostConnectionProvider.select(
        (s) => s.sessions[widget.session]?.status.isReadFlag,
      ),
      (_, read) {
        if (read == false && !_opening && !_keepUnread) {
          // Not from inside the provider's notification.
          scheduleMicrotask(() => _setRead(true));
        }
      },
    );
    final summary = ref.watch(
      hostConnectionProvider.select((s) => s.sessions[widget.session]),
    );
    final chatUri = _chat;
    final chat = chatUri == null
        ? null
        : ref.watch(
            hostConnectionProvider.select(
              (s) => s.chatChannels[chatUri]?.state,
            ),
          );
    final sessionState = ref.watch(
      hostConnectionProvider.select(
        (s) => s.sessionChannels[widget.session]?.state,
      ),
    );
    final protocolVersion = ref.watch(
      hostConnectionProvider.select((s) => s.protocolVersion),
    );
    final prompts = sessionPrompts(sessionState, chat);
    // The host could not resume the session after a reconnect (AHP-004).
    final missing = ref.watch(
      hostConnectionProvider.select(
        (s) =>
            s.missingChannels.contains(widget.session) ||
            (chatUri != null && s.missingChannels.contains(chatUri)),
      ),
    );
    final body = switch ((chat, _error)) {
      _ when missing => const Center(
        child: Text('This session is no longer available on the host.'),
      ),
      (_, final error?) => Center(child: Text('Could not open: $error')),
      (null, _) when _opening => const Center(
        child: CircularProgressIndicator(),
      ),
      (null, _) => const Center(child: Text('This session has no chat.')),
      (final chat?, _) => _Timeline(
        chat: chat,
        onAction: (action) => _dispatch(chatUri!, action),
        onAuthenticate: _authenticate,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          summary: summary,
          chat: chat,
          backgroundWork:
              supportsFeature(protocolVersion, ProtocolFeature.backgroundWork)
              ? chat?.backgroundWork ?? const []
              : const [],
          mcpAlerts: mcpServerAlerts(sessionState),
          onAuthenticate: _authenticate,
          onStop: chat == null
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
        ),
        const Divider(height: 1),
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
        Expanded(child: body),
        if (chat != null)
          FollowUpInput(
            working: chat.activeTurn != null,
            onSend: (text, {required steer}) => _dispatch(
              chatUri!,
              sendMessageAction(
                chat,
                text: text,
                id: const Uuid().v4(),
                now: DateTime.now(),
                steer: steer,
              ),
            ),
          ),
      ],
    );
  }
}

/// Title, agent, model, folder, status, activity and actions (AV-060).
class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.chat,
    required this.backgroundWork,
    required this.mcpAlerts,
    required this.onAuthenticate,
    required this.onStop,
    required this.onArchive,
    required this.onMarkUnread,
  });

  final SessionSummary? summary;
  final ChatState? chat;
  final List<BackgroundWork> backgroundWork;
  final List<McpServerAlert> mcpAlerts;
  final Authenticate onAuthenticate;
  final VoidCallback? onStop;
  final ValueChanged<bool> onArchive;
  final VoidCallback onMarkUnread;

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
                      BackgroundWorkChip(work: backgroundWork),
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
          if (chat?.activeTurn != null)
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
            ],
          ),
        ],
      ),
    );
  }
}

/// The turns, newest at the bottom, following new output unless the user
/// scrolled up (AV-066).
class _Timeline extends StatefulWidget {
  const _Timeline({
    required this.chat,
    required this.onAction,
    required this.onAuthenticate,
  });

  final ChatState chat;
  final ValueChanged<JsonMap> onAction;
  final Authenticate onAuthenticate;

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
    final items = timelineItems(widget.chat);
    if (items.isEmpty) {
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
            itemCount: items.length,
            itemBuilder: (context, index) => buildTimelineItem(
              items[items.length - 1 - index],
              widget.onAction,
              onAuthenticate: widget.onAuthenticate,
            ),
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

/// Sends [text]; [steer] asks to deliver it at the agent's next step.
typedef SendMessage = void Function(String text, {required bool steer});

/// The follow-up box (AV-080): Enter sends (or queues while working),
/// Cmd/Ctrl+Enter sends now while working, Shift+Enter adds a newline.
class FollowUpInput extends StatefulWidget {
  /// Creates a [FollowUpInput].
  const FollowUpInput({super.key, required this.working, required this.onSend});

  /// Whether a turn is running.
  final bool working;

  /// Called with the message text.
  final SendMessage onSend;

  @override
  State<FollowUpInput> createState() => _FollowUpInputState();
}

class _FollowUpInputState extends State<FollowUpInput> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
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
    widget.onSend(text, steer: steer);
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Padding(
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
