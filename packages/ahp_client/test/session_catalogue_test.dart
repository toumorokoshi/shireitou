import 'dart:convert';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

SessionSummary summary(String resource, {String title = 't'}) => SessionSummary(
  resource: resource,
  provider: 'pi',
  title: title,
  status: SessionStatus.idle,
  createdAt: '2026-01-01T00:00:00Z',
  modifiedAt: '2026-01-01T00:00:00Z',
  project: const ProjectInfo(uri: 'file:///p', displayName: 'p'),
);

/// Host-to-client messages recorded from pi-agent-host-protocol.
List<JsonMap> recordedHostMessages() {
  final file = File('../../examples/ahp/pi-host-root-catalogue.json');
  final entries = (jsonDecode(file.readAsStringSync()) as List<Object?>)
      .cast<JsonMap>();
  return [
    for (final entry in entries)
      if (entry['dir'] == 'host->client') entry['message']! as JsonMap,
  ];
}

void main() {
  group('session catalogue', () {
    test('sessionAdded inserts and replaces by resource', () {
      final added = applySessionAdded(emptyCatalogue, summary('a'));
      final replaced = applySessionAdded(added, summary('a', title: 'new'));
      expect(replaced.length, 1);
      expect(replaced['a']!.title, 'new');
    });

    test('sessionRemoved drops the entry', () {
      final catalogue = catalogueFromSummaries([summary('a'), summary('b')]);
      expect(applySessionRemoved(catalogue, 'a').keys, ['b']);
    });

    test('sessionSummaryChanged merges a partial summary', () {
      final catalogue = catalogueFromSummaries([summary('a')]);
      final next = applySessionSummaryChanged(catalogue, 'a', const {
        'title': 'renamed',
        'status': 8,
        'changes': {'additions': 3, 'deletions': 1, 'files': 2},
      });
      expect(next['a']!.title, 'renamed');
      expect(next['a']!.status.isInProgress, isTrue);
      expect(
        next['a']!.changes,
        const ChangesSummary(additions: 3, deletions: 1, files: 2),
      );
      expect(next['a']!.project, catalogue['a']!.project);
    });

    test('sessionSummaryChanged for an unknown session is ignored', () {
      final catalogue = catalogueFromSummaries([summary('a')]);
      expect(
        applySessionSummaryChanged(catalogue, 'z', const {'title': 'x'}),
        same(catalogue),
      );
    });

    test('catalogues are unmodifiable', () {
      final catalogue = catalogueFromSummaries([summary('a')]);
      expect(() => catalogue['b'] = summary('b'), throwsUnsupportedError);
    });
  });

  test('replays recorded pi host traffic', () {
    var state = const HostState();
    final titles = <String>[];
    for (final message in recordedHostMessages()) {
      final result = message['result'];
      final method = message['method'] as String?;
      if (result is JsonMap && result.containsKey('protocolVersion')) {
        state = applyInitializeResult(state, InitializeResult.fromJson(result));
      } else if (result is JsonMap && result.containsKey('items')) {
        state = state.copyWith(
          sessions: catalogueFromSummaries(
            ListSessionsResult.fromJson(result).items,
          ),
        );
      } else if (method == 'action') {
        state = applyEnvelope(
          state,
          ActionEnvelope.fromJson(message['params']! as JsonMap),
          clientId: 'example-client',
        );
      } else if (method != null && method.startsWith('root/')) {
        state = state.copyWith(
          sessions: applyRootNotification(
            state.sessions,
            method,
            message['params']! as JsonMap,
          ),
        );
        titles.add(
          state.sessions['pi:/00000000-0000-4000-8000-000000000002']?.title ??
              '<removed>',
        );
      }
    }
    expect(state.protocolVersion, '1.0.0');
    expect(state.root!.agents.single.provider, 'pi');
    expect(state.serverSeq, 7);
    expect(titles, ['New session', 'Renamed example session', '<removed>']);
    expect(state.sessions.length, 3);
    expect(
      state
          .sessions['pi:/01a103b9-71fd-7635-9643-fe041f005c2c']!
          .status
          .isReadFlag,
      isTrue,
    );
  });
}
