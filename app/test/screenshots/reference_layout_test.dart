/// Renders the sessions screen as PNGs to compare with the reference UI
/// (design/reference/agents-window.png, AV-090 to AV-096). Not part of
/// `just test`: run `just screenshots`, which writes
/// `app/build/screenshots/*.png`. Real fonts are loaded from macOS
/// (/System/Library/Fonts) and the Flutter SDK, because widget tests
/// draw text with a box font by default; elsewhere the test is skipped.
@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';

import '../fake_connection.dart';
import '../fixtures.dart';

/// The reference screenshot's size: 3562×2224 pixels at 2× is 1781×1112
/// points, drawn at 120% zoom (its 13 px text measures 15.6 points), so
/// the app is rendered at 1484×927 logical pixels with a 1.2 pixel
/// ratio. The PNG is then half the reference's size, pixel for pixel.
const _desktop = (size: Size(1781, 1112), pixelRatio: 1.2);

/// A phone in portrait.
const _phone = (size: Size(390, 844), pixelRatio: 1.0);

const _systemFonts = '/System/Library/Fonts';

/// Where the PNGs go (git-ignored).
final _out = Directory('build/screenshots');

/// Loads [path] as the font [families], so text renders with real glyphs.
Future<void> _loadFont(String path, List<String> families) async {
  final bytes = File(path).readAsBytesSync();
  for (final family in families) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Loads the system text and monospace fonts under the names the theme
/// asks for, and the Material icons from the Flutter SDK.
Future<void> _loadFonts() async {
  await _loadFont('$_systemFonts/SFNS.ttf', [
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.AppleSystemUIFont',
    'Roboto',
  ]);
  await _loadFont('$_systemFonts/SFNSMono.ttf', ['monospace', 'Menlo']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await _loadFont(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ['MaterialIcons'],
  );
}

String _ago(Duration elapsed) =>
    DateTime.now().toUtc().subtract(elapsed).toIso8601String();

const _home = 'file:///home/yusuke.tsutsumi/git';

SessionSummary _row(
  String id,
  String title, {
  String? folder,
  Duration ago = const Duration(hours: 1),
  int status = 33,
}) => SessionSummary(
  resource: 'pi:/$id',
  provider: 'pi',
  title: title,
  status: SessionStatus(status),
  createdAt: _ago(ago),
  modifiedAt: _ago(ago),
  workingDirectories: folder == null ? null : ['$_home/$folder'],
  project: folder == null
      ? null
      : const ProjectInfo(uri: '$_home/cruise', displayName: 'cruise'),
);

/// The sidebar of the reference: three pinned sessions, chats with no
/// working directory, and two workspaces.
final _sessions = [
  _row(
    'p1',
    '/skill:yft-branch-reset please do an analysis of how many sim runs '
        'we have left',
    folder: 'cruise',
    ago: const Duration(hours: 10),
  ),
  _row(
    'p2',
    'can you audit the olympus models and find the following:',
    folder: 'cruise',
    ago: const Duration(days: 1),
  ),
  _row(
    'open',
    'can you audit my PI history and tell me what categories of commands '
        'took the longest?',
    folder: 'cruise',
    ago: const Duration(hours: 14),
  ),
  _row(
    'w1',
    'can you make a table of the major models within olympus, their '
        'respective owners',
    folder: 'cruise',
    ago: const Duration(days: 1),
  ),
  _row(
    'w2',
    'implement SC3 protocol gating',
    folder: 'cruise-4',
    ago: const Duration(hours: 12),
    status: 1,
  ),
  _row(
    'w3',
    'can you do an analysis of runtime latency across the following '
        'environments:',
    folder: 'cruise-4',
    ago: const Duration(days: 1),
  ),
  _row('c1', 'Hydra Quota', ago: const Duration(minutes: 41), status: 24),
  _row('c2', 'bwd-on-avml-2', ago: const Duration(days: 2)),
  _row(
    'c3',
    '<skill name="yft-performance-peer-review" location="/home/yusuke.ts',
    ago: const Duration(days: 8),
  ),
];

final _pins = {
  for (final id in ['p1', 'p2', 'open'])
    (host: testHost.key, session: 'pi:/$id'),
};

const _opusId = 'anthropic/claude-opus-5-5';

const _root = RootState(
  agents: [
    AgentInfo(
      provider: 'pi',
      displayName: 'Pi',
      description: 'pi',
      models: [
        SessionModelInfo(
          id: _opusId,
          provider: 'pi',
          name: 'Claude Opus 5.5',
          maxContextWindow: 1000000,
          configSchema: ConfigSchema(
            properties: {
              'thinkingLevel': ConfigPropertySchema(
                type: ConfigPropertySchemaType.string,
                title: 'Thinking',
                defaultValue: 'medium',
                enumValues: ['low', 'medium', 'high'],
                enumLabels: ['Low', 'Medium', 'High'],
              ),
              'lane': ConfigPropertySchema(
                type: ConfigPropertySchemaType.string,
                title: 'Lane',
                defaultValue: 'impl',
                enumValues: ['impl', 'review'],
                enumLabels: ['implementation lane', 'review lane'],
              ),
            },
          ),
        ),
      ],
    ),
  ],
);

const _sessionState = SessionState(
  provider: 'pi',
  title: 'can you audit my PI history',
  status: SessionStatus.idle,
  lifecycle: SessionLifecycle.ready,
  activeClients: [],
  defaultChat: 'ahp-chat:/1',
  chats: [],
  config: SessionConfigState(
    schema: SessionConfigSchema(
      properties: {
        'mode': SessionConfigPropertySchema(
          type: SessionConfigPropertySchemaType.string,
          title: 'Mode',
          defaultValue: 'agent',
          enumValues: ['agent', 'plan'],
          enumLabels: ['Agent', 'Plan'],
          sessionMutable: true,
        ),
      },
    ),
    values: {'mode': 'agent'},
  ),
);

const _reply = '''
I went through all 145 pi sessions under `~/.av-pi/agent/sessions`: 7,765 tool calls and 7,955 LLM turns. Tool calls add up to about **65 hours** and model generation to about **25 hours**.

The main finding is that 107 calls longer than 5 minutes (1.4% of all calls) account for **76% of tool time**. The 6,900 calls that finished in under 10 seconds add up to only 1.2 hours.

## Time by category

| Category | Calls | Hours | % | p50 | p90 |
| --- | --- | --- | --- | --- | --- |
| **Waiting on sims** (`sim run`) | 70 | 16.0 | 25% | 4 min | 47 min |
| **Polling GitHub Actions CI** (`until gh run list …`) | 10 | 13.3 | 21% | 10 min | 10.7 h |
| `bazel test` | 260 | 8.8 | 14% | 71 s | 5 min |
| Code search (rg/grep/find) | 3,084 | 4.6 | 7% | 0 s | 2 s |
| git, local commands | 835 | 2.5 | 4% | 0.3 s | 9 s |
| `bazel run` | 89 | 2.0 | 3% | 13 s | 2.6 min |
| git fetch/push, `gt sync` | 161 | 1.7 | 3% | 13 s | 91 s |
| `make fix` / `make lint`, bazel build/query, python, gh, curl, MCP, read/edit | — | ~4 | ~6% | small | small |

LLM turns had a median of 5.4 s and a mean of 11 s. Opus used 20 of the 25 hours. The average context was large: about 250k tokens for Opus and 480k for Gemini Flash. Once context passed 200k, mean latency rose from about 7 s to 12–19 s.
''';

ToolCallResponsePart _tool(int i) => ToolCallResponsePart(
  toolCall: ToolCallCompletedState(
    toolCallId: 'call-$i',
    toolName: i.isEven ? 'bash' : 'read',
    displayName: i.isEven ? 'Bash' : 'Read',
    invocationMessage: PlainString(i.isEven ? 'Running `jq`' : 'Reading'),
    pastTenseMessage: PlainString(
      i.isEven ? 'Ran `jq .tool session-$i.jsonl`' : 'Read session-$i.jsonl',
    ),
    toolInput: const InlineToolInput('{}'),
    confirmed: ToolCallConfirmationReason.notNeeded,
    success: true,
  ),
);

/// A short turn before the reference's, so the timeline scrolls.
Turn _earlierTurn(String id) => Turn(
  id: id,
  message: userMessage('where are the pi session logs kept?'),
  state: TurnState.complete,
  duration: 9000,
  responseParts: [
    _tool(0),
    MarkdownResponsePart(
      id: '$id-reply',
      content:
          'In `~/.av-pi/agent/sessions`, one JSONL file per session. '
          'Each line is an event: a message, a tool call or a result, '
          'with timestamps, so durations can be read from them.',
    ),
  ],
);

final _chat = ChatState(
  resource: 'ahp-chat:/1',
  title: 'can you audit my PI history',
  status: const SessionStatus(33),
  modifiedAt: _ago(const Duration(hours: 14)),
  turns: [
    for (final id in ['turn-a', 'turn-b']) _earlierTurn(id),
    Turn(
      id: 'turn-1',
      message: userMessage(
        'can you audit my PI history and tell me what categories of '
        "commands took the longest? I'm trying to debug why my agents take "
        'so long.',
        model: const ModelSelection(id: _opusId),
      ),
      state: TurnState.complete,
      duration: 107000,
      responseParts: [
        for (var i = 0; i < 25; i++) _tool(i),
        const MarkdownResponsePart(id: 'reply', content: _reply),
      ],
    ),
  ],
);

HostState get _host => HostState(
  status: ConnectionStatus.connected,
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  defaultDirectory: '$_home/cruise',
  root: _root,
  sessions: catalogueFromSummaries(_sessions),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(_chat)},
  sessionChannels: {'pi:/open': ChannelMirror.snapshot(_sessionState)},
);

/// Pumps the app on [screen] in [brightness] and, when [open], opens
/// the reference session.
Future<void> _pump(
  WidgetTester tester, {
  required ({Size size, double pixelRatio}) screen,
  required Brightness brightness,
  bool open = true,
}) async {
  tester.view.physicalSize = screen.size;
  tester.view.devicePixelRatio = screen.pixelRatio;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  reduceMotion(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: FakeHostConnection(_host)),
        prefsStoreProvider.overrideWithValue(
          MemoryPrefsStore({'pinned_sessions': encodePinned(_pins)}),
        ),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (!open) return;
  await tester.tap(find.textContaining('can you audit my PI history').first);
  await tester.pumpAndSettle();
}

/// Writes the screen to `build/screenshots/[name].png`.
Future<void> _capture(WidgetTester tester, String name) async {
  final element = tester.element(find.byType(ShireitouApp));
  await tester.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

final _macOS = TargetPlatformVariant.only(TargetPlatform.macOS);
final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  // Elsewhere the text would be boxes.
  final skip = !Directory(_systemFonts).existsSync();

  setUpAll(() async {
    if (!skip) await _loadFonts();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('dark, desktop', skip: skip, variant: _macOS, (tester) async {
    await _pump(tester, screen: _desktop, brightness: Brightness.dark);
    await _capture(tester, 'dark');
  });

  testWidgets('light, desktop', skip: skip, variant: _macOS, (tester) async {
    await _pump(tester, screen: _desktop, brightness: Brightness.light);
    await _capture(tester, 'light');
  });

  testWidgets('dark, phone', skip: skip, variant: _iOS, (tester) async {
    await _pump(tester, screen: _phone, brightness: Brightness.dark);
    await _capture(tester, 'compact');
  });

  testWidgets('dark, phone, the session list', skip: skip, variant: _iOS, (
    tester,
  ) async {
    await _pump(
      tester,
      screen: _phone,
      brightness: Brightness.dark,
      open: false,
    );
    await _capture(tester, 'compact-list');
  });

  testWidgets('dark, desktop, a row hovered', skip: skip, variant: _macOS, (
    tester,
  ) async {
    await _pump(tester, screen: _desktop, brightness: Brightness.dark);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.text('implement SC3 protocol gating')),
    );
    // Long enough for the hover card.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await _capture(tester, 'dark-hover');

    // Scrolled up from the latest message, the jump button shows.
    await tester.drag(find.text('Time by category'), const Offset(0, 500));
    await tester.pumpAndSettle();
    await _capture(tester, 'dark-scrolled');
  });
}
