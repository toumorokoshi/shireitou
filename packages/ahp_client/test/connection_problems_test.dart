import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeHostUri', () {
    test('maps http(s) to ws(s) and adds a missing scheme', () {
      expect(
        normalizeHostUri('https://abc.devtunnels.ms/?tkn=x').toString(),
        'wss://abc.devtunnels.ms/?tkn=x',
      );
      expect(
        normalizeHostUri(' http://10.0.0.5:8080 ').toString(),
        'ws://10.0.0.5:8080',
      );
      expect(
        normalizeHostUri('127.0.0.1:63877?tkn=t').toString(),
        'ws://127.0.0.1:63877?tkn=t',
      );
      expect(normalizeHostUri('wss://h:1').toString(), 'wss://h:1');
    });
  });

  test('isLoopbackHost', () {
    for (final host in [
      'localhost',
      'app.localhost',
      '127.0.0.1',
      '127.1.2.3',
      '::1',
    ]) {
      expect(isLoopbackHost(host), isTrue, reason: host);
    }
    for (final host in [
      '10.0.0.5',
      '192.168.1.2',
      'example.com',
      '128.0.0.1',
    ]) {
      expect(isLoopbackHost(host), isFalse, reason: host);
    }
  });

  group('transportProblem', () {
    final https = Uri.parse('https://app.example.com/');
    test('blocks ws:// to another machine from an https page', () {
      expect(
        transportProblem(Uri.parse('ws://192.168.1.2:63877'), page: https),
        contains('wss://'),
      );
    });

    test('allows wss://, loopback ws://, http pages and native', () {
      expect(
        transportProblem(Uri.parse('wss://h.example'), page: https),
        isNull,
      );
      expect(
        transportProblem(Uri.parse('ws://127.0.0.1:1'), page: https),
        isNull,
      );
      expect(
        transportProblem(
          Uri.parse('ws://192.168.1.2:1'),
          page: Uri.parse('http://localhost:8080/'),
        ),
        isNull,
      );
      expect(transportProblem(Uri.parse('ws://192.168.1.2:1')), isNull);
    });

    test('rejects other schemes', () {
      expect(transportProblem(Uri.parse('ftp://h')), contains('ws://'));
    });
  });

  group('describeTransportError', () {
    final host = Uri.parse('ws://10.0.0.5:63877');
    test('native: a refused upgrade names the token', () {
      const error =
          "WebSocketException: Connection to 'http://10.0.0.5:63877#' was "
          'not upgraded to websocket, HTTP status code: 403';
      expect(upgradeStatusOf(error), 403);
      expect(
        describeTransportError(error, host, web: false),
        allOf(contains('HTTP 403'), contains('token')),
      );
      expect(
        describeTransportError(
          error.replaceAll('403', '404'),
          host,
          web: false,
        ),
        contains('HTTP 404'),
      );
    });

    test('native: TLS, refused and lookup failures', () {
      expect(
        describeTransportError(
          'HandshakeException: CERTIFICATE_VERIFY_FAILED',
          host,
          web: false,
        ),
        contains('certificate'),
      );
      expect(
        describeTransportError(
          'SocketException: Connection refused',
          host,
          web: false,
        ),
        contains('Nothing is listening on 10.0.0.5:63877'),
      );
      expect(
        describeTransportError(
          'SocketException: Failed host lookup',
          host,
          web: false,
        ),
        contains('"10.0.0.5"'),
      );
    });

    test('web: lists the causes a browser hides', () {
      final text = describeTransportError(
        'WebSocketChannelException',
        host,
        web: true,
      );
      expect(
        text,
        allOf(contains('token'), contains('origin'), contains('127.0.0.1')),
      );
    });
  });
}
