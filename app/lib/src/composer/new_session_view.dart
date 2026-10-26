/// A new session drafted in the session pane (AV-040, AV-041, AV-043,
/// AV-045), laid out like an open session, as the GitHub agents view
/// starts a task from its prompt box.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../auth/sign_in_dialog.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../runs/run_group_store.dart';
import '../runs/run_groups.dart';
import '../runs/runs_editor.dart';
import '../session_detail/message_settings.dart';
import '../session_detail/session_detail_view.dart';
import '../session_detail/timeline_parts.dart';
import '../session_list/folder_grouping.dart';
import '../shortcuts.dart';
import '../theme/app_colors.dart';
import 'composer_labels.dart';
import 'completions.dart';
import 'config_fields.dart';
import 'config_form.dart';
import 'directory_browser.dart';
import 'new_session_draft.dart';
import '../theme/app_icons.dart';
import '../agent_names.dart';
import '../dictation/dictation.dart';

/// The draft's title, in its header and in the session list.
const newSessionTitle = 'New session';

/// A session not started yet: a header titled "New session", an empty
/// timeline with a hint, and the follow-up box as the prompt, with the
/// host, agent, folder, model and settings pickers inline. Sending starts
/// the session (or parallel runs) and calls [onStarted]. Meanwhile the
/// timeline shows the prompt as the first message and "Initializing…",
/// as if the session had started; a failure puts the prompt back in the
/// box and shows above it.
class NewSessionView extends ConsumerStatefulWidget {
  /// Creates a [NewSessionView]. Give it a key per [target].
  const NewSessionView({
    super.key,
    required this.target,
    required this.onStarted,
    this.draft,
    this.onDraftChanged,
  });

  /// The host and folder "New session" preselected; null fields default
  /// to the first connected host and its `defaultDirectory`.
  final NewSessionTarget target;

  /// What the user picked and typed when the draft was last open.
  final NewSessionDraft? draft;

  /// Called with the draft as the user changes it.
  final ValueChanged<NewSessionDraft>? onDraftChanged;

  /// Called with the first started session.
  final ValueChanged<SessionRef> onStarted;

  @override
  ConsumerState<NewSessionView> createState() => _NewSessionViewState();
}

class _NewSessionViewState extends ConsumerState<NewSessionView> {
  late final _prompt = TextEditingController(text: widget.draft?.prompt);
  final _directory = TextEditingController();

  /// Asks the prompt to take focus (on open, Cmd/Ctrl+L).
  final _focusRequests = ValueNotifier<int>(0);
  StreamSubscription<AppCommand>? _commands;
  String? _host;
  late String? _provider = widget.draft?.provider;

  /// Session settings the user changed; the rest come from the host.
  Map<String, Object?> _settings = {};
  ResolveSessionConfigResult? _resolved;
  String? _settingsError;
  int _resolveGeneration = 0;
  Timer? _resolveTimer;

  /// The prompt being started, shown as the first message until the
  /// host has created the session.
  Message? _sent;
  String? _error;

  /// Runs beyond the first, for best-of-N (AV-045): each an agent and a
  /// model (null: the host's default).
  List<RunVariant> _extraRuns = const [];

  @override
  void initState() {
    super.initState();
    final hosts = ref.read(hostInfosProvider).where((h) => h.live);
    final wanted = widget.draft?.host ?? widget.target.host;
    _host =
        hosts.where((h) => h.key == wanted).firstOrNull?.key ??
        hosts.firstOrNull?.key;
    _directory.text =
        widget.draft?.directory ??
        initialDirectoryText(widget.target.directory, _defaultDirectory);
    _directory.addListener(_scheduleResolve);
    _directory.addListener(_saveDraft);
    _prompt.addListener(_saveDraft);
    _commands = ref.read(appCommandsProvider).stream.listen((command) {
      if (command == AppCommand.focusComposer && mounted) {
        _focusRequests.value++;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusRequests.value++;
    });
    unawaited(_resolve());
  }

  @override
  void dispose() {
    _resolveTimer?.cancel();
    unawaited(_commands?.cancel());
    _prompt.dispose();
    _directory.dispose();
    _focusRequests.dispose();
    super.dispose();
  }

  void _saveDraft() => widget.onDraftChanged?.call((
    host: _host,
    provider: _provider,
    directory: _directory.text,
    prompt: _prompt.text,
  ));

  String? get _defaultDirectory => switch (_host) {
    final host? => ref.read(hostConnectionProvider(host)).defaultDirectory,
    null => null,
  };

  HostConnection? get _connection => switch (_host) {
    final host? => ref.read(hostConnectionProvider(host).notifier),
    null => null,
  };

  List<AgentInfo> _agentsOf(String? host) => host == null
      ? const []
      : ref.read(hostConnectionProvider(host)).root?.agents ?? const [];

  String? get _directoryUri {
    final text = _directory.text.trim();
    return text.isEmpty ? null : directoryUri(text);
  }

  void _selectHost(String? host) {
    if (host == null || host == _host) return;
    setState(() {
      _host = host;
      _provider = null;
      _settings = {};
      _resolved = null;
      _extraRuns = const [];
    });
    _directory.text = initialDirectoryText(null, _defaultDirectory);
    unawaited(_resolve());
  }

  void _selectAgent(String? provider) {
    setState(() {
      _provider = provider;
      _settings = {};
    });
    _saveDraft();
    unawaited(_resolve());
  }

  void _changeSetting(String id, Object? value) {
    setState(() => _settings = {..._settings, id: value});
    _scheduleResolve();
  }

  void _scheduleResolve() {
    _resolveTimer?.cancel();
    _resolveTimer = Timer(const Duration(milliseconds: 400), _resolve);
  }

  /// Asks the host which settings the agent takes here
  /// (`resolveSessionConfig`); the latest answer wins. A host without the
  /// command just has no settings.
  Future<void> _resolve() async {
    final connection = _connection;
    if (connection == null) return;
    final generation = ++_resolveGeneration;
    final provider = _provider ?? _agentsOf(_host).firstOrNull?.provider;
    try {
      final result = await connection.resolveSessionConfig(
        provider: provider,
        workingDirectory: _directoryUri,
        config: _chosenSettings(),
      );
      if (!mounted || generation != _resolveGeneration) return;
      setState(() {
        _resolved = result;
        _settingsError = null;
      });
    } on Object catch (error) {
      if (!mounted || generation != _resolveGeneration) return;
      setState(() {
        _resolved = null;
        _settingsError = isMethodNotFound(error)
            ? null
            : 'Could not load the agent settings: $error';
      });
    }
  }

  JsonMap _chosenSettings() => {
    for (final MapEntry(:key, :value) in _settings.entries) key: ?value,
  };

  Future<List<ConfigOption>> _suggest(ConfigField field, String query) async {
    final items = await _connection!.sessionConfigCompletions(
      property: field.id,
      provider: _provider ?? _agentsOf(_host).firstOrNull?.provider,
      workingDirectory: _directoryUri,
      config: _chosenSettings(),
      query: query,
    );
    return [
      for (final item in items)
        ConfigOption(item.value, item.label, item.description),
    ];
  }

  Future<void> _browse() async {
    final host = _host;
    if (host == null) return;
    final chosen = await showDirectoryBrowser(
      context,
      host: host,
      initial: _directory.text.trim().isEmpty
          ? normalizeFolderKey(_defaultDirectory ?? '/')
          : normalizeFolderKey(_directory.text.trim()),
    );
    if (chosen != null) _directory.text = chosen;
  }

  /// Starts the session (and the parallel runs) with [prompt] and its
  /// accepted completions' [attachments], and the first run's [model].
  Future<void> _start(
    String prompt,
    ModelSelection? model,
    List<MessageAttachment> attachments,
  ) async {
    if (_sent != null) return;
    final host = _host;
    final agents = _agentsOf(host);
    final agent =
        agents.where((a) => a.provider == _provider).firstOrNull ??
        agents.firstOrNull;
    final directory = _directoryUri;
    if (host == null || agent == null || directory == null) {
      setState(() => _error = 'Pick an agent and a folder.');
      return;
    }
    final resolved = _resolved;
    final settings = resolved == null
        ? _chosenSettings()
        : configValues(sessionConfigFields(resolved.schema), {
            ...resolved.values,
            ..._settings,
          });
    final connection = ref.read(hostConnectionProvider(host).notifier);
    // The first run uses the pickers; the others their own agent and
    // model, with the session settings only when the agent is the same
    // (another agent's settings may not apply).
    final runs = [
      (agent: agent, model: model, config: settings),
      for (final extra in _extraRuns)
        _variant(
          agents.where((a) => a.provider == extra.provider).firstOrNull ??
              agent,
          extra.model,
          settings: settings,
          sameAgent: extra.provider == agent.provider,
        ),
    ];
    final typed = _prompt.text;
    setState(() {
      _sent = userMessage(prompt, model: model, attachments: attachments);
      _error = null;
    });
    _prompt.clear();
    final results = await Future.wait([
      for (final run in runs)
        connection
            .startSession(
              provider: run.agent.provider,
              workingDirectory: directory,
              prompt: prompt,
              attachments: attachments,
              model: run.model,
              config: run.config,
            )
            .then<Object>((session) => session, onError: (Object e) => e),
    ]);
    if (!mounted) return;
    final (:started, :failures) = runOutcome(
      host: host,
      labels: [for (final run in runs) runLabel(run.agent, run.model)],
      results: results,
    );
    if (started.isEmpty) {
      setState(() {
        _sent = null;
        _error = failures.join('\n');
      });
      _prompt.text = typed;
      return;
    }
    if (started.length > 1) {
      await ref
          .read(runGroupsProvider.notifier)
          .add(
            RunGroup(
              id: const Uuid().v4(),
              prompt: prompt,
              createdAt: DateTime.now().toUtc().toIso8601String(),
              members: started,
            ),
          );
    }
    if (!mounted) return;
    if (failures.isNotEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            '${started.length} of ${runs.length} runs started. '
            '${failures.join('; ')}',
          ),
        ),
      );
    }
    widget.onStarted(started.first.ref);
  }

  static ({AgentInfo agent, ModelSelection? model, JsonMap? config}) _variant(
    AgentInfo agent,
    String? model, {
    required JsonMap settings,
    required bool sameAgent,
  }) => (
    agent: agent,
    model: modelSelection(
      agent.models.where((m) => m.id == model).firstOrNull,
      const {},
    ),
    config: sameAgent ? settings : null,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hosts = [
      for (final h in ref.watch(hostInfosProvider))
        if (h.live) h,
    ];
    final host = _host;
    final agents = host == null
        ? const <AgentInfo>[]
        : ref.watch(
            hostConnectionProvider(host)
                .select((s) => s.root?.agents ?? const <AgentInfo>[]),
          );
    final agent =
        agents.where((a) => a.provider == _provider).firstOrNull ??
        agents.firstOrNull;
    final recent = host == null
        ? const <String>[]
        : recentFolders(ref.watch(allSessionsProvider), host);
    final resolved = _resolved;
    final settingValues = {...?resolved?.values, ..._settings};
    final settingFields = sessionConfigFields(resolved?.schema);
    // `/` completions (AV-044): there is no chat to ask the host about
    // yet, so the agent's own skills and prompts, else a loaded session's.
    final commands = draftCommands(
      agent: agent,
      sessions: host == null
          ? const <SessionState>[]
          : [
              for (final channel
                  in ref
                      .watch(
                        hostConnectionProvider(host)
                            .select((s) => s.sessionChannels),
                      )
                      .values)
                channel.state,
            ],
      directory: _directoryUri,
    );
    final signIns = host == null || agent == null
        ? const <AgentSignIn>[]
        : missingAgentSignIns(
            RootState(agents: [agent]),
            ref.watch(signedInResourcesProvider(host)).value ?? const {},
          );
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Semantics(
        header: true,
        child: Text(newSessionTitle, style: theme.textTheme.titleSmall),
      ),
    );
    final draftTimeline = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Write a prompt below to start the session. Its timeline '
                'shows here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              for (final (:agent, :resource) in signIns)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.key),
                      title: Text(
                        '${agent.displayName} needs you to sign in to '
                        '${resource.resourceName ?? resource.resource}.',
                      ),
                      trailing: TextButton(
                        onPressed: () => signInFromUi(
                          context,
                          ref.read(hostConnectionProvider(host!).notifier),
                          AuthChallenge(resource: resource),
                        ),
                        child: const Text('Sign in'),
                      ),
                    ),
                  ),
                ),
              // Settings a dropdown cannot take (such as a branch with the
              // host's suggestions); dropdowns sit above the prompt.
              if (settingFields.where((f) => !isPickerField(f)).toList()
                  case final fields when fields.isNotEmpty) ...[
                const SizedBox(height: 16),
                ConfigForm(
                  key: ValueKey('settings-$host-${agent?.provider}'),
                  fields: fields,
                  values: settingValues,
                  suggestions: _suggest,
                  onChanged: _changeSetting,
                ),
              ],
              if (_settingsError case final error?) ...[
                const SizedBox(height: 8),
                Text(error, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              ParallelRunsEditor(
                agents: agents,
                defaultAgent: agent,
                runs: _extraRuns,
                onChanged: (runs) => setState(() => _extraRuns = runs),
              ),
            ],
          ),
        ),
      ),
    );
    final muted = AppColors.of(context).mutedText;
    // The host, agent and folder sit in a row above the composer's box,
    // in the composer's chip style (AV-096).
    final pickers = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: composerMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            composerMargin.left - 6,
            8,
            composerMargin.right,
            0,
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hosts.length > 1)
                pickerChip<String>(
                  label: 'Host',
                  icon: AppIcons.host,
                  value: host,
                  items: [for (final h in hosts) (h.key, h.label)],
                  onChanged: (host) {
                    _selectHost(host);
                    _saveDraft();
                  },
                ),
              pickerChip<String>(
                label: 'Agent',
                icon: AppIcons.agent,
                value: agent?.provider,
                items: [for (final a in agents) (a.provider, a.displayName)],
                onChanged: _selectAgent,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    child: Semantics(
                      label: 'Working directory',
                      child: TextField(
                        controller: _directory,
                        style: theme.textTheme.bodySmall,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Working directory',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                          prefixIcon: Icon(
                            AppIcons.folder,
                            size: 14,
                            color: muted,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Browse…',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    color: muted,
                    icon: const Icon(AppIcons.folderOpen),
                    onPressed: host == null ? null : _browse,
                  ),
                  if (recent.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'Recent folders',
                      iconSize: 16,
                      iconColor: muted,
                      icon: const Icon(AppIcons.history),
                      onSelected: (folder) => _directory.text = folder,
                      itemBuilder: (_) => [
                        for (final folder in recent)
                          PopupMenuItem(
                            value: folder,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(folderLabelOf(folder)),
                              subtitle: Text(folder),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const Divider(height: 1),
        Expanded(
          child: switch (_sent) {
            final sent? => StartingTimeline(message: sent),
            null => draftTimeline,
          },
        ),
        if (_sent == null) pickers,
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ListenableBuilder(
          listenable: _directory,
          builder: (context, _) => FollowUpInput(
            // The model pickers start afresh for another host or agent;
            // the prompt's text is kept.
            key: ValueKey('prompt-$host-${agent?.provider}'),
            controller: _prompt,
            focusRequests: _focusRequests,
            dictation: ref.watch(dictationProvider),
            working: false,
            hintText: composerPlaceholder(
              agent: agent == null
                  ? null
                  : agentDisplayName(agent.provider, agents),
              folder: switch (_directory.text.trim()) {
                '' => null,
                final folder => folderLabelOf(normalizeFolderKey(folder)),
              },
            ),
            sendTooltip: _extraRuns.isEmpty
                ? 'Start session'
                : 'Start ${_extraRuns.length + 1} runs',
            models: agent?.models ?? const [],
            sessionFields: settingFields.where(isPickerField).toList(),
            sessionValues: settingValues,
            onSessionSettingChanged: _changeSetting,
            completionTriggers: completionTriggers(const [], commands),
            completionSource: (text, token) => resolveCompletions(
              text: text,
              token: token,
              commands: commands,
            ),
            onSend: (text, {required steer, model, attachments = const []}) =>
                unawaited(_start(text, model, attachments)),
          ),
        ),
      ],
    );
  }
}

/// What the timeline says while the host creates the session.
const initializingLabel = 'Initializing…';

/// The timeline of a session the host is still creating: [message] as
/// the first message and the working dots with [initializingLabel], laid
/// out like an open session's timeline.
class StartingTimeline extends StatelessWidget {
  /// Creates a [StartingTimeline].
  const StartingTimeline({super.key, required this.message});

  /// The prompt being started.
  final Message message;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(
      horizontal: timelineSidePadding,
      vertical: 8,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: timelineMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserMessageBubble(message: message),
            const WorkingIndicatorRow(activity: initializingLabel),
          ],
        ),
      ),
    ),
  );
}
