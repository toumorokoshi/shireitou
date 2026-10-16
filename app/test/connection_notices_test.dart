import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/connection_notices.dart';

ActionFailure _failure(ActionFailureKind kind, {String? reason}) =>
    ActionFailure(
      channel: 'ahp-chat:/1',
      clientSeq: 1,
      action: const {'type': 'chat/turnStarted'},
      kind: kind,
      reason: reason,
    );

void main() {
  test('describeActionType names known actions', () {
    expect(
      describeActionType(const {'type': 'chat/turnStarted'}),
      'Your message',
    );
    expect(describeActionType(const {'type': 'x/other'}), 'x/other');
    expect(describeActionType(const {}), 'That action');
  });

  test('describeActionFailure explains each kind', () {
    expect(
      describeActionFailure(
        _failure(ActionFailureKind.rejected, reason: 'busy'),
      ),
      'The host rejected that (busy). Your message was undone.',
    );
    expect(
      describeActionFailure(_failure(ActionFailureKind.timedOut)),
      contains('did not confirm that in time'),
    );
    expect(
      describeActionFailure(_failure(ActionFailureKind.connectionLost)),
      contains('may not have gone through'),
    );
  });

  test('compatibilityNotice lists what 0.9.0 lacks', () {
    final notice = compatibilityNotice('0.9.0')!;
    expect(notice, startsWith('This host speaks AHP 0.9.0'));
    for (final feature in ProtocolFeature.values) {
      expect(notice, contains(feature.label));
    }
    expect(compatibilityNotice('1.0.0'), isNull);
    expect(compatibilityNotice(null), isNull);
  });
}
