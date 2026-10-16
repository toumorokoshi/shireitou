import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  const channel = 'ahp-session:/a';

  test('only the first acquire and last release reach the host', () {
    final first = acquireSubscription(const {}, channel);
    expect(first.sendToHost, isTrue);
    final second = acquireSubscription(first.counts, channel);
    expect(second.sendToHost, isFalse);
    expect(second.counts[channel], 2);

    final release1 = releaseSubscription(second.counts, channel);
    expect(release1.sendToHost, isFalse);
    final release2 = releaseSubscription(release1.counts, channel);
    expect(release2.sendToHost, isTrue);
    expect(release2.counts, isEmpty);
  });

  test('releasing an unknown channel is a no-op', () {
    final change = releaseSubscription(const {}, channel);
    expect(change.sendToHost, isFalse);
    expect(change.counts, isEmpty);
  });
}
