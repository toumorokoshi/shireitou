/// Restoring the settings the macOS app kept while it was sandboxed: which
/// values are copied, merged or kept, and that it runs once.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/desktop/sandbox_prefs.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';

const _a = (host: 'ws://h:1', session: 'pi:/a');
const _b = (host: 'ws://h:1', session: 'pi:/b');
const _c = (host: 'ws://h:1', session: 'pi:/c');

void main() {
  group('sandboxPrefWrites', () {
    test('copies string settings the current ones lack', () {
      expect(
        sandboxPrefWrites(
          sandboxed: {'folder_order': '["x"]', 'theme_mode': 'dark'},
          current: {'folder_order': null, 'theme_mode': null},
        ),
        {'folder_order': '["x"]', 'theme_mode': 'dark'},
      );
    });

    test('keeps a current value over the sandboxed one', () {
      expect(
        sandboxPrefWrites(
          sandboxed: {'theme_mode': 'dark'},
          current: {'theme_mode': 'light'},
        ),
        isEmpty,
      );
    });

    test('skips values that are not strings', () {
      expect(
        sandboxPrefWrites(
          sandboxed: {
            'flutter_local_notifications_presentation_options': {
              'presentAlert': true,
            },
            'flag': true,
          },
          current: {},
        ),
        isEmpty,
      );
    });

    test('merges the pins, sandboxed ones first', () {
      final writes = sandboxPrefWrites(
        sandboxed: {
          pinnedSessionsKey: encodePinned({_a, _b}),
        },
        current: {
          pinnedSessionsKey: encodePinned({_c, _a}),
        },
      );
      expect(decodePinned(writes[pinnedSessionsKey]).toList(), [_a, _b, _c]);
    });

    test('writes nothing when merging changes nothing', () {
      expect(
        sandboxPrefWrites(
          sandboxed: {
            pinnedSessionsKey: encodePinned({_a}),
          },
          current: {
            pinnedSessionsKey: encodePinned({_a, _b}),
          },
        ),
        isEmpty,
      );
    });
  });

  group('migrateSandboxPrefs', () {
    test('restores the sandboxed settings once', () async {
      final store = MemoryPrefsStore({
        pinnedSessionsKey: encodePinned({_c}),
      });
      var reads = 0;
      Future<Map<String, Object?>?> read() async {
        reads++;
        return {
          pinnedSessionsKey: encodePinned({_a}),
          'theme_mode': 'dark',
        };
      }

      await migrateSandboxPrefs(store, read: read);
      expect(decodePinned(store.values[pinnedSessionsKey]).toList(), [_a, _c]);
      expect(store.values['theme_mode'], 'dark');
      expect(store.values[sandboxPrefsMigratedKey], 'true');

      await store.write(pinnedSessionsKey, encodePinned({_c}));
      await migrateSandboxPrefs(store, read: read);
      expect(reads, 1);
      expect(decodePinned(store.values[pinnedSessionsKey]), {_c});
    });

    test('marks it done when there is nothing to restore', () async {
      final store = MemoryPrefsStore();
      await migrateSandboxPrefs(store, read: () async => null);
      expect(store.values, {sandboxPrefsMigratedKey: 'true'});
    });

    test('leaves the settings and retries later when reading fails', () async {
      final store = MemoryPrefsStore();
      await migrateSandboxPrefs(store, read: () => throw StateError('broken'));
      expect(store.values, isEmpty);
    });
  });
}
