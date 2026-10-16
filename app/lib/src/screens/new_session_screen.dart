/// The "New session" composer (AV-040, AV-041, AV-043).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../composer/config_fields.dart';
import '../composer/config_form.dart';
import '../composer/directory_browser.dart';
import '../auth/sign_in_dialog.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../runs/run_group_store.dart';
import '../runs/run_groups.dart';
import '../runs/runs_editor.dart';
import '../session_list/folder_grouping.dart';

/// Starts a session: host, agent, model and its options, working
/// directory, the agent's session settings, and prompt. Pops with the new
/// session's [SessionRef].
class NewSessionScreen extends ConsumerStatefulWidget {
  /// Creates a [NewSessionScreen]. [initialHost] and [initialDirectory]
  /// preselect the host and folder (the folder header's "+" button).
  const NewSessionScreen({super.key, this.initialHost, this.initialDirectory});

  /// The host key to start on; defaults to the first connected host.
  final String? initialHost;

  /// Working directory URI or path to start in; defaults to the host's
  /// `defaultDirectory`.
  final String? initialDirectory;

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _prompt = TextEditingController();
  final _directory = TextEditingController();
  late final _promptFocus = FocusNode(onKeyEvent: _onKey);
  String? _host;
  String? _provider;
  String? _model;
  Map<String, Object?> _modelOptions = {};

  /// Session settings the user changed; the rest come from the host.
  Map<String, Object?> _settings = {};
  ResolveSessionConfigResult? _resolved;
  String? _settingsError;
  int _resolveGeneration = 0;
  Timer? _resolveTimer;
  bool _starting = false;
  String? _error;

  /// Runs beyond the first, for best-of-N (AV-045): each an agent and a
  /// model (null: the host's default).
  List<RunVariant> _extraRuns = const [];

  @override
  void initState() {
    super.initState();
    final hosts = ref.read(hostInfosProvider).where((h) => h.live);
    _host =
        hosts.where((h) => h.key == widget.initialHost).firstOrNull?.key ??
        hosts.firstOrNull?.key;
    _directory.text = switch (widget.initialDirectory ?? _defaultDirectory) {
      final uri? => normalizeFolderKey(uri),
      null => '',
    };
    _directory.addListener(_scheduleResolve);
    unawaited(_resolve());
  }

  @override
  void dispose() {
    _resolveTimer?.cancel();
    _prompt.dispose();
    _directory.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

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

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      unawaited(_start());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _selectHost(String? host) {
    if (host == null || host == _host) return;
    setState(() {
      _host = host;
      _provider = null;
      _model = null;
      _modelOptions = {};
      _settings = {};
      _resolved = null;
      _extraRuns = const [];
    });
    _directory.text = switch (_defaultDirectory) {
      final uri? => normalizeFolderKey(uri),
      null => '',
    };
    unawaited(_resolve());
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

  Future<void> _start() async {
    final host = _host;
    final agents = _agentsOf(host);
    final agent =
        agents.where((a) => a.provider == _provider).firstOrNull ??
        agents.firstOrNull;
    final prompt = _prompt.text.trim();
    final directory = _directoryUri;
    if (host == null || agent == null || prompt.isEmpty || directory == null) {
      setState(() => _error = 'Pick an agent, a folder and write a prompt.');
      return;
    }
    final model = agent.models.where((m) => m.id == _model).firstOrNull;
    final resolved = _resolved;
    final settings = resolved == null
        ? _chosenSettings()
        : configValues(sessionConfigFields(resolved.schema), {
            ...resolved.values,
            ..._settings,
          });
    final connection = ref.read(hostConnectionProvider(host).notifier);
    // The first run uses the pickers above; the others their own agent
    // and model, with the session settings only when the agent is the
    // same (another agent's settings may not apply).
    final runs = [
      (
        agent: agent,
        model: modelSelection(model, _modelOptions),
        config: settings,
      ),
      for (final extra in _extraRuns)
        _variant(
          agents.where((a) => a.provider == extra.provider).firstOrNull ??
              agent,
          extra.model,
          settings: settings,
          sameAgent: extra.provider == agent.provider,
        ),
    ];
    setState(() {
      _starting = true;
      _error = null;
    });
    final results = await Future.wait([
      for (final run in runs)
        connection
            .startSession(
              provider: run.agent.provider,
              workingDirectory: directory,
              prompt: prompt,
              model: run.model,
              config: run.config,
            )
            .then<Object>((session) => session, onError: (Object e) => e),
    ]);
    if (!mounted) return;
    final started = [
      for (final (i, result) in results.indexed)
        if (result is String)
          RunMember(
            host: host,
            session: result,
            label: runLabel(runs[i].agent, runs[i].model),
          ),
    ];
    final failures = [
      for (final (i, result) in results.indexed)
        if (result is! String)
          runs.length == 1 ? '$result' : 'Run ${i + 1}: $result',
    ];
    if (started.isEmpty) {
      setState(() {
        _starting = false;
        _error = failures.join('\n');
      });
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
    Navigator.of(context).pop((host: host, session: started.first.session));
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
    final models = agent?.models ?? const <SessionModelInfo>[];
    final model = models.where((m) => m.id == _model).firstOrNull;
    final modelFields = modelConfigFields(model?.configSchema);
    final recent = host == null
        ? const <String>[]
        : recentFolders(ref.watch(allSessionsProvider), host);
    final resolved = _resolved;
    final settingFields = sessionConfigFields(resolved?.schema);
    final signIns = host == null || agent == null
        ? const <AgentSignIn>[]
        : missingAgentSignIns(
            RootState(agents: [agent]),
            ref.watch(signedInResourcesProvider(host)).value ?? const {},
          );
    return Scaffold(
      appBar: AppBar(title: const Text('New session')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (hosts.length > 1)
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('host'),
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Host'),
                          initialValue: host,
                          items: [
                            for (final h in hosts)
                              DropdownMenuItem(
                                value: h.key,
                                child: Text(
                                  h.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _selectHost,
                        ),
                      ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('agent-$host'),
                        decoration: const InputDecoration(labelText: 'Agent'),
                        initialValue: agent?.provider,
                        items: [
                          for (final a in agents)
                            DropdownMenuItem(
                              value: a.provider,
                              child: Text(a.displayName),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _provider = value;
                            _model = null;
                            _modelOptions = {};
                            _settings = {};
                          });
                          unawaited(_resolve());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey('model-$host-${agent?.provider}'),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Model'),
                        initialValue: _model,
                        items: [
                          const DropdownMenuItem(child: Text('Host default')),
                          for (final m in models)
                            DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                m.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _model = value;
                          _modelOptions = {};
                        }),
                      ),
                    ),
                  ],
                ),
                if (modelFields.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConfigForm(
                    key: ValueKey('model-options-${model?.id}'),
                    fields: modelFields,
                    values: _modelOptions,
                    onChanged: (id, value) => setState(
                      () => _modelOptions = {..._modelOptions, id: value},
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _directory,
                        decoration: const InputDecoration(
                          labelText: 'Working directory',
                          helperText: 'A folder on the host',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton.icon(
                        onPressed: host == null ? null : _browse,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse…'),
                      ),
                    ),
                  ],
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final folder in recent)
                        ActionChip(
                          avatar: const Icon(Icons.history, size: 16),
                          label: Text(folderLabelOf(folder)),
                          tooltip: folder,
                          onPressed: () => _directory.text = folder,
                        ),
                    ],
                  ),
                ],
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
                if (settingFields.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConfigForm(
                    key: ValueKey('settings-$host-${agent?.provider}'),
                    fields: settingFields,
                    values: {...?resolved?.values, ..._settings},
                    suggestions: _suggest,
                    onChanged: (id, value) {
                      setState(() => _settings = {..._settings, id: value});
                      _scheduleResolve();
                    },
                  ),
                ],
                if (_settingsError case final error?) ...[
                  const SizedBox(height: 8),
                  Text(error, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                ParallelRunsEditor(
                  agents: agents,
                  defaultAgent: agent,
                  runs: _extraRuns,
                  onChanged: (runs) => setState(() => _extraRuns = runs),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prompt,
                  focusNode: _promptFocus,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText:
                        'What should the agent do? '
                        '(Enter to start, Shift+Enter for a newline)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _starting ? null : _start,
                    icon: _starting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      _extraRuns.isEmpty
                          ? 'Start session'
                          : 'Start ${_extraRuns.length + 1} runs',
                    ),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
