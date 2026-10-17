/// Tests for the review pane toggle's labels and the remembered open or
/// closed choice (AV-003).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/review/review_logic.dart';
import 'package:shireitou/src/review/review_pane_store.dart';

void main() {
  test('the toggle says what it does and what changed', () {
    expect(
      reviewToggleTooltip(open: false, shortcut: '⌥⌘B'),
      'Show review pane (⌥⌘B)',
    );
    expect(
      reviewToggleTooltip(open: true, shortcut: 'Ctrl+Alt+B'),
      'Hide review pane (Ctrl+Alt+B)',
    );
    expect(
      reviewToggleSemantics(
        open: false,
        changes: const ChangesSummary(additions: 3, deletions: 1, files: 1),
      ),
      'Show review pane, 3 lines added, 1 removed, 1 file',
    );
    expect(
      reviewToggleSemantics(
        open: true,
        changes: const ChangesSummary(additions: 2),
      ),
      'Hide review pane, 2 lines added, 0 removed',
    );
    expect(
      reviewToggleSemantics(open: false, changes: null),
      'Show review pane',
    );
  });

  test('the pane is closed by default', () async {
    final container = ProviderContainer(
      overrides: [prefsStoreProvider.overrideWithValue(MemoryPrefsStore())],
    );
    addTearDown(container.dispose);
    expect(container.read(reviewPaneOpenProvider), isFalse);
    await pumpEventQueue();
    expect(container.read(reviewPaneOpenProvider), isFalse);
  });

  test('toggling saves the choice, which the next start restores', () async {
    final prefs = MemoryPrefsStore();
    final first = ProviderContainer(
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
    );
    addTearDown(first.dispose);
    await first.read(reviewPaneOpenProvider.notifier).toggle();
    expect(first.read(reviewPaneOpenProvider), isTrue);
    expect(prefs.values['review_pane_open'], 'true');

    final second = ProviderContainer(
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    second.read(reviewPaneOpenProvider);
    await pumpEventQueue();
    expect(second.read(reviewPaneOpenProvider), isTrue);
    await second.read(reviewPaneOpenProvider.notifier).toggle();
    expect(prefs.values['review_pane_open'], 'false');
  });
}
