import 'dart:async';
import 'dart:io';

/// A loopback TCP relay in front of a host, so tests can break the
/// connection the way a network does: [drop] closes every relayed
/// connection, [refusing] turns new ones away (the host looks down), and
/// [hold] black-holes what the client sends (its actions never arrive).
///
/// The host behind it can change ([target]), so a test can restart a host
/// on another port while the client keeps the relay's URL.
class TcpRelay {
  /// A relay to the host on [target], once [start]ed.
  TcpRelay({required this.target, this.address = '127.0.0.1'});

  /// The host's port; new connections go here.
  int target;

  /// The address both sides use.
  final String address;

  ServerSocket? _server;
  final _pairs = <(Socket, Socket)>{};
  bool _holding = false;

  /// Connections relayed so far (each reconnect adds one).
  int get connections => _connections;
  int _connections = 0;

  /// The relay's port, once [start]ed.
  int get port => _server!.port;

  /// [url] with its host and port replaced by the relay's.
  Uri relayed(Uri url) => url.replace(host: address, port: port);

  /// Listens on [port] (0 for any) and returns the port.
  Future<int> start({int port = 0}) async {
    final server = await ServerSocket.bind(address, port);
    _server = server;
    server.listen(_accept);
    return server.port;
  }

  Future<void> _accept(Socket client) async {
    if (refusing) {
      client.destroy();
      return;
    }
    final Socket upstream;
    try {
      upstream = await Socket.connect(address, target);
    } on SocketException {
      client.destroy();
      return;
    }
    _connections++;
    final pair = (client, upstream);
    _pairs.add(pair);
    void close() {
      if (!_pairs.remove(pair)) return;
      client.destroy();
      upstream.destroy();
    }

    client.listen(
      (data) {
        if (!_holding) upstream.add(data);
      },
      onDone: close,
      onError: (_) => close(),
    );
    upstream.listen(client.add, onDone: close, onError: (_) => close());
  }

  /// Closes every relayed connection, as a dropped network would.
  void drop() {
    for (final (client, upstream) in _pairs.toList()) {
      client.destroy();
      upstream.destroy();
    }
    _pairs.clear();
    _holding = false;
  }

  /// Whether new connections are turned away (closed at once).
  bool refusing = false;

  /// Stops passing what clients send to the host until the next [drop]:
  /// actions dispatched meanwhile are lost with the connection.
  void hold() => _holding = true;

  /// Drops every connection and stops listening.
  Future<void> close() async {
    drop();
    await _server?.close();
  }
}
