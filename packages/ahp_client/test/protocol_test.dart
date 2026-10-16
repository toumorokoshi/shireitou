import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  group('withConnectionToken', () {
    test('adds tkn as a query parameter', () {
      final uri = withConnectionToken(Uri.parse('ws://127.0.0.1:1'), 'abc');
      expect(uri.queryParameters, {'tkn': 'abc'});
    });

    test('keeps a token already in the URL when none is given', () {
      final uri = Uri.parse('ws://127.0.0.1:1?tkn=abc');
      expect(withConnectionToken(uri, ''), uri);
      expect(withConnectionToken(uri, null), uri);
    });
  });

  test('initializeParams offers 1.0.0 then 0.9.0 on the root channel', () {
    final params = initializeParams(
      clientId: 'c',
      clientInfo: const {'name': 'shireitou'},
      initialSubscriptions: const [rootChannel],
    );
    expect(params['channel'], rootChannel);
    expect(params['protocolVersions'], ['1.0.0', '0.9.0']);
    expect(params.containsKey('locale'), isFalse);
  });

  test('describeRpcError lists the host versions for -32005', () {
    final text = describeRpcError(-32005, 'Unsupported protocol version', {
      'supportedVersions': ['2.0.0'],
    });
    expect(text, contains('host supports 2.0.0'));
  });

  test('reconnectDelay doubles up to the cap', () {
    expect(reconnectDelay(0), const Duration(milliseconds: 500));
    expect(reconnectDelay(1), const Duration(seconds: 1));
    expect(reconnectDelay(3), const Duration(seconds: 4));
    expect(reconnectDelay(40), const Duration(seconds: 30));
  });
}
