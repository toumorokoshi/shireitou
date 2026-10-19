/// The contrast function and the WCAG AA checks of the theme's tokens
/// (AV-090, AV-141), in the dark and the light theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/tool_previews.dart';
import 'package:shireitou/src/theme/app_theme.dart';
import 'package:shireitou/src/theme/contrast.dart';

/// Fails with the pair's name and ratio when [foreground] on any of
/// [backgrounds] is under [minimum].
void _expectContrast(
  String name,
  Color foreground,
  Map<String, Color> backgrounds,
  double minimum,
) {
  for (final MapEntry(key: surface, value: background) in backgrounds.entries) {
    final ratio = contrastRatio(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(minimum),
      reason:
          '$name on $surface is ${ratio.toStringAsFixed(2)}:1, '
          'under $minimum:1',
    );
  }
}

void main() {
  group('contrastRatio', () {
    test('black on white is 21:1 and either order gives the same', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
    });

    test('a colour on itself is 1:1', () {
      const grey = Color(0xFF777777);
      expect(contrastRatio(grey, grey), 1);
    });

    test('matches a known pair (#767676 on white is 4.54:1)', () {
      expect(
        contrastRatio(const Color(0xFF767676), Colors.white),
        closeTo(4.54, 0.01),
      );
    });

    test('a translucent colour is composited onto the background', () {
      expect(contrastRatio(const Color(0x00000000), Colors.white), 1);
      expect(
        contrastRatio(const Color(0x80000000), Colors.white),
        contrastRatio(
          Color.alphaBlend(const Color(0x80000000), Colors.white),
          Colors.white,
        ),
      );
    });
  });

  group('readable', () {
    const dark = Color(0xFF202020);
    test('keeps a colour that already passes', () {
      const white = Color(0xFFFFFFFF);
      expect(readable(white, [dark], minimum: 4.5, dark: true), white);
    });

    test('lightens a dim colour on a dark theme just enough', () {
      const dim = Color(0xFF555555);
      final fixed = readable(dim, [dark], minimum: 4.5, dark: true);
      expect(contrastRatio(fixed, dark), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(fixed, dark), lessThan(5));
      expect(fixed.computeLuminance(), greaterThan(dim.computeLuminance()));
    });

    test('darkens a pale colour on a light theme', () {
      const light = Color(0xFFF6F6F6);
      final fixed = readable(
        const Color(0xFFBBBBBB),
        [light],
        minimum: 4.5,
        dark: false,
      );
      expect(contrastRatio(fixed, light), greaterThanOrEqualTo(4.5));
    });
  });

  test('every theme has a unique id and the defaults exist', () {
    expect(allThemes.map((t) => t.id).toSet(), hasLength(allThemes.length));
    expect(allThemes.every((t) => t.colors.length == 24), isTrue);
    for (final brightness in Brightness.values) {
      expect(themesFor(brightness).first, defaultTheme(brightness));
    }
  });

  for (final theme in allThemes) {
    _themeGroup(theme);
  }

  testWidgets('the terminal box follows the theme', (tester) async {
    for (final theme in [defaultTheme(Brightness.light), allThemes.last]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(theme),
          home: const Scaffold(
            body: TerminalBox(title: 'bash', status: 'Running', output: 'hi'),
          ),
        ),
      );
      // MaterialApp animates between themes.
      await tester.pumpAndSettle();
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('bash'),
              matching: find.byWidgetPredicate(
                (widget) => widget is Container && widget.decoration != null,
              ),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      final terminal = AppColors.forTheme(theme).terminal;
      expect(decoration.color, terminal.background);
      expect(
        tester.widget<Text>(find.text('hi')).style?.color,
        terminal.foreground,
      );
    }
  });
}

/// The WCAG checks of [spec]'s tokens.
void _themeGroup(ThemeSpec spec) {
  group('${spec.id} tokens', () {
    final theme = buildTheme(spec, platform: TargetPlatform.macOS);
    final scheme = theme.colorScheme;
    final tokens = AppColors.forTheme(spec);
    // The surfaces text, dots and icons are drawn on.
    final surfaces = {
      'background': scheme.surface,
      'sidebar': tokens.sidebarBackground,
      'raised surface': tokens.raisedSurface,
      'selected row': tokens.selectedFill,
      'hovered row': tokens.hoverFill,
      'bubble': tokens.bubbleFill,
    };
    final textSurfaces = {
      'background': scheme.surface,
      'sidebar': tokens.sidebarBackground,
      'raised surface': tokens.raisedSurface,
    };
    // Diff lines are drawn on the diff area (the sidebar's grey) with
    // the added or removed fill over it.
    final area = tokens.sidebarBackground;
    final diffSurfaces = {
      'diff area': area,
      'added line': Color.alphaBlend(tokens.diffAddedFill, area),
      'removed line': Color.alphaBlend(tokens.diffRemovedFill, area),
    };
    // Code blocks in replies use the bubble fill.
    final codeSurfaces = {'code block': tokens.bubbleFill, 'diff area': area};

    test('text and muted text are 4.5:1 on every surface', () {
      _expectContrast('text', scheme.onSurface, surfaces, textContrast);
      _expectContrast('muted text', tokens.mutedText, surfaces, textContrast);
    });

    test('status dots are 3:1 on every surface', () {
      final status = tokens.statusColors;
      for (final (name, color) in [
        ('running', status.running),
        ('attention', status.attention),
        ('done', status.done),
        ('error', status.error),
        ('idle', status.idle),
      ]) {
        _expectContrast(name, color, surfaces, uiContrast);
      }
    });

    test('error text and links are 4.5:1 where they are shown', () {
      _expectContrast('error', scheme.error, textSurfaces, textContrast);
      _expectContrast('accent', scheme.primary, textSurfaces, textContrast);
    });

    test('hairlines are decorative but visible on the main surfaces', () {
      // Dividers and box borders are not needed to identify a control
      // (WCAG 1.4.11), so they are kept faint like the reference; the
      // focused field border is the accent, which is checked above.
      _expectContrast('hairline', tokens.hairline, textSurfaces, 1.1);
      _expectContrast(
        'focused border',
        scheme.primary,
        textSurfaces,
        uiContrast,
      );
    });

    test('diff text is 4.5:1 and the gutter 3:1 on every diff line', () {
      _expectContrast('code', scheme.onSurface, diffSurfaces, textContrast);
      // Line numbers repeat what the position shows: secondary text.
      _expectContrast(
        'gutter',
        tokens.diffGutterText,
        diffSurfaces,
        uiContrast,
      );
    });

    test('the terminal foreground and header are 4.5:1', () {
      final background = {'terminal': tokens.terminal.background};
      _expectContrast(
        'terminal text',
        tokens.terminal.foreground,
        background,
        textContrast,
      );
      _expectContrast('header', tokens.mutedText, background, textContrast);
    });

    test('highlight colours are 4.5:1 on code, 3:1 on diff fills', () {
      final highlight = tokens.syntax;
      expect(theme.extension<AppColors>()!.syntax, same(highlight));
      for (final MapEntry(key: scope, value: style) in highlight.entries) {
        if (style.color case final color?) {
          _expectContrast(scope, color, codeSurfaces, textContrast);
          // A tinted diff line keeps its syntax colours readable but
          // below 4.5:1, as in VS Code; the plain text is checked above.
          _expectContrast(scope, color, diffSurfaces, uiContrast);
        }
      }
    });

    test('the filled button text is 4.5:1 on the accent', () {
      _expectContrast('on accent', scheme.onPrimary, {
        'accent': scheme.primary,
      }, textContrast);
    });
  });
}
