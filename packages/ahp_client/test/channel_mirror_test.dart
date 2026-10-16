import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

/// A toy reducer: appends `action['v']` to a list of strings.
List<String> _append(List<String> state, JsonMap action) => [
  ...state,
  action['v']! as String,
];

ActionEnvelope _envelope(
  String value, {
  ActionOrigin? origin,
  String? rejectionReason,
}) => ActionEnvelope(
  channel: 'c',
  action: {'v': value},
  serverSeq: 1,
  origin: origin,
  rejectionReason: rejectionReason,
);

void main() {
  const mine = ActionOrigin(clientId: 'me', clientSeq: 1);
  final pending = applyPendingAction(
    const ChannelMirror<List<String>>.snapshot([]),
    (clientSeq: 1, action: {'v': 'local'}),
    _append,
  );

  test('a dispatched action shows at once but is not confirmed', () {
    expect(pending.state, ['local']);
    expect(pending.confirmed, isEmpty);
    expect(pending.pending.single.clientSeq, 1);
  });

  test('host actions before the echo are rebased under it', () {
    final next = applyHostEnvelope(
      pending,
      _envelope('host'),
      _append,
      clientId: 'me',
    );
    expect(next.confirmed, ['host']);
    expect(next.state, ['host', 'local']);
  });

  test('the echo confirms the action and clears it', () {
    final next = applyHostEnvelope(
      pending,
      _envelope('local', origin: mine),
      _append,
      clientId: 'me',
    );
    expect(next.pending, isEmpty);
    expect(next.state, ['local']);
    expect(next.confirmed, ['local']);
  });

  test('a rejection rolls the action back', () {
    final next = applyHostEnvelope(
      pending,
      _envelope('local', origin: mine, rejectionReason: 'no'),
      _append,
      clientId: 'me',
    );
    expect(next.pending, isEmpty);
    expect(next.state, isEmpty);
  });

  test("another client's sequence number does not clear ours", () {
    final next = applyHostEnvelope(
      pending,
      _envelope(
        'other',
        origin: const ActionOrigin(clientId: 'them', clientSeq: 1),
      ),
      _append,
      clientId: 'me',
    );
    expect(next.pending, hasLength(1));
    expect(next.state, ['other', 'local']);
  });
}
