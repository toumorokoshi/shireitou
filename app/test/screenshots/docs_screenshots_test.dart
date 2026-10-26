/// Renders the screenshots in the README and docs from made-up sessions
/// (a "weather-app" project, no real data). Not part of `just test`: run
/// `just docs-screenshots`, which writes `docs/images/*.png`. Needs the
/// macOS fonts, like `just screenshots` (docs/testing.md).
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';
import 'package:shireitou/src/theme/appearance.dart';

import '../fake_connection.dart';
import 'screenshot_harness.dart';

/// Committed, unlike `build/screenshots`.
final _out = Directory('../docs/images');

const _home = 'file:///home/dev/src';

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
);

const _forecast = 'Add a 7-day forecast view to the dashboard';
const _migration = 'Migrate the readings table to UTC timestamps';

final _sessions = [
  _row('forecast', _forecast, folder: 'weather-app', ago: Duration.zero),
  _row(
    'migrate',
    _migration,
    folder: 'weather-app',
    ago: const Duration(minutes: 3),
    status: 24,
  ),
  _row(
    'flaky',
    'Fix the flaky timezone test in station_test.dart',
    folder: 'weather-app',
    ago: const Duration(minutes: 20),
    status: 8,
  ),
  _row(
    'deps',
    'Bump chart and http to their latest versions',
    folder: 'weather-app',
    ago: const Duration(hours: 5),
  ),
  _row(
    'zsh',
    'Speed up zsh startup',
    folder: 'dotfiles',
    ago: const Duration(hours: 2),
    status: 1,
  ),
  _row(
    'nvim',
    'Port my vim config to lua',
    folder: 'dotfiles',
    ago: const Duration(days: 3),
  ),
  _row('regex', 'Explain this regex', ago: const Duration(minutes: 45)),
  _row(
    'standup',
    'Summarize yesterday\'s commits for standup',
    ago: const Duration(days: 1),
  ),
];

final _pins = {(host: testHost.key, session: 'pi:/forecast')};

const _modelId = 'anthropic/claude-sonnet';

const _root = RootState(
  agents: [
    AgentInfo(
      provider: 'pi',
      displayName: 'Pi',
      description: 'pi',
      models: [
        SessionModelInfo(
          id: _modelId,
          provider: 'pi',
          name: 'Claude Sonnet',
          maxContextWindow: 200000,
          configSchema: ConfigSchema(
            properties: {
              'thinkingLevel': ConfigPropertySchema(
                type: ConfigPropertySchemaType.string,
                title: 'Thinking',
                defaultValue: 'medium',
                enumValues: ['low', 'medium', 'high'],
                enumLabels: ['Low', 'Medium', 'High'],
              ),
            },
          ),
        ),
      ],
    ),
  ],
);

SessionState _sessionState(String id, String title) => SessionState(
  provider: 'pi',
  title: title,
  status: SessionStatus.idle,
  lifecycle: SessionLifecycle.ready,
  activeClients: const [],
  defaultChat: 'ahp-chat:/$id',
  chats: const [],
  config: const SessionConfigState(
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
The dashboard now has a **7-day forecast** strip under the current conditions. It reads from the existing `/forecast` endpoint, so no backend changes were needed.

## What changed

| File | Change |
| --- | --- |
| `lib/dashboard/forecast_strip.dart` | New widget: one card per day with the high, low and an icon |
| `lib/api/forecast_client.dart` | Parses `daily[]` into `DailyForecast` |
| `lib/dashboard/dashboard_page.dart` | Shows the strip below the current conditions |
| `test/forecast_strip_test.dart` | Covers empty, partial and full weeks |

Days are grouped by the station's local date, not UTC:

```dart
final days = groupBy(hourly, (h) => h.time.toLocal().dateOnly);
```

All 48 tests pass and `flutter analyze` is clean.
''';

ToolCallResponsePart _tool(String id, String verb, String target) =>
    ToolCallResponsePart(
      toolCall: ToolCallCompletedState(
        toolCallId: id,
        toolName: verb == 'Ran' ? 'bash' : verb.toLowerCase(),
        displayName: verb,
        invocationMessage: PlainString(target),
        pastTenseMessage: PlainString('$verb $target'),
        toolInput: const InlineToolInput('{}'),
        confirmed: ToolCallConfirmationReason.notNeeded,
        success: true,
      ),
    );

ChatState get _forecastChat => ChatState(
  resource: 'ahp-chat:/forecast',
  title: _forecast,
  status: const SessionStatus(33),
  modifiedAt: timeAgo(Duration.zero),
  turns: [
    Turn(
      id: 'turn-1',
      message: userMessage(
        'Add a 7-day forecast view to the dashboard. Use the existing '
        'forecast endpoint and keep it consistent with the current '
        'conditions card.',
        model: const ModelSelection(id: _modelId),
      ),
      state: TurnState.complete,
      duration: 94000,
      responseParts: [
        _tool('1', 'Read', '`lib/dashboard/dashboard_page.dart`'),
        _tool('2', 'Read', '`lib/api/forecast_client.dart`'),
        _tool('3', 'Ran', '`rg -n "class .*Card" lib`'),
        _tool('4', 'Edited', '`lib/api/forecast_client.dart`'),
        _tool('5', 'Created', '`lib/dashboard/forecast_strip.dart`'),
        _tool('6', 'Edited', '`lib/dashboard/dashboard_page.dart`'),
        _tool('7', 'Created', '`test/forecast_strip_test.dart`'),
        _tool('8', 'Ran', '`flutter test`'),
        _tool('9', 'Ran', '`flutter analyze`'),
        const MarkdownResponsePart(id: 'reply', content: _reply),
      ],
    ),
  ],
);

ChatState get _migrationChat => ChatState(
  resource: 'ahp-chat:/migrate',
  title: _migration,
  status: SessionStatus.inputNeeded,
  modifiedAt: timeAgo(const Duration(minutes: 3)),
  turns: const [],
  activeTurn: ActiveTurn(
    id: 'turn-1',
    startedAt: timeAgo(const Duration(minutes: 4)),
    message: userMessage(
      'Migrate the readings table to store UTC timestamps, and backfill '
      'the existing rows.',
      model: const ModelSelection(id: _modelId),
    ),
    responseParts: [
      _tool('1', 'Read', '`db/schema.sql`'),
      _tool('2', 'Created', '`db/migrations/0007_readings_utc.sql`'),
      const MarkdownResponsePart(
        id: 'plan',
        content:
            'The migration adds a `recorded_at_utc` column, backfills it '
            'from each station\'s time zone and then drops the old column. '
            'I\'ll run it against the local database first.',
      ),
      const ToolCallResponsePart(
        toolCall: ToolCallPendingConfirmationState(
          toolCallId: 'migrate',
          toolName: 'bash',
          displayName: 'Bash',
          invocationMessage: PlainString(
            'Run `dbmate --env-file .env.local up`',
          ),
          toolInput: InlineToolInput(
            '{"command":"dbmate --env-file .env.local up"}',
          ),
        ),
      ),
    ],
  ),
);

HostState get _host => HostState(
  status: ConnectionStatus.connected,
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  defaultDirectory: '$_home/weather-app',
  root: _root,
  sessions: catalogueFromSummaries(_sessions),
  chatChannels: {
    _forecastChat.resource: ChannelMirror.snapshot(_forecastChat),
    _migrationChat.resource: ChannelMirror.snapshot(_migrationChat),
  },
  sessionChannels: {
    'pi:/forecast': ChannelMirror.snapshot(
      _sessionState('forecast', _forecast),
    ),
    'pi:/migrate': ChannelMirror.snapshot(_sessionState('migrate', _migration)),
  },
);

Future<void> _shoot(
  WidgetTester tester,
  String name, {
  Screen screen = desktop,
  Brightness brightness = Brightness.dark,
  String? open = _forecast,
  Map<String, String> prefs = const {},
}) async {
  await pumpApp(
    tester,
    host: _host,
    screen: screen,
    brightness: brightness,
    prefs: {'pinned_sessions': encodePinned(_pins), ...prefs},
    chats: {
      for (final id in ['forecast', 'migrate']) 'pi:/$id': 'ahp-chat:/$id',
    },
    open: open,
  );
  await capture(tester, _out, name);
}

void main() {
  final skip = screenshotSkip;

  setUpAll(loadScreenshotFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('dark', skip: skip, variant: macOS, (tester) async {
    await _shoot(tester, 'desktop-dark');
  });

  testWidgets('light', skip: skip, variant: macOS, (tester) async {
    await _shoot(tester, 'desktop-light', brightness: Brightness.light);
  });

  testWidgets('a tool approval', skip: skip, variant: macOS, (tester) async {
    await _shoot(tester, 'tool-approval', open: _migration);
  });

  testWidgets('a colour theme', skip: skip, variant: macOS, (tester) async {
    await _shoot(
      tester,
      'theme-tokyo-night',
      prefs: {darkThemeKey: 'tokyo-night'},
    );
  });

  testWidgets('phone, a session', skip: skip, variant: iOS, (tester) async {
    await _shoot(tester, 'phone-session', screen: phone);
  });

  testWidgets('phone, the list', skip: skip, variant: iOS, (tester) async {
    await _shoot(tester, 'phone-list', screen: phone, open: null);
  });
}
