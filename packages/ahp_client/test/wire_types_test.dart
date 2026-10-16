import 'dart:convert';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

/// Every recorded message, from both example files.
List<JsonMap> _messages() => [
  for (final name in ['pi-host-root-catalogue.json', 'pi-host-chat-turns.json'])
    for (final entry in jsonDecode(
      File('../../examples/ahp/$name').readAsStringSync(),
    ) as List<Object?>)
      (entry! as JsonMap)['message']! as JsonMap,
];

/// [json] without what pi-agent-host-protocol 0.3.0 sends beyond the
/// 1.0.0 schema: `modifiedAt` in `SessionSummary.chats` entries.
Object? _withoutPiExtras(Object? json) => switch (json) {
  {'chats': final List<Object?> chats} && final JsonMap map
      when map.containsKey('createdAt') =>
    {
      for (final MapEntry(:key, :value) in map.entries)
        key: key == 'chats'
            ? [
                for (final chat in chats)
                  {...chat! as JsonMap}..remove('modifiedAt'),
              ]
            : _withoutPiExtras(value),
    },
  final JsonMap map => {
    for (final MapEntry(:key, :value) in map.entries)
      key: _withoutPiExtras(value),
  },
  final List<Object?> list => [for (final e in list) _withoutPiExtras(e)],
  _ => json,
};

/// Decodes [json] with [decode] and checks that encoding gives it back.
void _roundTrips(JsonMap json, JsonMap Function(JsonMap json) decode) {
  expect(decode(json), _withoutPiExtras(json), reason: jsonEncode(json));
}

void main() {
  final messages = _messages();
  final actions = [
    for (final m in messages)
      if (m['method'] == 'action')
        ((m['params']! as JsonMap)['action']! as JsonMap),
    for (final m in messages)
      if (m['method'] == 'dispatchAction')
        ((m['params']! as JsonMap)['action']! as JsonMap),
  ];

  test('the generated types match the schema version', () {
    expect(wireProtocolVersion, targetProtocolVersion);
  });

  test('recorded actions decode to known types and round-trip', () {
    expect(actions, isNotEmpty);
    for (final action in actions) {
      final decoded = StateAction.fromJson(action);
      expect(decoded, isNot(isA<StateActionUnknown>()), reason: '$action');
      _roundTrips(action, (json) => StateAction.fromJson(json).toJson());
    }
  });

  test('channel unions agree with StateAction', () {
    for (final action in actions) {
      final type = action['type']! as String;
      final decoded = StateAction.fromJson(action);
      if (type.startsWith('chat/')) {
        expect(ChatAction.fromJson(action), decoded);
        expect(decoded, isA<ChatAction>());
      } else if (type.startsWith('session/')) {
        expect(SessionAction.fromJson(action), decoded);
      } else if (type.startsWith('root/')) {
        expect(RootAction.fromJson(action), decoded);
      }
    }
  });

  test('recorded snapshots and results round-trip', () {
    var snapshots = 0;
    for (final m in messages) {
      final result = m['result'];
      if (result is! JsonMap) continue;
      if (result.containsKey('protocolVersion')) {
        _roundTrips(result, (j) => InitializeResult.fromJson(j).toJson());
      } else if (result['items'] is List) {
        _roundTrips(result, (j) => ListSessionsResult.fromJson(j).toJson());
      } else if (result['snapshot'] case final JsonMap snapshot) {
        final state = snapshot['state']! as JsonMap;
        if (state.containsKey('turns')) {
          _roundTrips(state, (json) => ChatState.fromJson(json).toJson());
        } else {
          _roundTrips(state, (json) => SessionState.fromJson(json).toJson());
        }
        snapshots++;
      }
    }
    expect(snapshots, greaterThan(0));
  });

  test('catalogue notifications decode to their params types', () {
    for (final m in messages) {
      final params = m['params'];
      if (params is! JsonMap) continue;
      switch (m['method']) {
        case 'root/sessionAdded':
          _roundTrips(params, (j) => SessionAddedParams.fromJson(j).toJson());
        case 'root/sessionRemoved':
          _roundTrips(params, (j) => SessionRemovedParams.fromJson(j).toJson());
        case 'root/sessionSummaryChanged':
          _roundTrips(
            params,
            (j) => SessionSummaryChangedParams.fromJson(j).toJson(),
          );
      }
    }
  });

  group('forward compatibility', () {
    test('unknown union members keep their JSON', () {
      const json = {'type': 'chat/somethingNew', 'x': 1};
      final action = ChatAction.fromJson(json);
      expect(action, isA<ChatActionUnknown>());
      expect(action.type, 'chat/somethingNew');
      expect(action.toJson(), json);
    });

    test('unknown tool call states keep the shared fields', () {
      final call = ToolCallState.fromJson(const {
        'status': 'paused',
        'toolCallId': 't',
        'toolName': 'bash',
        'displayName': 'Bash',
      });
      expect(call, isA<ToolCallStateUnknown>());
      expect(call.toolCallId, 't');
      expect(call.isBlocking, isFalse);
    });

    test('unknown enum values decode to \$unknown', () {
      expect(TurnState.fromJson('paused'), TurnState.$unknown);
      expect(TurnState.fromJson('error'), TurnState.error);
    });

    test('required lists may be left out', () {
      final root = RootState.fromJson(const {});
      expect(root.agents, isEmpty);
    });
  });

  group('generated API', () {
    const message = Message(
      text: 'hi',
      origin: MessageOrigin(kind: MessageKind.user),
    );

    test('copyWith replaces, keeps and clears fields', () {
      const turn = ActiveTurn(
        id: 't',
        startedAt: 's',
        message: message,
        responseParts: [],
        usage: UsageInfo(outputTokens: 1),
      );
      expect(turn.copyWith(id: 'u').id, 'u');
      expect(turn.copyWith(id: 'u').usage, turn.usage);
      expect(turn.copyWith(usage: null).usage, isNull);
      expect(turn.copyWith().usage, turn.usage);
    });

    test('value equality is deep', () {
      expect(
        ChatDeltaAction.fromJson(const {
          'type': 'chat/delta',
          'turnId': 't',
          'partId': 'p',
          'content': 'c',
          '_meta': {
            'a': [1],
          },
        }),
        const ChatDeltaAction(
          turnId: 't',
          partId: 'p',
          content: 'c',
          meta: {
            'a': [1],
          },
        ),
      );
    });

    test('toJson writes discriminators and leaves out nulls', () {
      expect(
        const ChatToolCallDeniedAction(
          turnId: 't',
          toolCallId: 'x',
          reason: ToolCallCancellationReason.denied,
        ).toJson(),
        {
          'type': 'chat/toolCallConfirmed',
          'approved': false,
          'turnId': 't',
          'toolCallId': 'x',
          'reason': 'denied',
        },
      );
    });

    test('untagged unions decode by JSON type', () {
      expect(StringOrMarkdown.fromJson('a'), const PlainString('a'));
      expect(StringOrMarkdown.fromJson(const {'markdown': '*a*'}).text, '*a*');
      expect(ToolInput.fromJson('{}'), const InlineToolInput('{}'));
      expect(
        ToolInput.fromJson(const {'uri': 'file:///x'}),
        const ContentRef(uri: 'file:///x'),
      );
    });
  });
}
