import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

SessionState _reduce(SessionState state, JsonMap action) =>
    reduceSession(state, SessionAction.fromJson(action));

void main() {
  final state = SessionState.fromJson({
    'provider': 'pi',
    'title': 'New session',
    'status': 1,
    'lifecycle': 'creating',
    'activeClients': <Object?>[],
    'chats': [
      {
        'resource': 'ahp-chat:/a',
        'title': 'New session',
        'status': 1,
        'modifiedAt': '2026-01-01T00:00:00Z',
      },
    ],
  });

  test('ready and creationFailed set the lifecycle', () {
    expect(
      _reduce(state, {'type': 'session/ready'}).lifecycle,
      SessionLifecycle.ready,
    );
    final failed = _reduce(state, {
      'type': 'session/creationFailed',
      'error': {'errorType': 'x', 'message': 'no model'},
    });
    expect(failed.lifecycle, SessionLifecycle.failed);
    expect(failed.creationError?.message, 'no model');
  });

  test('chatUpdated merges partial summaries', () {
    final next = _reduce(state, {
      'type': 'session/chatUpdated',
      'chat': 'ahp-chat:/a',
      'changes': {'status': 8, 'activity': 'Thinking'},
    });
    expect(next.chats.single.status.isInProgress, isTrue);
    expect(next.chats.single.activity, 'Thinking');
    expect(next.chats.single.title, 'New session');
  });

  test('chat added, default chat and removal', () {
    final added = _reduce(state, {
      'type': 'session/chatAdded',
      'summary': {
        'resource': 'ahp-chat:/b',
        'title': 'side',
        'status': 1,
        'modifiedAt': '2026-01-01T00:00:00Z',
      },
    });
    final defaulted = _reduce(added, {
      'type': 'session/defaultChatChanged',
      'defaultChat': 'ahp-chat:/b',
    });
    expect(defaultChatOf(defaulted), 'ahp-chat:/b');
    final removed = _reduce(defaulted, {
      'type': 'session/chatRemoved',
      'chat': 'ahp-chat:/b',
    });
    expect(defaultChatOf(removed), 'ahp-chat:/a');
  });

  test('title, read, archived and activity', () {
    var next = _reduce(state, {'type': 'session/titleChanged', 'title': 'T'});
    next = _reduce(next, {'type': 'session/isReadChanged', 'isRead': true});
    next = _reduce(next, {
      'type': 'session/isArchivedChanged',
      'isArchived': true,
    });
    next = _reduce(next, {
      'type': 'session/activityChanged',
      'activity': 'Running ls',
    });
    expect(next.title, 'T');
    expect(next.status.isReadFlag, isTrue);
    expect(next.status.isArchivedFlag, isTrue);
    expect(next.status.isIdle, isTrue);
    expect(next.activity, 'Running ls');
  });

  test('unknown actions are ignored', () {
    expect(_reduce(state, {'type': 'session/fromTheFuture'}), state);
  });

  group('input needed (session-level requests)', () {
    final running = state.copyWith(status: SessionStatus.inProgress);
    const confirmation = {
      'kind': 'toolConfirmation',
      'id': 'c1',
      'chat': 'ahp-chat:/a',
      'turnId': 't1',
      'toolCall': {
        'status': 'pending-confirmation',
        'toolCallId': 'tc1',
        'toolName': 'bash',
        'displayName': 'Bash',
        'invocationMessage': 'Run ls',
      },
    };
    const clientExecution = {
      'kind': 'toolClientExecution',
      'id': 'x1',
      'chat': 'ahp-chat:/a',
      'turnId': 't1',
      'clientId': 'c',
      'toolCall': {
        'status': 'running',
        'toolCallId': 'tc2',
        'toolName': 'mine',
        'displayName': 'Mine',
        'invocationMessage': 'Run mine',
        'confirmed': 'not-needed',
        'contributor': {'kind': 'client', 'clientId': 'c'},
      },
    };

    test('a user-blocking entry raises InputNeeded; removing it falls back '
        'to InProgress', () {
      final set = _reduce(running.copyWith(status: SessionStatus(8 | 32)), {
        'type': 'session/inputNeededSet',
        'request': confirmation,
      });
      expect(set.inputNeeded!.single, isA<SessionToolConfirmationRequest>());
      expect(set.status.isInputNeeded, isTrue);
      expect(set.status.isReadFlag, isTrue);
      final updated = _reduce(set, {
        'type': 'session/inputNeededSet',
        'request': {...confirmation, 'turnId': 't2'},
      });
      expect(updated.inputNeeded, hasLength(1));
      expect(
        (updated.inputNeeded!.single as SessionToolConfirmationRequest).turnId,
        't2',
      );
      final removed = _reduce(updated, {
        'type': 'session/inputNeededRemoved',
        'id': 'c1',
      });
      expect(removed.inputNeeded, isNull);
      expect(removed.status.isInputNeeded, isFalse);
      expect(removed.status.isInProgress, isTrue);
      expect(removed.status.isReadFlag, isTrue);
      expect(
        _reduce(removed, {'type': 'session/inputNeededRemoved', 'id': 'c1'}),
        same(removed),
      );
    });

    test('client tool execution does not need the user', () {
      final set = _reduce(running, {
        'type': 'session/inputNeededSet',
        'request': clientExecution,
      });
      expect(set.inputNeeded, hasLength(1));
      expect(set.status.isInputNeeded, isFalse);
      expect(set.status.isInProgress, isTrue);
    });
  });

  test('chatsReordered applies only permutations', () {
    final two = _reduce(state, {
      'type': 'session/chatAdded',
      'summary': {
        'resource': 'ahp-chat:/b',
        'title': 'b',
        'status': 1,
        'modifiedAt': '2026-01-01T00:00:00Z',
      },
    });
    final reordered = _reduce(two, {
      'type': 'session/chatsReordered',
      'chats': ['ahp-chat:/b', 'ahp-chat:/a'],
    });
    expect(
      [for (final c in reordered.chats) c.resource],
      ['ahp-chat:/b', 'ahp-chat:/a'],
    );
    for (final chats in [
      ['ahp-chat:/a'],
      ['ahp-chat:/a', 'ahp-chat:/a'],
      ['ahp-chat:/a', 'ahp-chat:/x'],
      ['ahp-chat:/a', 'ahp-chat:/b'],
    ]) {
      expect(
        _reduce(two, {'type': 'session/chatsReordered', 'chats': chats}),
        same(two),
      );
    }
  });

  test('working directories are set, removed and replaced', () {
    var next = _reduce(state, {
      'type': 'session/workingDirectorySet',
      'directory': '/a',
    });
    next = _reduce(next, {
      'type': 'session/workingDirectorySet',
      'directory': '/b',
    });
    expect(
      _reduce(next, {'type': 'session/workingDirectorySet', 'directory': '/a'}),
      same(next),
    );
    expect(next.workingDirectories, ['/a', '/b']);
    expect(
      _reduce(next, {
        'type': 'session/workingDirectoryReplaced',
        'directory': '/a',
        'replacement': '/c',
      }).workingDirectories,
      ['/c', '/b'],
    );
    // Replacing with a directory listed earlier drops the replaced one.
    expect(
      _reduce(next, {
        'type': 'session/workingDirectoryReplaced',
        'directory': '/b',
        'replacement': '/a',
      }).workingDirectories,
      ['/a'],
    );
    // Replacing with one listed later moves it into the replaced slot.
    expect(
      _reduce(next, {
        'type': 'session/workingDirectoryReplaced',
        'directory': '/a',
        'replacement': '/b',
      }).workingDirectories,
      ['/b'],
    );
    expect(
      _reduce(next, {
        'type': 'session/workingDirectoryRemoved',
        'directory': '/a',
      }).workingDirectories,
      ['/b'],
    );
  });

  test('changesets, server tools, active clients and _meta', () {
    var next = _reduce(state, {
      'type': 'session/changesetsChanged',
      'changesets': [
        {
          'label': 'Session',
          'uriTemplate': 'ahp-changeset:/s',
          'changeKind': 'session',
        },
      ],
    });
    expect(next.changesets!.single.label, 'Session');
    expect(
      _reduce(next, {'type': 'session/changesetsChanged'}).changesets,
      isNull,
    );
    next = _reduce(next, {
      'type': 'session/serverToolsChanged',
      'tools': [
        {'name': 'grep'},
      ],
    });
    expect(next.serverTools!.single.name, 'grep');
    next = _reduce(next, {
      'type': 'session/activeClientSet',
      'activeClient': {'clientId': 'c1', 'tools': <Object?>[]},
    });
    next = _reduce(next, {
      'type': 'session/activeClientSet',
      'activeClient': {
        'clientId': 'c1',
        'displayName': 'Desk',
        'tools': <Object?>[],
      },
    });
    expect(next.activeClients.single.displayName, 'Desk');
    next = _reduce(next, {
      'type': 'session/activeClientRemoved',
      'clientId': 'c1',
    });
    expect(next.activeClients, isEmpty);
    next = _reduce(next, {
      'type': 'session/metaChanged',
      '_meta': {'pr': 'https://example.com/1'},
    });
    expect(next.meta, {'pr': 'https://example.com/1'});
  });

  group('customizations and MCP servers', () {
    final withCustomizations = _reduce(state, {
      'type': 'session/customizationsChanged',
      'customizations': [
        {
          'type': 'mcpServer',
          'id': 'm1',
          'uri': 'file:///mcp.json#m1',
          'name': 'Docs',
          'state': {'kind': 'ready'},
          'channel': 'ahp-mcp:/m1',
        },
        {
          'type': 'plugin',
          'id': 'p1',
          'uri': 'file:///plugin',
          'name': 'Plugin',
          'children': [
            {
              'type': 'skill',
              'id': 's1',
              'uri': 'file:///plugin/skill',
              'name': 'Skill',
            },
            {
              'type': 'mcpServer',
              'id': 'm2',
              'uri': 'file:///plugin/mcp',
              'name': 'Inner',
              'state': {'kind': 'starting', 'blocking': true},
            },
          ],
        },
      ],
    });

    McpServerCustomization inner(SessionState s) =>
        (s.customizations![1] as PluginCustomization).children![1]
            as McpServerCustomization;

    test('toggling sets enablement or the legacy enabled flag', () {
      const decision = {'kind': 'global', 'enabled': false};
      final plugin = _reduce(withCustomizations, {
        'type': 'session/customizationToggled',
        'id': 'p1',
        'enablement': [decision],
      });
      expect(
        (plugin.customizations![1] as PluginCustomization)
            .enablement!
            .single
            .enabled,
        isFalse,
      );
      final skill = _reduce(withCustomizations, {
        'type': 'session/customizationToggled',
        'id': 's1',
        'enablement': [decision],
      });
      expect(
        ((skill.customizations![1] as PluginCustomization).children![0]
                as SkillCustomization)
            .enabled,
        isFalse,
      );
      final cleared = _reduce(plugin, {
        'type': 'session/customizationToggled',
        'id': 'p1',
        'enablement': <Object?>[],
      });
      expect(
        (cleared.customizations![1] as PluginCustomization).enablement,
        isNull,
      );
    });

    test('updated upserts and removed removes, also children', () {
      final updated = _reduce(withCustomizations, {
        'type': 'session/customizationUpdated',
        'customization': {
          'type': 'mcpServer',
          'id': 'm3',
          'uri': 'file:///m3',
          'name': 'New',
          'state': {'kind': 'stopped'},
        },
      });
      expect(updated.customizations, hasLength(3));
      final removed = _reduce(updated, {
        'type': 'session/customizationRemoved',
        'id': 's1',
      });
      expect(
        (removed.customizations![1] as PluginCustomization).children,
        hasLength(1),
      );
      expect(
        _reduce(removed, {
          'type': 'session/customizationRemoved',
          'id': 'm3',
        }).customizations,
        hasLength(2),
      );
      expect(
        _reduce(removed, {'type': 'session/customizationRemoved', 'id': 'x'}),
        same(removed),
      );
    });

    test('MCP server state, start, background and stop', () {
      final authRequired = _reduce(withCustomizations, {
        'type': 'session/mcpServerStateChanged',
        'id': 'm1',
        'state': {
          'kind': 'authRequired',
          'reason': 'required',
          'resource': {'resource': 'https://mcp.example.com'},
        },
      });
      final top = authRequired.customizations![0] as McpServerCustomization;
      expect(top.state, isA<McpServerAuthRequiredState>());
      expect(top.channel, isNull);

      final started = _reduce(authRequired, {
        'type': 'session/mcpServerStartRequested',
        'id': 'm1',
      });
      expect(
        (started.customizations![0] as McpServerCustomization).state,
        isA<McpServerStartingState>(),
      );

      final backgrounded = _reduce(withCustomizations, {
        'type': 'session/mcpServerBackgroundRequested',
        'id': 'm2',
      });
      expect(
        (inner(backgrounded).state as McpServerStartingState).blocking,
        isFalse,
      );
      expect(
        _reduce(backgrounded, {
          'type': 'session/mcpServerBackgroundRequested',
          'id': 'm2',
        }),
        same(backgrounded),
      );

      final stopped = _reduce(withCustomizations, {
        'type': 'session/mcpServerStopRequested',
        'id': 'm2',
      });
      expect(inner(stopped).state, isA<McpServerStoppedState>());
      // A non-MCP customization with that ID is left alone.
      expect(
        _reduce(withCustomizations, {
          'type': 'session/mcpServerStopRequested',
          'id': 's1',
        }),
        same(withCustomizations),
      );
    });
  });

  test('resolveSessionResource matches the host URI by trailing ID', () {
    final catalogue = catalogueFromSummaries([
      _summary('pi:/abc'),
      _summary('pi:/def'),
    ]);
    expect(resolveSessionResource(catalogue, 'ahp-session:/abc'), 'pi:/abc');
    expect(resolveSessionResource(catalogue, 'pi:/def'), 'pi:/def');
    expect(resolveSessionResource(catalogue, 'ahp-session:/x'), isNull);
  });
}

SessionSummary _summary(String resource) => SessionSummary(
  resource: resource,
  provider: 'pi',
  title: 't',
  status: SessionStatus.idle,
  createdAt: '2026-01-01T00:00:00Z',
  modifiedAt: '2026-01-01T00:00:00Z',
);
