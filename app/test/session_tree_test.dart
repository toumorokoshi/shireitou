import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';
import 'package:shireitou/src/session_list/session_tree.dart';

import 'fixtures.dart';

HostInfo _host(
  String url,
  String label, {
  ConnectionStatus status = ConnectionStatus.connected,
}) => HostInfo(
  host: SavedHost(url: url),
  status: status,
  label: label,
);

final _laptop = _host('ws://a', 'laptop');
final _box = _host('ws://b', 'build box');
final _down = _host('ws://c', 'down', status: ConnectionStatus.failed);

final _groups = groupHostSessions([
  HostSession('ws://a', session('1', directory: 'file:///src/app')),
  HostSession('ws://a', session('2', directory: 'file:///src/lib')),
  HostSession('ws://b', session('3', directory: 'file:///src/app')),
]);

void main() {
  group('sessionTree', () {
    test('puts each host\'s folders under it, in the hosts\' order', () {
      final tree = sessionTree([_box, _laptop], _groups);
      expect([for (final n in tree) n.host.label], ['build box', 'laptop']);
      expect([for (final f in tree.first.folders) f.path], ['/src/app']);
      expect([
        for (final f in tree.last.folders) f.path,
      ], unorderedEquals(['/src/app', '/src/lib']));
      expect(tree.last.sessionCount, 2);
      expect(tree.last.attentionCount, 0);
      expect(tree.every((n) => n.emptyText == null), isTrue);
    });

    test('says why a live host has no folders', () {
      final tree = sessionTree(
        [_laptop, _box, _down],
        const [],
        hostsWithSessions: {'ws://a'},
      );
      expect(
        [for (final n in tree) n.emptyText],
        [noMatchText, noSessionsText, null],
      );
    });

    test('a host whose sessions are all pinned gets no empty text', () {
      final tree = sessionTree(
        [_laptop],
        const [],
        hostsWithSessions: {'ws://a'},
        hostsWithPinned: {'ws://a'},
      );
      expect(tree.single.emptyText, isNull);
    });

    test('hosts other than the filter get no empty text', () {
      final tree = sessionTree([_laptop, _box], const [], hostFilter: 'ws://b');
      expect([for (final n in tree) n.emptyText], [null, noSessionsText]);
    });
  });

  group('sidebarRows', () {
    final tree = sessionTree([_laptop, _box], _groups);

    test('lists hosts, folders and sessions depth first', () {
      expect(
        [for (final r in sidebarRows(tree, const {})) r.runtimeType],
        [
          HostRow,
          FolderRow,
          SessionItem,
          FolderRow,
          SessionItem,
          HostRow,
          FolderRow,
          SessionItem,
        ],
      );
    });

    test('skips the children of collapsed hosts and folders', () {
      final folder = tree.first.folders.first;
      final rows = sidebarRows(tree, {'ws://b', folder.id});
      expect(
        [for (final r in rows) r.runtimeType],
        [HostRow, FolderRow, FolderRow, SessionItem, HostRow],
      );
      expect((rows[1] as FolderRow).collapsed, isTrue);
      expect((rows.last as HostRow).collapsed, isTrue);
    });

    final pinned = [
      HostSession('ws://b', session('9', directory: 'file:///src/web')),
      HostSession('ws://a', session('8')),
    ];

    test('puts the Pinned section first, naming host and folder', () {
      final rows = sidebarRows(tree, const {}, pinned: pinned);
      expect(
        [for (final r in rows.take(4)) r.runtimeType],
        [PinnedRow, SessionItem, SessionItem, HostRow],
      );
      expect((rows.first as PinnedRow).sessions, hasLength(2));
      expect(
        [for (final r in rows.skip(1).take(2)) (r as SessionItem).place],
        ['build box · web', 'laptop · $noFolderLabel'],
      );
      expect((rows[1] as SessionItem).ref, (host: 'ws://b', session: 'pi:/9'));
      expect([
        for (final r in rows.skip(3))
          if (r is SessionItem) r.place,
      ], everyElement(isNull));
    });

    test('names only the folder with one host', () {
      final rows = sidebarRows(
        sessionTree([_laptop], _groups),
        const {},
        pinned: [pinned.last],
      );
      expect((rows[1] as SessionItem).place, noFolderLabel);
    });

    test('collapses the Pinned section, and has none with no pins', () {
      final rows = sidebarRows(tree, {pinnedNodeId}, pinned: pinned);
      expect((rows.first as PinnedRow).collapsed, isTrue);
      expect(rows[1], isA<HostRow>());
      expect(sidebarRows(tree, const {}).first, isA<HostRow>());
    });

    test('shows the empty text under its host', () {
      final rows = sidebarRows(
        sessionTree([_laptop], const [], hostsWithSessions: {}),
        const {},
      );
      expect((rows.last as EmptyRow).text, noSessionsText);
    });
  });

  test('toggledNode adds and removes an id', () {
    expect(toggledNode(const {}, 'x'), {'x'});
    expect(toggledNode({'x', 'y'}, 'x'), {'y'});
  });

  test('revealSession expands the host and folder of a session', () {
    final folder = _groups.firstWhere((g) => g.host == 'ws://b');
    expect(
      revealSession(
        {'ws://a', 'ws://b', folder.id},
        _groups,
        (host: 'ws://b', session: 'pi:/3'),
      ),
      {'ws://a'},
    );
  });

  test('revealSession expands the Pinned section for a pinned session', () {
    const pinned = (host: 'ws://a', session: 'pi:/8');
    expect(
      revealSession(
        {pinnedNodeId, 'ws://a'},
        _groups,
        pinned,
        pinned: [pinned],
      ),
      {'ws://a'},
    );
  });

  test('hostsTitle names the narrowed host, the only host or all', () {
    expect(hostsTitle([_laptop, _box], 'ws://b'), 'build box');
    expect(hostsTitle([_laptop], null), 'laptop');
    expect(hostsTitle([_laptop, _box], null), 'All hosts');
    expect(hostsTitle(const [], null), 'shireitou');
  });
}
