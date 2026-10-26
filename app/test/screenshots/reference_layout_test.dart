/// Renders the sessions screen as PNGs to compare with the reference UI
/// (design/reference/agents-window.png, AV-090 to AV-096). Not part of
/// `just test`: run `just screenshots`, which writes
/// `app/build/screenshots/*.png`. Real fonts are loaded from macOS
/// (/System/Library/Fonts) and the Flutter SDK, because widget tests
/// draw text with a box font by default; elsewhere the test is skipped.
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Brightness, Offset;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/theme/appearance.dart';
import 'package:shireitou/src/theme/themes.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';

import '../fake_connection.dart';
import 'screenshot_harness.dart';

/// Where the PNGs go (git-ignored).
final _out = Directory('build/screenshots');

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
  createdAt: timeAgo(ago),
  modifiedAt: timeAgo(ago),
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
  modifiedAt: timeAgo(const Duration(hours: 14)),
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
/// the reference session. [prefs] are added to the stored settings (such
/// as a colour theme, AV-097).
Future<void> _pump(
  WidgetTester tester, {
  required Screen screen,
  required Brightness brightness,
  bool open = true,
  Map<String, String> prefs = const {},
}) => pumpApp(
  tester,
  host: _host,
  screen: screen,
  brightness: brightness,
  prefs: {'pinned_sessions': encodePinned(_pins), ...prefs},
  open: open ? 'can you audit my PI history' : null,
);

Future<void> _capture(WidgetTester tester, String name) =>
    capture(tester, _out, name);

void main() {
  final skip = screenshotSkip;

  setUpAll(loadScreenshotFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('dark, desktop', skip: skip, variant: macOS, (tester) async {
    await _pump(tester, screen: desktop, brightness: Brightness.dark);
    await _capture(tester, 'dark');
  });

  testWidgets('light, desktop', skip: skip, variant: macOS, (tester) async {
    await _pump(tester, screen: desktop, brightness: Brightness.light);
    await _capture(tester, 'light');
  });

  testWidgets('dark, phone', skip: skip, variant: iOS, (tester) async {
    await _pump(tester, screen: phone, brightness: Brightness.dark);
    await _capture(tester, 'compact');
  });

  testWidgets('dark, phone, the session list', skip: skip, variant: iOS, (
    tester,
  ) async {
    await _pump(
      tester,
      screen: phone,
      brightness: Brightness.dark,
      open: false,
    );
    await _capture(tester, 'compact-list');
  });

  testWidgets('dark, desktop, a row hovered', skip: skip, variant: macOS, (
    tester,
  ) async {
    await _pump(tester, screen: desktop, brightness: Brightness.dark);
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

  // A sample of the colour themes (AV-097), as theme-<id>.png.
  for (final theme in [
    'dracula',
    'tokyo-night',
    'gruvbox-dark',
    'nord',
    'solarized-light',
    'catppuccin-latte',
  ]) {
    testWidgets('$theme, desktop', skip: skip, variant: macOS, (tester) async {
      final light = themeById(theme, Brightness.light).id == theme;
      await _pump(
        tester,
        screen: desktop,
        brightness: light ? Brightness.light : Brightness.dark,
        prefs: {light ? lightThemeKey : darkThemeKey: theme},
      );
      await _capture(tester, 'theme-$theme');
    });
  }

  testWidgets('the Appearance menu', skip: skip, variant: macOS, (
    tester,
  ) async {
    await _pump(tester, screen: desktop, brightness: Brightness.dark);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark theme · Graphite'));
    await tester.pumpAndSettle();
    await _capture(tester, 'appearance-menu');
  });
}
