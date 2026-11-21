/// A copy-to-clipboard icon button with copied feedback (AV-061, AV-071),
/// and a one-line read-only field with that button on its right.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../clipboard/rich_clipboard.dart';

/// An icon button that copies [text] to the clipboard, then shows a check
/// and "Copied" for [feedback] and announces "Copied to clipboard" to
/// screen readers (as VS Code's chat copy action does).
class CopyButton extends StatefulWidget {
  /// Creates a [CopyButton] for [text] labelled [tooltip].
  const CopyButton({
    super.key,
    required this.text,
    this.html,
    this.icon = Icons.copy,
    this.tooltip = 'Copy',
    this.iconSize = 16,
    this.feedback = const Duration(milliseconds: 1200),
  });

  /// The text copied, read when pressed.
  final String Function() text;

  /// The HTML copied along with the text, made from it; null copies only
  /// the text.
  final String Function(String text)? html;

  /// The icon before copying.
  final IconData icon;

  /// The tooltip and screen reader label before copying.
  final String tooltip;

  /// The icon's size.
  final double iconSize;

  /// How long the copied state shows.
  final Duration feedback;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  Timer? _reset;

  bool get _copied => _reset?.isActive ?? false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = widget.text();
    if (widget.html case final html?) {
      await setRichClipboard(text: text, html: html(text));
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }
    if (!mounted) return;
    _reset?.cancel();
    setState(() {
      _reset = Timer(widget.feedback, () {
        if (mounted) setState(() {});
      });
    });
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Copied to clipboard',
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _copied ? 'Copied' : widget.tooltip,
    iconSize: widget.iconSize,
    visualDensity: VisualDensity.compact,
    icon: Icon(_copied ? Icons.check : widget.icon),
    onPressed: _copy,
  );
}

/// A one-line read-only value with a [CopyButton] on the right of the
/// field (a session ID, a directory path). The text stays on one line and
/// scrolls sideways; the button copies the whole value.
class CopyableField extends StatefulWidget {
  /// Creates a [CopyableField] showing [text].
  const CopyableField({
    super.key,
    required this.text,
    this.tooltip = 'Copy',
    this.icon,
    this.caption,
  });

  /// The value shown and copied.
  final String text;

  /// The copy button's tooltip.
  final String tooltip;

  /// An icon at the start of the field; none when null.
  final IconData? icon;

  /// A short note under the field; none when null.
  final String? caption;

  @override
  State<CopyableField> createState() => _CopyableFieldState();
}

class _CopyableFieldState extends State<CopyableField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(CopyableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.text) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(
      controller: _controller,
      readOnly: true,
      maxLines: 1,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontFamily: 'monospace'),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 18),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 36,
        ),
        helperText: widget.caption,
        suffixIcon: CopyButton(
          text: () => widget.text,
          tooltip: widget.tooltip,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 36,
        ),
      ),
    ),
  );
}
