/// System tray icon and dropdown menu for active and pinned conversations.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/desktop/tray_backend.dart';
import 'package:shireitou/src/desktop/tray_menu.dart';
import 'package:shireitou/src/desktop/tray_menu_items.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _working = 8 | 32;
const _input = 8 | 16 | 32;
const _idle = 1 | 32;
const _unread = 1;
const _failed = 1 | 2 | 32;
const _archived = 1 | 32 | 64;

class _RecordingTrayBackend implements TrayBackend {
  TrayMenuModel? lastModel;
  ValueChanged<SessionRef>? onSelectSession;
  VoidCallback? onShowWindow;
  VoidCallback? onQuit;
  int updates = 0;
  bool disposed = false;

  @override
  void update(
    TrayMenuModel model, {
    required ValueChanged<SessionRef> onSelectSession,
    required VoidCallback onShowWindow,
    required VoidCallback onQuit,
  }) {
    updates++;
    lastModel = model;
    this.onSelectSession = onSelectSession;
    this.onShowWindow = onShowWindow;
    this.onQuit = onQuit;
  }

  @override
  void dispose() => disposed = true;
}

void main() {
  group('buildTrayMenuModel', () {
    test(
      'puts active sessions first (needs input before working), then pinned',
      () {
        final sessions = [
          HostSession(
            'h',
            session(
              'idle-pinned-1',
              status: _idle,
              title: 'First pinned',
              modifiedAt: '2026-10-05T00:00:00Z',
            ),
          ),
          HostSession(
            'h',
            session(
              'idle-unpinned',
              status: _idle,
              title: 'Unpinned idle',
              modifiedAt: '2026-10-06T00:00:00Z',
            ),
          ),
          HostSession(
            'h',
            session(
              'working-older',
              status: _working,
              title: 'Working older',
              modifiedAt: '2026-10-02T00:00:00Z',
            ),
          ),
          HostSession(
            'h',
            session(
              'working-newer',
              status: _working,
              title: 'Working newer',
              modifiedAt: '2026-10-04T00:00:00Z',
            ),
          ),
          HostSession(
            'h',
            session(
              'input-1',
              status: _input,
              title: 'Needs approval',
              modifiedAt: '2026-10-01T00:00:00Z',
            ),
          ),
          HostSession(
            'h',
            session(
              'idle-pinned-2',
              status: _unread,
              title: 'Second pinned',
              modifiedAt: '2026-10-03T00:00:00Z',
            ),
          ),
        ];

        final pins = <SessionRef>{
          (host: 'h', session: 'pi:/idle-pinned-2'),
          (host: 'h', session: 'pi:/idle-pinned-1'),
        };

        final model = buildTrayMenuModel(
          sessions: sessions,
          pins: pins,
          hostLabels: const {},
          attentionCount: 2,
        );

        expect(model.tooltip, '(2) shireitou');
        expect(model.active.map((i) => i.ref.session), [
          'pi:/input-1',
          'pi:/working-newer',
          'pi:/working-older',
        ]);
        expect(model.active.map((i) => i.label), [
          '◆ Needs approval',
          '● Working newer',
          '● Working older',
        ]);
        // Preserves pin order, not modifiedAt order.
        expect(model.pinned.map((i) => i.ref.session), [
          'pi:/idle-pinned-2',
          'pi:/idle-pinned-1',
        ]);
        expect(model.pinned.map((i) => i.label), [
          '• Second pinned',
          'First pinned',
        ]);
      },
    );

    test('does not duplicate a pinned session that is also active', () {
      final sessions = [
        HostSession(
          'h',
          session('a', status: _working, title: 'Active and pinned'),
        ),
        HostSession(
          'h',
          session('b', status: _failed, title: 'Failed and pinned'),
        ),
      ];
      final pins = <SessionRef>{
        (host: 'h', session: 'pi:/a'),
        (host: 'h', session: 'pi:/b'),
      };

      final model = buildTrayMenuModel(
        sessions: sessions,
        pins: pins,
        hostLabels: const {},
      );

      expect(model.active.map((i) => i.ref.session), ['pi:/a']);
      expect(model.pinned.map((i) => i.ref.session), ['pi:/b']);
      expect(model.pinned.single.label, '✕ Failed and pinned');
    });

    test('excludes archived sessions even if pinned or in progress', () {
      final sessions = [
        HostSession(
          'h',
          session('arch', status: _archived | 8, title: 'Archived'),
        ),
      ];
      final pins = <SessionRef>{(host: 'h', session: 'pi:/arch')};

      final model = buildTrayMenuModel(
        sessions: sessions,
        pins: pins,
        hostLabels: const {},
      );

      expect(model.isEmpty, isTrue);
      expect(model.active, isEmpty);
      expect(model.pinned, isEmpty);
    });

    test(
      'truncates long titles, handles blank titles, and formats tooltips',
      () {
        final longTitle = 'A' * (maxTrayTitleLength + 20);
        final sessions = [
          HostSession(
            'h1',
            session(
              'long',
              status: _working,
              title: longTitle,
              directory: 'file:///src/shireitou',
            ),
          ),
          HostSession('h2', session('blank', status: _idle, title: '   ')),
        ];
        final pins = <SessionRef>{(host: 'h2', session: 'pi:/blank')};

        final model = buildTrayMenuModel(
          sessions: sessions,
          pins: pins,
          hostLabels: const {'h1': 'alpha', 'h2': 'beta'},
        );

        expect(
          model.active.single.label.length,
          '● '.length + maxTrayTitleLength,
        );
        expect(model.active.single.label, endsWith('…'));
        expect(
          model.active.single.tooltip,
          '$longTitle · Working · shireitou · alpha',
        );
        expect(model.pinned.single.label, 'Untitled session');
        expect(model.pinned.single.tooltip, 'Untitled session · beta');
      },
    );
  });

  group('TrayMenu widget', () {
    testWidgets('updates backend and opens clicked conversation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      FlutterSecureStorage.setMockInitialValues({});
      final backend = _RecordingTrayBackend();
      final prefs = MemoryPrefsStore({
        pinnedSessionsKey: encodePinned({
          (host: testHost.key, session: 'pi:/p1'),
        }),
      });
      final connection = FakeHostConnection(
        HostState(
          status: ConnectionStatus.connected,
          protocolVersion: '1.0.0',
          sessions: catalogueFromSummaries([
            session('a1', status: _working, title: 'Active chat'),
            session('p1', status: _idle, title: 'Pinned chat'),
          ]),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...hostOverrides(connection: connection),
            prefsStoreProvider.overrideWithValue(prefs),
            trayBackendProvider.overrideWithValue(backend),
          ],
          child: const ShireitouApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(backend.lastModel, isNotNull);
      expect(backend.lastModel!.active.map((i) => i.ref.session), ['pi:/a1']);
      expect(backend.lastModel!.pinned.map((i) => i.ref.session), ['pi:/p1']);

      // Clicking a conversation in the tray opens it in the session pane.
      backend.onSelectSession!((host: testHost.key, session: 'pi:/p1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.descendant(
          of: find.byType(SessionDetailView),
          matching: find.text('Pinned chat'),
        ),
        findsOneWidget,
      );
    });
  });
}
