/// Session details mirrored from the host that have no place in the
/// timeline: working directories, canvases, customizations (with MCP
/// server start/stop and backgrounding), server tools, active clients and
/// metadata.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../channels.dart';
import '../host_connection.dart';

/// A readable label for a working directory URI.
String directoryLabel(String uri) {
  final parsed = Uri.tryParse(uri);
  return parsed != null && parsed.scheme == 'file' ? parsed.path : uri;
}

/// A label for an MCP server's state.
String mcpStateLabel(McpServerState state) => switch (state) {
  McpServerStartingState(blocking: true) => 'Starting (blocking)',
  McpServerStartingState() => 'Starting',
  McpServerReadyState() => 'Ready',
  McpServerAuthRequiredState() => 'Sign-in required',
  McpServerErrorState(:final error) => 'Error: ${error.message}',
  McpServerStoppedState() => 'Stopped',
  McpServerStateUnknown() => 'Unknown',
};

/// The chat's canvases, one chip each, subscribed while shown. Tapping
/// one opens its URL (1.0.0 canvas channel).
class CanvasChips extends StatelessWidget {
  /// Creates [CanvasChips] for [canvases].
  const CanvasChips({super.key, required this.canvases});

  /// The chat's canvas references.
  final List<CanvasReference> canvases;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: [
      for (final canvas in canvases)
        ChannelSubscriber(
          key: ValueKey(canvas.resource),
          channel: canvas.resource,
          kind: ChannelKind.canvas,
          builder: (context, failed) => Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(
                hostConnectionProvider.select(
                  (s) => s.canvasChannels[canvas.resource]?.state,
                ),
              );
              final url = state?.url;
              return Tooltip(
                message: [
                  ?state?.extensionName,
                  ?state?.status,
                  ?url,
                ].join(' · '),
                child: ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.web_asset, size: 16),
                  label: Text(
                    state?.title ?? (failed ? 'Canvas unavailable' : 'Canvas'),
                  ),
                  onPressed: url == null
                      ? null
                      : () => launchUrl(Uri.parse(url)),
                ),
              );
            },
          ),
        ),
    ],
  );
}

/// Opens [SessionInfoSheet] as a dialog-like page.
Future<void> showSessionInfo(
  BuildContext context, {
  required String session,
  required String? chat,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => SessionInfoSheet(session: session, chat: chat),
  ),
);

/// Everything else the host mirrors about a session and its open chat.
class SessionInfoSheet extends ConsumerWidget {
  /// Creates a [SessionInfoSheet].
  const SessionInfoSheet({super.key, required this.session, this.chat});

  /// The session URI.
  final String session;

  /// The open chat URI.
  final String? chat;

  void _dispatch(BuildContext context, WidgetRef ref, JsonMap action) {
    try {
      ref.read(hostConnectionProvider.notifier).dispatch(session, action);
    } on StateError catch (error) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not send that: ${error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      hostConnectionProvider.select((s) => s.sessionChannels[session]?.state),
    );
    final chatState = chat == null
        ? null
        : ref.watch(
            hostConnectionProvider.select((s) => s.chatChannels[chat]?.state),
          );
    final version = ref.watch(
      hostConnectionProvider.select((s) => s.protocolVersion),
    );
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    const none = ListTile(dense: true, title: Text('None'));
    final directories = state?.workingDirectories ?? const <String>[];
    final chatDirectories = chatState?.workingDirectories ?? const <String>[];
    final canvases = supportsFeature(version, ProtocolFeature.canvases)
        ? chatState?.canvases ?? const <CanvasReference>[]
        : const <CanvasReference>[];
    final customizations = state?.customizations ?? const <Customization>[];
    final tools = state?.serverTools ?? const <ToolDefinition>[];
    final clients = state?.activeClients ?? const <SessionActiveClient>[];
    final meta = state?.meta;
    return Scaffold(
      appBar: AppBar(title: Text(state?.title ?? 'Session details')),
      body: state == null
          ? const Center(child: Text('The session is not open.'))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                heading('Working directories'),
                if (directories.isEmpty) none,
                for (final d in directories)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(directoryLabel(d)),
                    subtitle: d == directories.first && state.project != null
                        ? Text(state.project!.displayName)
                        : null,
                  ),
                if (chatDirectories.isNotEmpty) ...[
                  heading('This chat uses'),
                  for (final d in chatDirectories)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_special_outlined),
                      title: Text(directoryLabel(d)),
                    ),
                ],
                if (canvases.isNotEmpty) ...[
                  heading('Canvases'),
                  CanvasChips(canvases: canvases),
                ],
                heading('Customizations'),
                if (customizations.isEmpty) none,
                for (final c in customizations)
                  _CustomizationTile(
                    customization: c,
                    canBackground: supportsFeature(
                      version,
                      ProtocolFeature.mcpBackgroundStartup,
                    ),
                    onDispatch: (action) => _dispatch(context, ref, action),
                  ),
                heading('Server tools'),
                if (tools.isEmpty) none,
                for (final t in tools)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.build_outlined),
                    title: Text(t.title ?? t.name),
                    subtitle: t.description == null
                        ? null
                        : Text(t.description!),
                  ),
                heading('Active clients'),
                if (clients.isEmpty) none,
                for (final c in clients)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.devices_outlined),
                    title: Text(c.displayName ?? c.clientId),
                    subtitle: Text('${c.tools.length} tools'),
                  ),
                if (meta != null && meta.isNotEmpty) ...[
                  heading('Metadata'),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(meta),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _CustomizationTile extends StatelessWidget {
  const _CustomizationTile({
    required this.customization,
    required this.canBackground,
    required this.onDispatch,
  });

  final Customization customization;
  final bool canBackground;
  final ValueChanged<JsonMap> onDispatch;

  @override
  Widget build(BuildContext context) {
    final c = customization;
    final id = c.id;
    final server = c is McpServerCustomization ? c : null;
    final state = server?.state;
    return ListTile(
      dense: true,
      leading: Icon(
        server != null ? Icons.dns_outlined : Icons.extension_outlined,
      ),
      title: Text(c.name),
      subtitle: Text(
        [c.type, if (state != null) mcpStateLabel(state)].join(' · '),
      ),
      trailing: state == null
          ? null
          : Wrap(
              spacing: 4,
              children: [
                if (state case McpServerStartingState(blocking: true)
                    when canBackground)
                  TextButton(
                    onPressed: () => onDispatch(
                      SessionMcpServerBackgroundRequestedAction(id: id)
                          .toJson(),
                    ),
                    child: const Text('Continue in background'),
                  ),
                if (state is McpServerStoppedState ||
                    state is McpServerErrorState)
                  TextButton(
                    onPressed: () => onDispatch(
                      SessionMcpServerStartRequestedAction(id: id).toJson(),
                    ),
                    child: const Text('Start'),
                  )
                else
                  TextButton(
                    onPressed: () => onDispatch(
                      SessionMcpServerStopRequestedAction(id: id).toJson(),
                    ),
                    child: const Text('Stop'),
                  ),
              ],
            ),
    );
  }
}
