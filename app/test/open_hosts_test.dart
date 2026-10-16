import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';

HostInfo _info(String url, {String name = '', String? server}) => HostInfo(
  host: SavedHost(url: url, name: name),
  status: ConnectionStatus.connected,
  serverName: server,
);

/// A store whose keyring is locked until [unlocked].
class _LockedStore extends HostStore {
  _LockedStore() : super(const FlutterSecureStorage());

  bool unlocked = false;
  List<SavedHost> saved = const [];

  void _check() {
    if (!unlocked) {
      throw PlatformException(
        code: 'KeyringLocked',
        message: 'Cannot create an item in a locked collection',
      );
    }
  }

  @override
  Future<List<SavedHost>> loadHosts() async {
    _check();
    return saved;
  }

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async {
    _check();
    saved = hosts;
  }
}

void main() {
  test('withHost replaces in place or appends', () {
    const a = SavedHost(url: 'ws://a:1?tkn=x');
    const b = SavedHost(url: 'ws://b:1');
    const a2 = SavedHost(url: 'ws://a:1?tkn=y', name: 'A');
    expect(withHost(const [a, b], a2), [a2, b]);
    expect(withHost(const [a], b), [a, b]);
  });

  test('hostLabels prefer names, then server names, and disambiguate', () {
    expect(
      hostLabels([
        _info('ws://a:1', name: 'laptop'),
        _info('ws://b:2', server: 'pi'),
        _info('ws://c:3', server: 'pi'),
        _info('ws://d:4?tkn=s'),
      ]),
      ['laptop', 'pi (b:2)', 'pi (c:3)', 'ws://d:4'],
    );
  });

  test('describeStorageError explains a locked keyring and no service', () {
    expect(
      describeStorageError(
        PlatformException(code: 'KeyringLocked'),
        reading: false,
      ),
      contains('keyring is locked'),
    );
    expect(
      describeStorageError(
        PlatformException(
          code: 'Libsecret error',
          message:
              'The name org.freedesktop.secrets was not provided by any '
              '.service files',
        ),
        reading: true,
      ),
      allOf(startsWith('Saved hosts could not be read'), contains('Secret')),
    );
    expect(
      describeStorageError(StateError('disk'), reading: false),
      contains('secure storage failed'),
    );
  });

  test('a locked keyring is reported, and retry saves once unlocked', () async {
    final store = _LockedStore();
    final container = ProviderContainer(
      overrides: [hostStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(await container.read(savedHostsProvider.future), isEmpty);
    expect(
      container.read(hostStorageProblemProvider),
      contains('keyring is locked'),
    );
    const host = SavedHost(url: 'ws://a:1', name: 'a');
    await container.read(savedHostsProvider.notifier).remember(host);
    expect(container.read(savedHostsProvider).value, [host]);
    expect(
      container.read(hostStorageProblemProvider),
      startsWith('Hosts are not being remembered'),
    );
    store
      ..unlocked = true
      ..saved = const [SavedHost(url: 'ws://b:1')];
    await container.read(savedHostsProvider.notifier).retry();
    expect(container.read(hostStorageProblemProvider), isNull);
    expect(store.saved.map((h) => h.key), ['ws://a:1', 'ws://b:1']);
  });
}
