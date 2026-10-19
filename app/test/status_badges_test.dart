import 'package:ahp_client/ahp_client.dart';

import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/layout.dart';
import 'package:shireitou/src/session_list/relative_time.dart';
import 'package:shireitou/src/session_list/status_badges.dart';
import 'package:shireitou/src/theme/app_colors.dart';

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

  group('dotBadgeFor', () {
    test('shows one status, unread only when idle', () {
      expect(dotBadgeFor(const SessionStatus(33)), SessionBadge.idle);
      expect(dotBadgeFor(const SessionStatus(1)), SessionBadge.unread);
      expect(dotBadgeFor(const SessionStatus(8)), SessionBadge.working);
      expect(dotBadgeFor(SessionStatus.inputNeeded), SessionBadge.needsInput);
      expect(dotBadgeFor(const SessionStatus(2)), SessionBadge.error);
      // Other flags (archived 64) do not change the dot.
      expect(
        dotBadgeFor(const SessionStatus(8 | 32 | 64)),
        SessionBadge.working,
      );
    });

    test('statusDotColor takes the theme\'s status colours', () {
      final status = AppColors.dark;
      const unread = Color(0xFFFFFFFF);
      Color dot(SessionBadge badge) =>
          statusDotColor(badge, status.statusColors, unread: unread);
      expect(dot(SessionBadge.working), status.statusColors.running);
      expect(dot(SessionBadge.needsInput), status.statusColors.attention);
      expect(dot(SessionBadge.error), status.statusColors.error);
      expect(dot(SessionBadge.idle), status.statusColors.idle);
      expect(dot(SessionBadge.unread), unread);
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
      '5 mins ago',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now),
      '3 hrs ago',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now),
      '2 days ago',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 61)), now),
      '1 hr ago',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 15)), now),
      '2 wks ago',
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
