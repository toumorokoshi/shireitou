/// The composer's "parallel runs" section (best-of-N, AV-045): extra
/// agent/model combinations to start with the same prompt.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import 'run_groups.dart';

/// One extra run: an agent ([provider]) and a [model] (null for the
/// host's default).
typedef RunVariant = ({String? provider, String? model});

/// "Claude · Sonnet 4.5", or "Claude · default model".
String runLabel(AgentInfo agent, ModelSelection? model) {
  final name = switch (model) {
    final m? =>
      agent.models.where((x) => x.id == m.id).firstOrNull?.name ?? m.id,
    null => 'default model',
  };
  return '${agent.displayName} · $name';
}

/// Lists the extra runs, each with an agent and a model picker and a
/// remove button, and adds runs up to [maxRuns] in all.
class ParallelRunsEditor extends StatelessWidget {
  /// Creates a [ParallelRunsEditor].
  const ParallelRunsEditor({
    super.key,
    required this.agents,
    required this.defaultAgent,
    required this.runs,
    required this.onChanged,
  });

  /// The host's agents.
  final List<AgentInfo> agents;

  /// The agent picked for the first run, which new runs start with.
  final AgentInfo? defaultAgent;

  /// The extra runs.
  final List<RunVariant> runs;

  /// Called with the new list of extra runs.
  final ValueChanged<List<RunVariant>> onChanged;

  void _replace(int index, RunVariant run) =>
      onChanged([for (final (i, r) in runs.indexed) i == index ? run : r]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                runs.isEmpty
                    ? 'Parallel runs: one session.'
                    : 'Parallel runs: ${runs.length + 1} sessions with the '
                          'same prompt, to compare and pick from.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: defaultAgent == null || runs.length + 1 >= maxRuns
                  ? null
                  : () => onChanged([
                      ...runs,
                      (provider: defaultAgent!.provider, model: null),
                    ]),
              icon: const Icon(Icons.call_split),
              label: const Text('Add a run'),
            ),
          ],
        ),
        for (final (i, run) in runs.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Run ${i + 2}'),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('run-${i + 2}-agent'),
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Agent'),
                    initialValue: run.provider,
                    items: [
                      for (final a in agents)
                        DropdownMenuItem(
                          value: a.provider,
                          child: Text(a.displayName),
                        ),
                    ],
                    onChanged: (provider) =>
                        _replace(i, (provider: provider, model: null)),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('run-${i + 2}-model-${run.provider}'),
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Model'),
                    initialValue: run.model,
                    items: [
                      const DropdownMenuItem(child: Text('Host default')),
                      for (final m
                          in agents
                                  .where((a) => a.provider == run.provider)
                                  .firstOrNull
                                  ?.models ??
                              const <SessionModelInfo>[])
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (model) =>
                        _replace(i, (provider: run.provider, model: model)),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove run ${i + 2}',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged([
                    for (final (j, r) in runs.indexed)
                      if (j != i) r,
                  ]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
