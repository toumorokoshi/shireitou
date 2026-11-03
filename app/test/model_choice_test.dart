/// Tests for the user's model choice (AV-041): defaulting to the last
/// selected model across sessions, and falling back to "Host default model"
/// when the model does not exist.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/composer_labels.dart';
import 'package:shireitou/src/composer/model_store.dart';
import 'package:shireitou/src/composer/new_session_view.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

import 'fake_connection.dart';

const _modelA = SessionModelInfo(
  id: 'model-a',
  provider: 'agent-1',
  name: 'Model A',
);

const _modelB = SessionModelInfo(
  id: 'model-b',
  provider: 'agent-1',
  name: 'Model B',
);

const _modelC = SessionModelInfo(
  id: 'model-c',
  provider: 'agent-2',
  name: 'Model C',
);

const _agent1 = AgentInfo(
  provider: 'agent-1',
  displayName: 'Agent 1',
  description: 'First agent',
  models: [_modelA, _modelB],
);

const _agent2 = AgentInfo(
  provider: 'agent-2',
  displayName: 'Agent 2',
  description: 'Second agent',
  models: [_modelC],
);

HostState _stateWithAgents() => const HostState(
  status: ConnectionStatus.connected,
  root: RootState(agents: [_agent1, _agent2]),
);

void main() {
  group('defaultModelChoice', () {
    test('returns null when no preferred model was selected', () {
      expect(defaultModelChoice([_modelA, _modelB], null), isNull);
    });

    test('returns preferred model when it exists in models', () {
      const preferred = ModelSelection(
        id: 'model-a',
        config: {'thinkingLevel': 'high'},
      );
      final chosen = defaultModelChoice([_modelA, _modelB], preferred);
      expect(chosen, equals(preferred));
    });

    test(
      'falls back to null ("Host default model") when model does not exist',
      () {
        const preferred = ModelSelection(id: 'nonexistent/model');
        expect(defaultModelChoice([_modelA, _modelB], preferred), isNull);
      },
    );

    test('returns null when model list is empty', () {
      const preferred = ModelSelection(id: 'model-a');
      expect(defaultModelChoice([], preferred), isNull);
    });
  });

  group('chatModelChoice', () {
    test('returns chat last model if it exists in models', () {
      final chat = ChatState(
        resource: 'chat:1',
        title: 'Chat',
        status: const SessionStatus(24),
        modifiedAt: '2026-10-01T00:00:00Z',
        turns: [
          Turn(
            id: 't1',
            startedAt: '2026-10-01T00:00:00Z',
            state: TurnState.complete,
            responseParts: const [],
            message: userMessage(
              'hello',
              model: const ModelSelection(id: 'model-a'),
            ),
          ),
        ],
      );
      final chosen = chatModelChoice(
        chat: chat,
        models: [_modelA, _modelB],
        preferred: const ModelSelection(id: 'model-b'),
      );
      expect(chosen?.id, 'model-a');
    });

    test(
      'falls back to null when chat last model does not exist in models',
      () {
        final chat = ChatState(
          resource: 'chat:1',
          title: 'Chat',
          status: const SessionStatus(24),
          modifiedAt: '2026-10-01T00:00:00Z',
          turns: [
            Turn(
              id: 't1',
              startedAt: '2026-10-01T00:00:00Z',
              state: TurnState.complete,
              responseParts: const [],
              message: userMessage(
                'hello',
                model: const ModelSelection(id: 'deleted/model'),
              ),
            ),
          ],
        );
        final chosen = chatModelChoice(
          chat: chat,
          models: [_modelA, _modelB],
          preferred: const ModelSelection(id: 'model-a'),
        );
        expect(chosen, isNull);
      },
    );

    test('uses preferred model when chat has no model specified and preferred exists', () {
      final chat = ChatState(
        resource: 'chat:1',
        title: 'Chat',
        status: const SessionStatus(24),
        modifiedAt: '2026-10-01T00:00:00Z',
        turns: [
          Turn(
            id: 't1',
            startedAt: '2026-10-01T00:00:00Z',
            state: TurnState.complete,
            responseParts: const [],
            message: userMessage('hello'),
          ),
        ],
      );
      final chosen = chatModelChoice(
        chat: chat,
        models: [_modelA, _modelB],
        preferred: const ModelSelection(id: 'model-b'),
      );
      expect(chosen?.id, 'model-b');
    });

    test(
      'falls back to null when chat has no model and preferred does not exist',
      () {
        final chat = ChatState(
          resource: 'chat:1',
          title: 'Chat',
          status: const SessionStatus(24),
          modifiedAt: '2026-10-01T00:00:00Z',
          turns: [],
        );
        final chosen = chatModelChoice(
          chat: chat,
          models: [_modelA, _modelB],
          preferred: const ModelSelection(id: 'model-c'),
        );
        expect(chosen, isNull);
      },
    );
  });

  group('encodeModelSelection and decodeModelSelection', () {
    test('roundtrips model with config', () {
      const model = ModelSelection(
        id: 'model-a',
        config: {'thinkingLevel': 'high', 'count': 42},
      );
      final encoded = encodeModelSelection(model);
      expect(encoded, isNotNull);
      final decoded = decodeModelSelection(encoded);
      expect(decoded, equals(model));
    });

    test('roundtrips model without config', () {
      const model = ModelSelection(id: 'model-b');
      final encoded = encodeModelSelection(model);
      expect(encoded, isNotNull);
      final decoded = decodeModelSelection(encoded);
      expect(decoded, equals(model));
    });

    test('decodes plain string id', () {
      final decoded = decodeModelSelection('plain-model-id');
      expect(decoded?.id, 'plain-model-id');
      expect(decoded?.config, isNull);
    });

    test('decodes null or empty as null', () {
      expect(decodeModelSelection(null), isNull);
      expect(decodeModelSelection(''), isNull);
      expect(decodeModelSelection('   '), isNull);
    });
  });

  group('StoredModelSelection', () {
    test('loads from PrefsStore and saves updates', () async {
      final prefs = MemoryPrefsStore({
        StoredModelSelection.key: '{"id":"model-a"}',
      });
      final container = ProviderContainer(
        overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Trigger lazy provider build, then await load.
      container.read(lastSelectedModelProvider);
      await pumpEventQueue();
      expect(
        container.read(lastSelectedModelProvider),
        equals(const ModelSelection(id: 'model-a')),
      );

      await container
          .read(lastSelectedModelProvider.notifier)
          .set(const ModelSelection(id: 'model-b'));
      expect(
        container.read(lastSelectedModelProvider),
        equals(const ModelSelection(id: 'model-b')),
      );
      expect(prefs.values[StoredModelSelection.key], contains('model-b'));

      await container.read(lastSelectedModelProvider.notifier).set(null);
      expect(container.read(lastSelectedModelProvider), isNull);
      expect(prefs.values[StoredModelSelection.key], '');
    });
  });

  group('NewSessionView model choice default', () {
    testWidgets(
      'uses last selected model by default when it exists in agent models',
      (tester) async {
        final prefs = MemoryPrefsStore({
          StoredModelSelection.key: '{"id":"model-b"}',
        });
        final connection = FakeHostConnection(_stateWithAgents());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...hostOverrides(connection: connection),
              prefsStoreProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NewSessionView(
                  target: (host: testHost.url, directory: null),
                  onStarting: (_, _, _) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Model B'), findsOneWidget);
        expect(find.text(hostDefaultModelLabel), findsNothing);
      },
    );

    testWidgets(
      'falls back to "Host default model" when previous model does not exist',
      (tester) async {
        final prefs = MemoryPrefsStore({
          StoredModelSelection.key: '{"id":"model-c"}',
        });
        final connection = FakeHostConnection(_stateWithAgents());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...hostOverrides(connection: connection),
              prefsStoreProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: NewSessionView(
                  target: (host: testHost.url, directory: null),
                  onStarting: (_, _, _) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(hostDefaultModelLabel), findsOneWidget);
      },
    );

    testWidgets('switching agent restores preferred model when available', (
      tester,
    ) async {
      final prefs = MemoryPrefsStore({
        StoredModelSelection.key: '{"id":"model-c"}',
      });
      final connection = FakeHostConnection(_stateWithAgents());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...hostOverrides(connection: connection),
            prefsStoreProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NewSessionView(
                target: (host: testHost.url, directory: null),
                onStarting: (_, _, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hostDefaultModelLabel), findsOneWidget);

      await tester.tap(find.text('Agent 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agent 2').last);
      await tester.pumpAndSettle();

      expect(find.text('Model C'), findsOneWidget);
      expect(find.text(hostDefaultModelLabel), findsNothing);
    });

    testWidgets('picking a model saves it to prefs', (tester) async {
      final prefs = MemoryPrefsStore();
      final connection = FakeHostConnection(_stateWithAgents());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...hostOverrides(connection: connection),
            prefsStoreProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NewSessionView(
                target: (host: testHost.url, directory: null),
                onStarting: (_, _, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hostDefaultModelLabel), findsOneWidget);

      await tester.tap(find.text(hostDefaultModelLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Model A').last);
      await tester.pumpAndSettle();

      expect(find.text('Model A'), findsOneWidget);
      expect(prefs.values[StoredModelSelection.key], contains('model-a'));
    });
  });

  group('FollowUpInput model validation', () {
    testWidgets('drops invalid initialModel to Host default model', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpInput(
              working: false,
              models: const [_modelA],
              initialModel: const ModelSelection(id: 'nonexistent/model'),
              onSend: (_, {required sendNow, model, attachments = const []}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hostDefaultModelLabel), findsOneWidget);
    });
  });
}
