import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

const _chat = 'ahp-chat:/c';
final _t0 = DateTime.utc(2026, 10, 1, 12);

DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

const _streaming = ToolCallStreamingState(
  toolCallId: 'a',
  toolName: 'bash',
  displayName: 'Bash',
);

const _pending = ToolCallPendingConfirmationState(
  toolCallId: 'a',
  toolName: 'bash',
  displayName: 'Bash',
  invocationMessage: PlainString('Run ls'),
);

const _running = ToolCallRunningState(
  toolCallId: 'a',
  toolName: 'bash',
  displayName: 'Bash',
  invocationMessage: PlainString('Run ls'),
  confirmed: ToolCallConfirmationReason.notNeeded,
);

const _done = ToolCallCompletedState(
  toolCallId: 'a',
  toolName: 'bash',
  displayName: 'Bash',
  invocationMessage: PlainString('Run ls'),
  pastTenseMessage: PlainString('Ran ls'),
  confirmed: ToolCallConfirmationReason.notNeeded,
  success: true,
);

ChatState _chatWith(List<ToolCallState> calls) =>
    ChatState.fromJson(const {
      'resource': _chat,
      'title': 'c',
      'status': 8,
      'modifiedAt': '2026-10-01T12:00:00Z',
      'turns': <Object?>[],
    }).copyWith(
      activeTurn: ActiveTurn(
        id: 't',
        startedAt: '2026-10-01T12:00:00Z',
        message: userMessage('hi'),
        responseParts: [
          for (final call in calls) ToolCallResponsePart(toolCall: call),
        ],
      ),
    );

HostState _host(
  List<ToolCallState>? calls, {
  ConnectionStatus status = ConnectionStatus.connected,
}) => HostState(
  status: status,
  chatChannels: {
    if (calls != null) _chat: ChannelMirror.snapshot(_chatWith(calls)),
  },
);

/// Observes [steps] in order, one second apart from [_t0].
ToolCallTimings _observe(List<HostState> steps) {
  ToolCallTimings timings = const {};
  for (final (i, state) in steps.indexed) {
    timings = observeToolCalls(timings, state, _at(i));
  }
  return timings;
}

void main() {
  test('times a call from running to done', () {
    final timings = _observe([
      _host([_streaming]),
      _host([_running]),
      _host([_running]),
      _host([_running]),
      _host([_done]),
    ]);
    final timing = timings[_chat]!['a']!;
    expect(timing.running, isFalse);
    expect(timing.partial, isFalse);
    expect(timing.elapsed(_at(99)), const Duration(seconds: 3));
  });

  test('a running call counts up to now', () {
    final timing = _observe([
      _host([_streaming]),
      _host([_running]),
    ])[_chat]!['a']!;
    expect(timing.running, isTrue);
    expect(timing.elapsed(_at(11)), const Duration(seconds: 10));
  });

  test('waiting on approval does not count', () {
    final timing = _observe([
      _host([_streaming]),
      _host([_pending]),
      _host([_pending]),
      _host([_pending]),
      _host([_running]),
      _host([_done]),
    ])[_chat]!['a']!;
    expect(timing.elapsed(_at(99)), const Duration(seconds: 1));
  });

  test('a call first seen running is a lower bound', () {
    final timing = _observe([
      _host([_running]),
      _host([_done]),
    ])[_chat]!['a']!;
    expect(timing.partial, isTrue);
    expect(timing.elapsed(_at(99)), const Duration(seconds: 1));
  });

  test('a call first seen finished has no timing', () {
    expect(
      _observe([
        _host(const [_done]),
      ]),
      isEmpty,
    );
  });

  test('a call that never ran has no elapsed time', () {
    final timing = _observe([
      _host([_streaming]),
      _host([_pending]),
    ])[_chat]!['a']!;
    expect(timing.elapsed(_at(99)), isNull);
  });

  test('a lost connection closes the interval as a lower bound', () {
    final timings = _observe([
      _host([_streaming]),
      _host([_running]),
      _host([_running], status: ConnectionStatus.reconnecting),
      _host([_running], status: ConnectionStatus.reconnecting),
      _host([_running]),
      _host([_done]),
    ]);
    final timing = timings[_chat]!['a']!;
    expect(timing.partial, isTrue);
    // Running from 1 to 2, then again from 4 to 5; the gap is not counted.
    expect(timing.elapsed(_at(99)), const Duration(seconds: 2));
  });

  test('a call that leaves the active turn while running stops', () {
    final timing = _observe([
      _host([_streaming]),
      _host([_running]),
      _host(const []),
    ])[_chat]!['a']!;
    expect(timing.running, isFalse);
    expect(timing.partial, isFalse);
    expect(timing.elapsed(_at(99)), const Duration(seconds: 1));
  });

  test('an unsubscribed chat stops its calls as lower bounds', () {
    final timing = _observe([
      _host([_streaming]),
      _host([_running]),
      _host(null),
    ])[_chat]!['a']!;
    expect(timing.running, isFalse);
    expect(timing.partial, isTrue);
  });

  test('returns the same map when nothing changed', () {
    final timings = _observe([
      _host([_streaming]),
      _host([_running]),
    ]);
    expect(observeToolCalls(timings, _host([_running]), _at(5)), same(timings));
    expect(
      observeToolCalls(const {}, _host(null), _at(5)),
      same(const <String, Map<String, ToolCallTiming>>{}),
    );
  });
}
