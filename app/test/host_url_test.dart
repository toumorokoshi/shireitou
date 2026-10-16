/// The connect screen's host URL check (web transport, AHP-001).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/screens/connect_screen.dart';

void main() {
  test('accepts ws(s), http(s) and bare addresses', () {
    for (final url in [
      'ws://127.0.0.1:63877?tkn=x',
      'wss://host.example',
      'https://abc.devtunnels.ms',
      'http://10.0.0.2:8080',
      '127.0.0.1:63877',
    ]) {
      expect(validateHostUrl(url), isNull, reason: url);
    }
  });

  test('rejects empty and non-WebSocket URLs', () {
    expect(validateHostUrl(''), isNotNull);
    expect(validateHostUrl(null), isNotNull);
    expect(validateHostUrl('ftp://h'), contains('ws://'));
  });

  test('an https page cannot reach ws:// on another machine', () {
    final page = Uri.parse('https://shireitou.example/');
    expect(
      validateHostUrl('ws://192.168.1.5:1', page: page),
      contains('wss://'),
    );
    expect(validateHostUrl('ws://localhost:1', page: page), isNull);
    expect(validateHostUrl('wss://192.168.1.5:1', page: page), isNull);
  });
}
