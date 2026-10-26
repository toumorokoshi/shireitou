/// A copy-to-clipboard icon button with copied feedback (AV-061, AV-071).
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
    this.tooltip = 'Copy',
    this.iconSize = 16,
    this.feedback = const Duration(milliseconds: 1200),
  });

  /// The text copied, read when pressed.
  final String Function() text;

  /// The HTML copied along with the text, made from it; null copies only
  /// the text.
  final String Function(String text)? html;

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
    icon: Icon(_copied ? Icons.check : Icons.copy),
    onPressed: _copy,
  );
}
