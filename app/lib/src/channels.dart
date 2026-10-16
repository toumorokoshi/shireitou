/// Widgets and providers that subscribe to extra channels (terminals,
/// changesets, canvases, other chats) while they are on screen, and read
/// `ContentRef` content.
library;

import 'dart:async';
import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'host_connection.dart';

final _log = Logger('channels');

/// Builds with whether subscribing failed (the host does not know the
/// channel, or the connection dropped).
typedef SubscribedBuilder = Widget Function(BuildContext context, bool failed);

/// Keeps [channel] subscribed (mirrored as [kind]) while mounted, so
/// descendants can watch its state in [hostConnectionProvider].
class ChannelSubscriber extends ConsumerStatefulWidget {
  /// Creates a [ChannelSubscriber].
  const ChannelSubscriber({
    super.key,
    required this.channel,
    required this.kind,
    required this.builder,
  });

  /// The channel URI.
  final String channel;

  /// How the channel is mirrored.
  final ChannelKind kind;

  /// Builds the child.
  final SubscribedBuilder builder;

  @override
  ConsumerState<ChannelSubscriber> createState() => _ChannelSubscriberState();
}

class _ChannelSubscriberState extends ConsumerState<ChannelSubscriber> {
  late final HostConnection _connection;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _connection = ref.read(hostConnectionProvider.notifier);
    _subscribe(widget.channel, widget.kind);
  }

  void _subscribe(String channel, ChannelKind kind) {
    _failed = false;
    unawaited(
      Future(() => _connection.subscribe(channel, kind))
          .catchError((Object error) {
            _log.info('could not subscribe to $channel: $error');
            if (mounted && widget.channel == channel) {
              setState(() => _failed = true);
            }
          }),
    );
  }

  @override
  void didUpdateWidget(ChannelSubscriber old) {
    super.didUpdateWidget(old);
    if (old.channel != widget.channel || old.kind != widget.kind) {
      _connection.unsubscribe(old.channel);
      _subscribe(widget.channel, widget.kind);
    }
  }

  @override
  void dispose() {
    _connection.unsubscribe(widget.channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _failed);
}

/// The text behind a `ContentRef` URI, read with `resourceRead` while
/// something watches it.
final resourceTextProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  uri,
) async {
  final result = await ref
      .read(hostConnectionProvider.notifier)
      .readResource(uri);
  return switch (result.encoding) {
    ContentEncoding.base64 => utf8.decode(
      base64.decode(result.data),
      allowMalformed: true,
    ),
    _ => result.data,
  };
});
