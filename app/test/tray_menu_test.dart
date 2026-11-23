/// System tray icon and dropdown menu for active and pinned conversations.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/desktop/tray_backend.dart';
import 'package:shireitou/src/desktop/tray_dot_icon.dart';
import 'package:shireitou/src/desktop/tray_menu_items.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';
import 'package:shireitou/src/session_list/status_badges.dart';
import 'package:shireitou/src/theme/app_colors.dart';

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
          'Needs approval',
          'Working newer',
          'Working older',
        ]);
        expect(model.active.map((i) => i.status), [
          SessionBadge.needsInput,
          SessionBadge.working,
          SessionBadge.working,
        ]);
        // Preserves pin order, not modifiedAt order.
        expect(model.pinned.map((i) => i.ref.session), [
          'pi:/idle-pinned-2',
          'pi:/idle-pinned-1',
        ]);
        expect(model.pinned.map((i) => i.label), [
          'Second pinned',
          'First pinned',
        ]);
        expect(model.pinned.map((i) => i.status), [
          SessionBadge.unread,
          SessionBadge.idle,
        ]);
      },
    );

    test('assigns status dot colors from StatusColors', () {
      const statusColors = StatusColors(
        running: Color(0xFF112233),
        attention: Color(0xFF445566),
        done: Color(0xFF778899),
        error: Color(0xFFAABBCC),
        idle: Color(0xFFDDEEFF),
      );
      const unreadColor = Color(0xFF123456);

      final sessions = [
        HostSession('h', session('w', status: _working, title: 'Working')),
        HostSession('h', session('i', status: _input, title: 'Input')),
        HostSession('h', session('e', status: _failed, title: 'Error')),
        HostSession('h', session('u', status: _unread, title: 'Unread')),
        HostSession('h', session('d', status: _idle, title: 'Idle')),
      ];
      final pins = <SessionRef>{
        (host: 'h', session: 'pi:/e'),
        (host: 'h', session: 'pi:/u'),
        (host: 'h', session: 'pi:/d'),
      };

      final model = buildTrayMenuModel(
        sessions: sessions,
        pins: pins,
        hostLabels: const {},
        statusColors: statusColors,
        unreadColor: unreadColor,
      );

      expect(model.active.map((i) => (i.status, i.dotColor)), [
        (SessionBadge.needsInput, statusColors.attention),
        (SessionBadge.working, statusColors.running),
      ]);
      expect(model.pinned.map((i) => (i.status, i.dotColor)), [
        (SessionBadge.error, statusColors.error),
        (SessionBadge.unread, unreadColor),
        (SessionBadge.idle, statusColors.idle),
      ]);
    });

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
      expect(model.pinned.single.label, 'Failed and pinned');
      expect(model.pinned.single.status, SessionBadge.error);
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

        expect(model.active.single.label.length, maxTrayTitleLength);
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
            ...hostOverrides(connection: connection, tray: backend),
            prefsStoreProvider.overrideWithValue(prefs),
          ],
          child: const ShireitouApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(backend.lastModel, isNotNull);
      expect(backend.lastModel!.active.map((i) => i.ref.session), ['pi:/a1']);
      expect(backend.lastModel!.active.single.status, SessionBadge.working);
      expect(backend.lastModel!.active.single.dotColor, isNotNull);
      expect(backend.lastModel!.pinned.map((i) => i.ref.session), ['pi:/p1']);
      expect(backend.lastModel!.pinned.single.status, SessionBadge.idle);
      expect(backend.lastModel!.pinned.single.dotColor, isNotNull);

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

  group('status dot PNG', () {
    test('renders a valid 16x16 RGBA PNG data URI', () async {
      const color = Color(0xFF3388FF);
      final uri = statusDotDataUri(color);
      expect(uri, startsWith('data:image/png;base64,'));

      final bytes = base64Decode(
        uri.substring('data:image/png;base64,'.length),
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      expect(image.width, 16);
      expect(image.height, 16);

      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      // Top-left corner (0, 0) should be transparent.
      expect(rgba.getUint8(3), 0);
      // Center pixel (8, 8) should be opaque in the requested color.
      final centerOffset = (8 * 16 + 8) * 4;
      expect(rgba.getUint8(centerOffset), 0x33);
      expect(rgba.getUint8(centerOffset + 1), 0x88);
      expect(rgba.getUint8(centerOffset + 2), 0xFF);
      expect(rgba.getUint8(centerOffset + 3), 255);
      image.dispose();
    });
  });
}
