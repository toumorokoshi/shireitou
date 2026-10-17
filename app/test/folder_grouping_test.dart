import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';

import 'fixtures.dart';

void main() {
  group('normalizeFolderKey', () {
    test('decodes file URIs and strips the trailing slash', () {
      expect(normalizeFolderKey('file:///home/u/my%20app/'), '/home/u/my app');
    });

    test('keeps the filesystem root and non-file URIs', () {
      expect(normalizeFolderKey('file:///'), '/');
      expect(
        normalizeFolderKey('vscode-remote://box/src'),
        'vscode-remote://box/src',
      );
    });
  });

  group('groupSessionsByFolder', () {
    test('worktrees of one repo are separate folders', () {
      final groups = groupSessionsByFolder([
        session('1', directory: 'file:///src/app'),
        session('2', directory: 'file:///src/app-worktrees/fix-login'),
        session('3', directory: 'file:///src/app/'),
      ]);
      expect(groups.map((g) => g.key), [
        '/src/app',
        '/src/app-worktrees/fix-login',
      ]);
      expect(groups.first.sessions.length, 2);
      expect(groups.last.label, 'fix-login');
      expect(groups.last.path, '/src/app-worktrees/fix-login');
    });

    test('falls back to the project, then to "No folder"', () {
      final groups = groupSessionsByFolder([
        session('1', project: 'file:///src/proj'),
        session('2'),
      ]);
      expect(groups.map((g) => g.label), ['proj', noFolderLabel]);
      expect(groups.last.key, isNull);
      expect(groups.last.path, isEmpty);
    });

    test('folders and sessions sort by most recent modification', () {
      final groups = groupSessionsByFolder([
        session(
          'old',
          directory: 'file:///a',
          modifiedAt: '2026-10-01T00:00:00Z',
        ),
        session(
          'new',
          directory: 'file:///b',
          modifiedAt: '2026-10-03T00:00:00Z',
        ),
        session(
          'mid',
          directory: 'file:///a',
          modifiedAt: '2026-10-02T00:00:00Z',
        ),
      ]);
      expect(groups.map((g) => g.key), ['/b', '/a']);
      expect(groups.last.sessions.map((s) => s.resource), [
        'pi:/mid',
        'pi:/old',
      ]);
    });

    test('counts sessions that need attention', () {
      final groups = groupSessionsByFolder([
        session('read', directory: 'file:///a', status: 33),
        session('unread', directory: 'file:///a', status: 1),
        session('input', directory: 'file:///a', status: 24 | 32),
        session('error', directory: 'file:///a', status: 2 | 32),
      ]);
      expect(groups.single.attentionCount, 3);
    });

    test('no sessions means no folders', () {
      expect(groupSessionsByFolder([]), isEmpty);
    });
  });

  group('hosts and worktree metadata', () {
    test('the same path on two hosts is two folders', () {
      final groups = groupHostSessions([
        HostSession('ws://a', session('1', directory: 'file:///src/app')),
        HostSession('ws://b', session('2', directory: 'file:///src/app')),
      ]);
      expect(groups.map((g) => g.host), unorderedEquals(['ws://a', 'ws://b']));
      expect(groups.map((g) => g.id).toSet(), hasLength(2));
    });

    test('repo and branch come from the project and _meta.git', () {
      final worktree = session('1', directory: 'file:///src/app-worktrees/fix')
          .copyWith(
            project: const ProjectInfo(
              uri: 'file:///src/app',
              displayName: 'app',
            ),
            meta: {
              'git': {'branchName': 'fix'},
            },
          );
      expect(worktreeInfoOf(worktree), (repo: 'app', branch: 'fix'));
      final root = worktree.copyWith(workingDirectories: ['file:///src/app/']);
      expect(worktreeInfoOf(root).repo, isNull);
      expect(worktreeInfoOf(session('2')), (repo: null, branch: null));
      final group = groupSessionsByFolder([worktree]).single;
      expect(group.repo, 'app');
      expect(group.branch, 'fix');
      expect(folderDetails(group), 'app · ⎇ fix · /src/app-worktrees/fix');
      expect(folderDetails(groupSessionsByFolder([session('3')]).single), '');
    });

    test('recentFolders lists a host\'s folders, newest first', () {
      final sessions = [
        HostSession(
          'a',
          session('1', directory: 'file:///x', modifiedAt: '2026-10-01'),
        ),
        HostSession(
          'a',
          session('2', directory: 'file:///y/', modifiedAt: '2026-10-03'),
        ),
        HostSession(
          'a',
          session('3', directory: 'file:///x', modifiedAt: '2026-10-02'),
        ),
        HostSession('b', session('4', directory: 'file:///z')),
      ];
      expect(recentFolders(sessions, 'a'), ['/y', '/x']);
    });
  });

  test('workspaceLabel writes "folder [project]" from the host\'s project', () {
    final group = groupSessionsByFolder([
      session('1', directory: 'file:///src/cruise-4', project: 'cruise'),
    ]).single;
    expect(group.project, 'cruise');
    expect(workspaceLabel(group.label, group.project), 'cruise-4 [cruise]');
    expect(projectNameOf(session('2')), isNull);
    expect(workspaceLabel('app', null), 'app');
  });
}
