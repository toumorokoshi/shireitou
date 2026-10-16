@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

/// Starts a WebSocket server that records each upgrade request.
Future<(HttpServer, List<HttpRequest>)> _server() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <HttpRequest>[];
  server.listen((request) async {
    requests.add(request);
    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen(socket.add);
  });
  return (server, requests);
}

void main() {
  test('native default sends the token as a header and as tkn', () async {
    expect(defaultTokenTransport, TokenTransport.queryAndHeader);
    final (server, requests) = await _server();
    addTearDown(server.close);
    final channel = await connectWebSocket(
      Uri.parse('ws://127.0.0.1:${server.port}?tkn=secret'),
    );
    channel.sink.add('ping');
    expect(await channel.stream.first, 'ping');
    await channel.sink.close();
    final request = requests.single;
    expect(request.headers.value('authorization'), 'Bearer secret');
    expect(request.uri.queryParameters['tkn'], 'secret');
  });

  test('header-only transport keeps the token out of the URL', () async {
    final (server, requests) = await _server();
    addTearDown(server.close);
    final connect = webSocketConnector(tokenTransport: TokenTransport.header);
    final channel = await connect(
      Uri.parse('ws://127.0.0.1:${server.port}?tkn=secret'),
    );
    await channel.sink.close();
    final request = requests.single;
    expect(request.headers.value('authorization'), 'Bearer secret');
    expect(request.uri.queryParameters, isEmpty);
  });

  test('a refused upgrade is explained', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) {
      request.response.statusCode = HttpStatus.forbidden;
      unawaited(request.response.close());
    });
    await expectLater(
      connectWebSocket(Uri.parse('ws://127.0.0.1:${server.port}?tkn=bad')),
      throwsA(
        isA<ConnectionProblem>().having(
          (p) => p.message,
          'message',
          contains('HTTP 403'),
        ),
      ),
    );
  });

  test('a closed port is explained', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();
    await expectLater(
      connectWebSocket(Uri.parse('ws://127.0.0.1:$port')),
      throwsA(isA<ConnectionProblem>()),
    );
  });
}
