import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';
import 'package:shireitou/src/session_list/session_query.dart';
import 'package:shireitou/src/session_list/session_tree.dart';

import 'fixtures.dart';

HostInfo _host(String url, String label) => HostInfo(
  host: SavedHost(url: url),
  status: ConnectionStatus.connected,
  label: label,
);

final _laptop = _host('ws://a', 'laptop');
final _box = _host('ws://b', 'build box');

final _groups = groupHostSessions([
  HostSession('ws://a', session('1', directory: 'file:///src/app')),
  HostSession('ws://a', session('2', directory: 'file:///src/lib')),
  HostSession('ws://b', session('3', directory: 'file:///src/app')),
]);

final _chats = [
  HostSession('ws://a', session('4')),
  HostSession('ws://b', session('5')),
];

final _pinned = [
  HostSession('ws://b', session('9', directory: 'file:///src/web')),
  HostSession('ws://a', session('8')),
];

List<Type> _types(List<SidebarRow> rows) => [
  for (final r in rows) r.runtimeType,
];

void main() {
  group('sidebarRows', () {
    test('lists Pinned, Chats, then each folder with its sessions', () {
      final rows = sidebarRows(
        collapsed: const {},
        pinned: _pinned,
        chats: _chats,
        folders: _groups,
      );
      expect(_types(rows), [
        SectionRow,
        SessionItem,
        SessionItem,
        SectionRow,
        SessionItem,
        SessionItem,
        FolderRow,
        SessionItem,
        FolderRow,
        SessionItem,
        FolderRow,
        SessionItem,
      ]);
      expect((rows.first as SectionRow).id, pinnedNodeId);
      expect((rows[3] as SectionRow).id, chatsNodeId);
    });

    test('leaves out empty sections and has no host rows', () {
      expect(_types(sidebarRows(collapsed: const {}, folders: _groups)), [
        FolderRow,
        SessionItem,
        FolderRow,
        SessionItem,
        FolderRow,
        SessionItem,
      ]);
      expect(sidebarRows(collapsed: const {}), isEmpty);
    });

    test('skips the sessions of collapsed sections and folders', () {
      final rows = sidebarRows(
        collapsed: {pinnedNodeId, chatsNodeId, _groups.first.id},
        pinned: _pinned,
        chats: _chats,
        folders: _groups,
      );
      expect(_types(rows), [
        SectionRow,
        SectionRow,
        FolderRow,
        FolderRow,
        SessionItem,
        FolderRow,
        SessionItem,
      ]);
      expect((rows.first as SectionRow).collapsed, isTrue);
      expect((rows[2] as FolderRow).collapsed, isTrue);
    });

    test('names the host on rows and folders when given labels', () {
      final labels = hostLabelsOf([_laptop, _box]);
      final rows = sidebarRows(
        collapsed: const {},
        pinned: _pinned,
        folders: _groups,
        hostLabels: labels,
      );
      expect(
        [for (final r in rows.skip(1).take(2)) (r as SessionItem).place],
        ['web · build box', 'laptop'],
      );
      expect((rows[1] as SessionItem).ref, (host: 'ws://b', session: 'pi:/9'));
      expect([
        for (final r in rows)
          if (r is FolderRow) r.hostLabel,
      ], containsAll(['laptop', 'build box']));
    });

    test('names only the workspace with one host', () {
      final rows = sidebarRows(
        collapsed: const {},
        folders: _groups,
        hostLabels: hostLabelsOf([_laptop]),
      );
      expect((rows.first as FolderRow).hostLabel, isNull);
      expect((rows[1] as SessionItem).place, 'app');
    });

    test('marks a section that needs attention', () {
      final rows = sidebarRows(
        collapsed: const {},
        chats: [HostSession('ws://a', session('6', status: 1))],
        pinned: _pinned,
      );
      expect(
        [
          for (final r in rows)
            if (r is SectionRow) r.hasAttention,
        ],
        [false, true],
      );
    });
  });

  test('sessionPlace writes "folder [project]" and the host', () {
    expect(
      sessionPlace(
        session('1', directory: 'file:///src/cruise-4', project: 'cruise'),
        hostLabel: 'box',
      ),
      'cruise-4 [cruise] · box',
    );
    expect(sessionPlace(session('2')), '');
  });

  test('chatSessions keeps sessions with no folder, in sort order', () {
    final chats = chatSessions([
      HostSession('ws://a', session('1', modifiedAt: '2026-10-01T00:00:00Z')),
      HostSession('ws://a', session('2', directory: 'file:///src/app')),
      HostSession('ws://b', session('3', modifiedAt: '2026-10-02T00:00:00Z')),
    ]);
    expect([for (final s in chats) s.summary.resource], ['pi:/3', 'pi:/1']);
    expect(
      [
        for (final s in chatSessions(chats, sort: SessionSort.oldest))
          s.summary.resource,
      ],
      ['pi:/1', 'pi:/3'],
    );
  });

  test('hostLabelsOf is empty for one host', () {
    expect(hostLabelsOf([_laptop]), isEmpty);
    expect(hostLabelsOf([_laptop, _box]), {
      'ws://a': 'laptop',
      'ws://b': 'build box',
    });
  });

  test('toggledNode adds and removes an id', () {
    expect(toggledNode(const {}, 'x'), {'x'});
    expect(toggledNode({'x', 'y'}, 'x'), {'y'});
  });

  test('revealSession expands the folder of a session', () {
    final folder = _groups.firstWhere((g) => g.host == 'ws://b');
    expect(
      revealSession(
        {'other', chatsNodeId, folder.id},
        _groups,
        (host: 'ws://b', session: 'pi:/3'),
      ),
      {'other', chatsNodeId},
    );
  });

  test('revealSession expands the Pinned or Chats section', () {
    const pinned = (host: 'ws://a', session: 'pi:/8');
    const chat = (host: 'ws://a', session: 'pi:/4');
    final collapsed = {pinnedNodeId, chatsNodeId};
    expect(revealSession(collapsed, _groups, pinned, pinned: [pinned]), {
      chatsNodeId,
    });
    expect(revealSession(collapsed, _groups, chat, chats: [chat]), {
      pinnedNodeId,
    });
  });

  test('hostsTitle names the narrowed host, the only host or all', () {
    expect(hostsTitle([_laptop, _box], 'ws://b'), 'build box');
    expect(hostsTitle([_laptop], null), 'laptop');
    expect(hostsTitle([_laptop, _box], null), 'All hosts');
    expect(hostsTitle(const [], null), 'shireitou');
  });
}
