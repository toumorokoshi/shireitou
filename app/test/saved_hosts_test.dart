import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';

void main() {
  const a = SavedHost(url: 'ws://127.0.0.1:1?tkn=old', name: 'laptop');
  const b = SavedHost(url: 'wss://box.example:443/ahp', token: 't');

  test('hostKey drops the token but keeps the rest of the URL', () {
    expect(hostKey('ws://127.0.0.1:1?tkn=abc'), 'ws://127.0.0.1:1');
    expect(hostKey(' ws://h:2/p?x=1&tkn=abc '), 'ws://h:2/p?x=1');
  });

  test('label never shows the token', () {
    expect(a.label, 'laptop');
    expect(const SavedHost(url: 'ws://h:1?tkn=secret').label, 'ws://h:1');
  });

  test('rememberHost puts the host first and replaces the same host', () {
    final hosts = rememberHost([
      a,
      b,
    ], const SavedHost(url: 'wss://box.example:443/ahp', token: 'new'));
    expect(hosts.map((h) => h.key), [
      'wss://box.example:443/ahp',
      'ws://127.0.0.1:1',
    ]);
    expect(hosts.first.token, 'new');
  });

  test('rememberHost keeps the old name and a rotated token', () {
    final hosts = rememberHost([
      a,
    ], const SavedHost(url: 'ws://127.0.0.1:1?tkn=new'));
    expect(hosts, [
      const SavedHost(url: 'ws://127.0.0.1:1?tkn=new', name: 'laptop'),
    ]);
  });

  test('rememberHost keeps at most max hosts', () {
    final hosts = rememberHost(
      [a, b],
      const SavedHost(url: 'ws://c:1'),
      max: 2,
    );
    expect(hosts.map((h) => h.key), ['ws://c:1', 'ws://127.0.0.1:1']);
  });

  test('forgetHost removes by key', () {
    expect(forgetHost([a, b], 'ws://127.0.0.1:1'), [b]);
  });

  test('encode and decode round-trip; bad input is skipped', () {
    expect(decodeHosts(encodeHosts([a, b])), [a, b]);
    expect(decodeHosts('not json'), isEmpty);
    expect(decodeHosts('[{"url": ""}, {"url": "ws://h:1"}, 3]'), [
      const SavedHost(url: 'ws://h:1'),
    ]);
    expect(decodeHosts(null), isEmpty);
  });

  group('HostStore', () {
    test('migrates the single host saved by earlier versions', () async {
      FlutterSecureStorage.setMockInitialValues({
        'last_host_url': 'ws://127.0.0.1:1?tkn=abc',
        'last_host_token': 'x',
      });
      const store = HostStore(FlutterSecureStorage());
      expect(await store.loadHosts(), [
        const SavedHost(url: 'ws://127.0.0.1:1?tkn=abc', token: 'x'),
      ]);
      final all = await const FlutterSecureStorage().readAll();
      expect(all.keys, ['hosts']);
    });

    test('saves and loads the list', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const store = HostStore(FlutterSecureStorage());
      expect(await store.loadHosts(), isEmpty);
      await store.saveHosts([a, b]);
      expect(await store.loadHosts(), [a, b]);
    });
  });
}
