import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/layout.dart';
import 'package:shireitou/src/session_list/relative_time.dart';
import 'package:shireitou/src/session_list/status_badges.dart';

void main() {
  group('badgesFor', () {
    test('idle and read shows only Idle', () {
      expect(badgesFor(const SessionStatus(33)), [SessionBadge.idle]);
    });

    test('input needed wins over working, and unread is added', () {
      expect(badgesFor(SessionStatus.inputNeeded), [
        SessionBadge.needsInput,
        SessionBadge.unread,
      ]);
    });

    test('in progress shows Working', () {
      expect(badgesFor(const SessionStatus(8 | 32)), [SessionBadge.working]);
    });

    test('error shows Error', () {
      expect(badgesFor(const SessionStatus(2 | 32)), [SessionBadge.error]);
    });
  });

  test('needsAttention covers input, error and unread', () {
    expect(needsAttention(const SessionStatus(33)), isFalse);
    expect(needsAttention(const SessionStatus(1)), isTrue);
    expect(needsAttention(const SessionStatus(24 | 32)), isTrue);
    expect(needsAttention(const SessionStatus(2 | 32)), isTrue);
  });

  test('formatRelativeTime', () {
    final now = DateTime.utc(2026, 10, 15, 12);
    expect(formatRelativeTime(now, now), 'just now');
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 5)), now),
      '5m',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now),
      '3h',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now),
      '2d',
    );
    expect(formatRelativeTime(DateTime(2026, 1, 2), now), '2026-01-02');
  });

  test('layoutTierFor uses the spec breakpoints', () {
    expect(layoutTierFor(699), LayoutTier.compact);
    expect(layoutTierFor(700), LayoutTier.medium);
    expect(layoutTierFor(1199), LayoutTier.medium);
    expect(layoutTierFor(1200), LayoutTier.wide);
  });
}
