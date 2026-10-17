/// `/` completions in the composer and the follow-up box (AV-044): the
/// pure helpers, the popup's keys, mouse and semantics, and the host's
/// `completions` from a session.
library;

import 'dart:ui' show SemanticsRole;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/composer/completions.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _commands = [
  (name: 'review', description: 'Review the changes', skillUri: null),
  (name: 'explain', description: 'Explain the code', skillUri: null),
  (name: 'refactor', description: null, skillUri: null),
];

const _skill = DirectoryCustomization(
  id: 'skills',
  uri: 'file:///w/.agents/skills',
  name: 'Skills',
  enabled: true,
  contents: ChildCustomizationType.skill,
  writable: false,
  children: [
    SkillCustomization(
      id: 'review',
      uri: 'file:///w/.agents/skills/review/SKILL.md',
      name: 'review',
      description: 'Review the changes',
    ),
  ],
);

CompletionItem _hostItem(String name, {int start = 0, int end = 2}) =>
    CompletionItem(
      insertText: '/skill:$name ',
      rangeStart: start,
      rangeEnd: end,
      attachment: SimpleMessageAttachment(
        label: '/skill:$name',
        meta: {'uri': 'file:///$name', 'description': 'Does $name'},
      ),
    );

TextEditingValue _at(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

/// The messages a [FollowUpInput] sent.
typedef _Sent = ({
  String text,
  bool steer,
  List<MessageAttachment> attachments,
});

Future<List<_Sent>> _pumpInput(
  WidgetTester tester, {
  bool working = false,
  List<String> triggers = const ['/'],
  Future<List<ComposerCompletion>> Function(String, CompletionToken)? source,
}) async {
  final sent = <_Sent>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FollowUpInput(
            working: working,
            completionTriggers: triggers,
            completionSource:
                source ??
                (text, token) async => resolveCompletions(
                  text: text,
                  token: token,
                  commands: _commands,
                ),
            onSend: (text, {required steer, model, attachments = const []}) =>
                sent.add((text: text, steer: steer, attachments: attachments)),
          ),
        ),
      ),
    ),
  );
  return sent;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

Finder get _popup => find.byKey(const ValueKey('completions'));

void main() {
  group('helpers', () {
    test('commandCompletions replace the / word and are filtered', () {
      final token = completionToken('see /re', 7, ['/'])!;
      final items = filterCompletions(
        commandCompletions(_commands, token),
        token.query,
      );
      expect([for (final i in items) i.label], ['/review', '/refactor']);
      expect(applyCompletion(_at('see /re'), items.first), _at('see /review '));
    });

    test('a skill command carries a skill reference', () {
      final [skill, prompt] = commandCompletions(
        slashCommands(const [
          _skill,
          DirectoryCustomization(
            id: 'prompts',
            uri: 'file:///w/.agents/prompts',
            name: 'Prompts',
            enabled: true,
            contents: ChildCustomizationType.prompt,
            writable: false,
            children: [
              PromptCustomization(
                id: 'fix',
                uri: 'file:///w/.agents/prompts/fix.md',
                name: 'fix',
              ),
            ],
          ),
        ]),
        completionToken('/', 1, ['/'])!,
      );
      final attachment = skill.attachment! as SimpleMessageAttachment;
      expect(attachment.label, '/review');
      expect(attachment.displayKind, 'skill');
      expect(attachment.meta, {
        'uri': 'file:///w/.agents/skills/review/SKILL.md',
        'name': 'review',
        'description': 'Review the changes',
      });
      expect(prompt.attachment, isNull);
    });

    test('draftCommands use the agent, else a session of the agent', () {
      SessionState session(String provider, String folder) => SessionState(
        provider: provider,
        title: 't',
        status: SessionStatus.idle,
        workingDirectories: [folder],
        lifecycle: SessionLifecycle.ready,
        activeClients: const [],
        chats: const [],
        customizations: [
          DirectoryCustomization(
            id: folder,
            uri: '$folder/.agents/skills',
            name: 'Skills',
            enabled: true,
            contents: ChildCustomizationType.skill,
            writable: false,
            children: [
              SkillCustomization(
                id: folder,
                uri: '$folder/SKILL.md',
                name: folder.split('/').last,
              ),
            ],
          ),
        ],
      );
      List<String> names(List<SlashCommand> commands) => [
        for (final c in commands) c.name,
      ];
      final sessions = [
        session('other', 'file:///w/x'),
        session('pi', 'file:///w/a'),
        session('pi', 'file:///w/b'),
      ];
      const pi = AgentInfo(
        provider: 'pi',
        displayName: 'Pi',
        description: '',
        models: [],
      );
      expect(names(draftCommands(agent: pi, sessions: sessions)), ['a']);
      expect(
        names(
          draftCommands(
            agent: pi,
            sessions: sessions,
            directory: 'file:///w/b/',
          ),
        ),
        ['b'],
      );
      expect(
        names(
          draftCommands(
            agent: const AgentInfo(
              provider: 'pi',
              displayName: 'Pi',
              description: '',
              models: [],
              customizations: [_skill],
            ),
            sessions: sessions,
          ),
        ),
        ['review'],
      );
      expect(draftCommands(agent: null, sessions: sessions), isEmpty);
    });

    test('filterCompletions puts prefix matches first, then fuzzy', () {
      final items = commandCompletions(
        _commands,
        completionToken('/', 1, ['/'])!,
      );
      expect(
        [for (final i in filterCompletions(items, 'e')) i.label],
        ['/explain', '/review', '/refactor'],
      );
      expect(
        [for (final i in filterCompletions(items, 'rvw')) i.label],
        ['/review'],
      );
      expect(filterCompletions(items, 'zz'), isEmpty);
    });

    test('applyCompletion uses the host range, moved by later typing', () {
      final item = hostCompletion(
        _hostItem('review', start: 4, end: 6),
        text: 'see /r',
      );
      expect(item.label, '/skill:review');
      expect(item.description, 'Does review');
      expect(applyCompletion(_at('see /r'), item), _at('see /skill:review '));
      // Two more characters typed before the item was accepted.
      expect(applyCompletion(_at('see /rev'), item), _at('see /skill:review '));
      // Mid-text: the host's range covers the rest of the word.
      final word = hostCompletion(
        _hostItem('review', start: 0, end: 4),
        text: '/rev now',
      );
      expect(
        applyCompletion(_at('/rev now', 2), word),
        _at('/skill:review  now', 14),
      );
    });

    test('applyCompletion without a range inserts at the cursor', () {
      const item = ComposerCompletion(label: '@a', insertText: '@a.txt');
      expect(applyCompletion(_at('see '), item), _at('see @a.txt'));
    });

    test('a description comes from the session commands when the host has '
        'none', () {
      final item = hostCompletion(
        const CompletionItem(
          insertText: '/review ',
          attachment: SimpleMessageAttachment(label: '/review'),
        ),
        text: '/',
        commands: _commands,
      );
      expect(item.description, 'Review the changes');
    });

    test('acceptedAttachments keeps those still in the text, once', () {
      final a = hostCompletion(_hostItem('a'), text: '/a');
      final b = hostCompletion(_hostItem('b'), text: '/b');
      expect(acceptedAttachments([a, b, a], 'use /skill:a then'), [
        a.attachment,
      ]);
    });

    test('completionTriggers prefer the host, else / for commands', () {
      expect(completionTriggers(['@', '/'], _commands), ['@', '/']);
      expect(completionTriggers(const [], _commands), ['/']);
      expect(completionTriggers(const [], const []), isEmpty);
    });

    test(
      'resolveCompletions falls back when the host lacks the command',
      () async {
        final token = completionToken('/ex', 3, ['/'])!;
        final fallback = await resolveCompletions(
          text: '/ex',
          token: token,
          commands: _commands,
          request: () async => throw RpcException.methodNotFound('completions'),
        );
        expect([for (final i in fallback) i.label], ['/explain']);
        final host = await resolveCompletions(
          text: '/ex',
          token: token,
          commands: _commands,
          request: () async => [_hostItem('example')],
        );
        expect([for (final i in host) i.label], ['/skill:example']);
        for (final request in <Future<List<CompletionItem>> Function()>[
          () async => throw RpcException(-32603, 'internal'),
          () async => const [],
        ]) {
          final items = await resolveCompletions(
            text: '/ex',
            token: token,
            commands: _commands,
            request: request,
          );
          expect([for (final i in items) i.label], ['/explain']);
        }
        expect(
          await resolveCompletions(
            text: '@x',
            token: completionToken('@x', 2, ['@'])!,
            commands: _commands,
          ),
          isEmpty,
        );
      },
    );
  });

  group('popup', () {
    testWidgets('/ opens the commands; typing filters; Enter accepts', (
      tester,
    ) async {
      final sent = await _pumpInput(tester);
      await _type(tester, '/');
      expect(_popup, findsOneWidget);
      expect(find.text('/review'), findsOneWidget);
      expect(find.text('Review the changes'), findsOneWidget);
      expect(find.text('/explain'), findsOneWidget);

      await _type(tester, '/ex');
      expect(find.text('/review'), findsNothing);
      expect(find.text('/explain'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '/explain ',
      );
      expect(_popup, findsNothing);

      // Closed again, Enter sends.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent.single.text, '/explain');
    });

    testWidgets('arrows and Tab pick an item; Esc closes until the word '
        'ends', (tester) async {
      await _pumpInput(tester);
      await _type(tester, 'please /re');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'please /refactor ');

      await _type(tester, '/');
      expect(_popup, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_popup, findsNothing);
      await _type(tester, '/r');
      expect(_popup, findsNothing);
      await _type(tester, '/r /');
      expect(_popup, findsOneWidget);
    });

    testWidgets('a tap accepts an item', (tester) async {
      await _pumpInput(tester);
      await _type(tester, '/');
      await tester.tap(find.text('/review'));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '/review ');
      expect(_popup, findsNothing);
    });

    testWidgets('a / inside a word does not open it; Cmd/Ctrl+Enter steers '
        'with the popup closed', (tester) async {
      final sent = await _pumpInput(tester, working: true);
      await _type(tester, 'src/re');
      expect(_popup, findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      expect(sent.single.steer, isTrue);
    });

    testWidgets('answers for older text are dropped', (tester) async {
      final requests = <String>[];
      await _pumpInput(
        tester,
        source: (text, token) async {
          requests.add(text);
          await Future<void>.delayed(
            Duration(milliseconds: text == '/r' ? 500 : 10),
          );
          return [
            ComposerCompletion(
              label: text == '/r' ? '/stale' : '/fresh',
              insertText: '/x ',
              rangeStart: 0,
            ),
          ];
        },
      );
      await _type(tester, '/r');
      await _type(tester, '/re');
      await tester.pump(const Duration(milliseconds: 600));
      expect(requests, ['/r', '/re']);
      expect(find.text('/fresh'), findsOneWidget);
      expect(find.text('/stale'), findsNothing);
    });

    testWidgets('typing quickly sends one request', (tester) async {
      final requests = <String>[];
      await _pumpInput(
        tester,
        source: (text, token) async {
          requests.add(text);
          return const [];
        },
      );
      await tester.enterText(find.byType(TextField), '/r');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), '/re');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), '/rev');
      await tester.pump(const Duration(milliseconds: 200));
      expect(requests, ['/rev']);
    });

    testWidgets('the items are a list with a count', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpInput(tester);
      await _type(tester, '/');
      expect(find.bySemanticsLabel('3 completions'), findsOneWidget);
      final list = tester.getSemantics(find.bySemanticsLabel('3 completions'));
      expect(list.getSemanticsData().role, SemanticsRole.list);
      semantics.dispose();
    });
  });

  group('in a session', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<FakeHostConnection> pumpSession(
      WidgetTester tester, {
      List<String> triggers = const [],
    }) async {
      reduceMotion(tester);
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final connection = FakeHostConnection(
        HostState(
          status: ConnectionStatus.connected,
          serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
          completionTriggerCharacters: triggers,
          sessions: catalogueFromSummaries([
            session('1', directory: 'file:///src/app', title: 'Fix login'),
          ]),
          chatChannels: {
            'ahp-chat:/1': ChannelMirror.snapshot(chatFixture(active: false)),
          },
          sessionChannels: {
            'pi:/1': ChannelMirror.snapshot(
              sessionWithRequests().copyWith(customizations: const [_skill]),
            ),
          },
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: hostOverrides(connection: connection),
          child: const ShireitouApp(),
        ),
      );
      await tester.tap(find.text('Fix login'));
      await tester.pumpAndSettle();
      return connection;
    }

    testWidgets('asks the host and sends the accepted attachment', (
      tester,
    ) async {
      final connection = await pumpSession(tester, triggers: ['/']);
      connection.completionItems = [_hostItem('review', end: 2)];
      await tester.enterText(find.byType(TextField).last, '/r');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(connection.completionRequests.single, ('ahp-chat:/1', '/r', 2));
      expect(find.text('/skill:review'), findsOneWidget);
      expect(find.text('Does review'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final (_, action) = connection.dispatched.last;
      expect(action['type'], 'chat/turnStarted');
      final message = action['message']! as JsonMap;
      expect(message['text'], '/skill:review');
      expect(message['attachments'], [
        {
          'type': 'simple',
          'label': '/skill:review',
          '_meta': {'uri': 'file:///review', 'description': 'Does review'},
        },
      ]);
    });

    testWidgets('without host completions, offers the session skills', (
      tester,
    ) async {
      final connection = await pumpSession(tester);
      await tester.enterText(find.byType(TextField).last, '/');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(connection.completionRequests, isEmpty);
      expect(find.text('/review'), findsOneWidget);
      expect(find.text('Review the changes'), findsOneWidget);
    });
  });

  testWidgets('the new-session composer offers the agent\'s skills', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final connection = FakeHostConnection(
      HostState(
        status: ConnectionStatus.connected,
        serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
        defaultDirectory: 'file:///src/app',
        root: const RootState(
          agents: [
            AgentInfo(
              provider: 'pi',
              displayName: 'Pi',
              description: 'pi',
              models: [],
              customizations: [_skill],
            ),
          ],
        ),
        sessions: catalogueFromSummaries([
          session('1', directory: 'file:///src/app', title: 'Fix login'),
        ]),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: hostOverrides(connection: connection),
        child: const ShireitouApp(),
      ),
    );
    await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
    await tester.pumpAndSettle();
    final prompt = composerField;
    await tester.enterText(prompt, 'Please /rev');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('/review'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(connection.started, isEmpty);
    expect(
      tester.widget<TextField>(prompt).controller!.text,
      'Please /review ',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(connection.started.single.prompt, 'Please /review');
  });
}
