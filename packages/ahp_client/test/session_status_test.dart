import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  group('SessionStatus', () {
    test('decodes combined flags bitwise', () {
      const status = SessionStatus(33); // Idle | IsRead
      expect(status.isIdle, isTrue);
      expect(status.isReadFlag, isTrue);
      expect(status.isInProgress, isFalse);
      expect(status.isArchivedFlag, isFalse);
    });

    test('InputNeeded implies InProgress, not the reverse', () {
      expect(SessionStatus.inputNeeded.isInProgress, isTrue);
      expect(SessionStatus.inputNeeded.isInputNeeded, isTrue);
      expect(SessionStatus.inProgress.isInputNeeded, isFalse);
    });

    test('read and archived flags are orthogonal to activity', () {
      const status = SessionStatus(8 | 16 | 64);
      expect(status.isInputNeeded, isTrue);
      expect(status.isArchivedFlag, isTrue);
      expect(status.isReadFlag, isFalse);
    });

    test('withFlag sets and clears one flag', () {
      final read = SessionStatus.idle.withFlag(
        SessionStatus.isRead,
        enabled: true,
      );
      expect(read.bits, 33);
      expect(read.withFlag(SessionStatus.isRead, enabled: false).bits, 1);
    });

    test('round-trips through JSON', () {
      final summary = SessionSummary.fromJson(const {
        'resource': 'ahp-session:/a',
        'provider': 'pi',
        'title': 't',
        'status': 42,
        'createdAt': '2026-01-01T00:00:00Z',
        'modifiedAt': '2026-01-01T00:00:00Z',
      });
      expect(summary.status.isError, isTrue);
      expect(summary.toJson()['status'], 42);
    });
  });
}
