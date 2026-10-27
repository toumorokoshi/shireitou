/// Right-clicking a link (AV-075): a dialog shows the URL with "Copy
/// link" and "Open link", for markdown links in replies and for the
/// app's link buttons and chips.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../files/file_paths.dart';
import '../files/open_file_store.dart';

/// Opens [url] in the browser, or does nothing when it does not parse.
void openLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}

/// Receives the URL while [linkHref] reads a link.
ValueChanged<String>? _readingHref;

/// Opens [url], or hands it to [linkHref] while it reads a link. Link
/// spans whose recognizer calls this report their URL to [linkHref]. With
/// [openFile], a link to a file ([fileReferenceOfHref]) opens it in the
/// file viewer (AV-106); `#anchors` do nothing.
void followLink(String url, {OpenFile? openFile}) {
  if (_readingHref case final read?) {
    read(url);
  } else if (openFile != null && fileReferenceOfHref(url) != null) {
    openFile(fileReferenceOfHref(url)!);
  } else if (!url.trim().startsWith('#')) {
    openLink(url);
  }
}

/// The text a link to [url] shows in [showLinkDialog] and copies: the
/// path of a link the app made for a file path ([filePathHref]), else
/// [url].
String linkText(String url) => url.startsWith(filePathHrefPrefix)
    ? url.substring(filePathHrefPrefix.length)
    : url;

/// The URL [link] opens, read by running its tap while [followLink]
/// reports instead of opening (the markdown package keeps a link's URL
/// only in its recognizer's tap); null when the tap does not follow a
/// link.
String? linkHref(TapGestureRecognizer link) {
  String? href;
  _readingHref = (url) => href = url;
  try {
    link.onTap?.call();
  } finally {
    _readingHref = null;
  }
  return href;
}

/// Shows [url] in a dialog that copies it ("Copy link", then a "Link
/// copied" snackbar) or opens it ("Open link"). A link to a file, below a
/// [FileLinkScope], shows its path with "Copy path" and "Open file".
Future<void> showLinkDialog(BuildContext context, String url) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final openFile = FileLinkScope.maybeOf(context);
  final file = openFile != null && fileReferenceOfHref(url) != null;
  final text = linkText(url);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(file ? 'File' : 'Link'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SelectableText(text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            followLink(url, openFile: openFile);
          },
          child: Text(file ? 'Open file' : 'Open link'),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () async {
            Navigator.of(context).pop();
            await Clipboard.setData(ClipboardData(text: text));
            messenger?.showSnackBar(
              SnackBar(content: Text(file ? 'Path copied' : 'Link copied')),
            );
          },
          child: Text(file ? 'Copy path' : 'Copy link'),
        ),
      ],
    ),
  );
}

/// [child] (a link button or chip) with [showLinkDialog] for [url] on
/// right-click.
class LinkContextMenu extends StatelessWidget {
  /// Creates a [LinkContextMenu] for [url] around [child].
  const LinkContextMenu({super.key, required this.url, required this.child});

  /// The link's URL.
  final String url;

  /// The link.
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onSecondaryTap: () => unawaited(showLinkDialog(context, url)),
    child: child,
  );
}

/// The tap recognizer of the link text span under [global] in [box]'s
/// subtree, or null.
TapGestureRecognizer? linkRecognizerAt(RenderBox box, Offset global) {
  final result = BoxHitTestResult();
  box.hitTest(result, position: box.globalToLocal(global));
  for (final entry in result.path) {
    if (entry.target case TextSpan(
      recognizer: final TapGestureRecognizer recognizer,
    )) {
      return recognizer;
    }
  }
  return null;
}

/// Right-clicks on the link spans in [child] (rich text whose links have
/// [TapGestureRecognizer]s, such as a `MarkdownBody`): [onLink] gets the
/// link's recognizer. Right-clicks elsewhere are left to the enclosing
/// selection's context menu; on a link this wins over it.
class LinkSecondaryTap extends StatelessWidget {
  /// Creates a [LinkSecondaryTap] around [child].
  const LinkSecondaryTap({
    super.key,
    required this.onLink,
    required this.child,
  });

  /// Called with the right-clicked link's recognizer.
  final ValueChanged<TapGestureRecognizer> onLink;

  /// The rich text.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    TapGestureRecognizer? at(Offset global) =>
        switch (context.findRenderObject()) {
          final RenderBox box when box.hasSize => linkRecognizerAt(box, global),
          _ => null,
        };
    return RawGestureDetector(
      gestures: {
        _LinkSecondaryTapRecognizer:
            GestureRecognizerFactoryWithHandlers<_LinkSecondaryTapRecognizer>(
              () => _LinkSecondaryTapRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..isOverLink = ((global) => at(global) != null)
                ..onSecondaryTapUp = (details) {
                  if (at(details.globalPosition) case final link?) {
                    onLink(link);
                  }
                },
            ),
      },
      child: child,
    );
  }
}

/// A secondary tap that only takes pointers over a link, and claims them
/// at once so the selection's right-click menu does not also open.
class _LinkSecondaryTapRecognizer extends TapGestureRecognizer {
  _LinkSecondaryTapRecognizer({super.debugOwner});

  bool Function(Offset global) isOverLink = (_) => false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      event.buttons == kSecondaryButton &&
      super.isPointerAllowed(event) &&
      isOverLink(event.position);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
