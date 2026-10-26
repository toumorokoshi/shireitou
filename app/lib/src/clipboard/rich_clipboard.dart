/// Copying HTML along with plain text, so links and formatting survive a
/// paste into a mail, a doc or a chat. Flutter's [Clipboard] only writes
/// plain text: the desktop and mobile runners take `setHtml` on
/// [richClipboardChannel], and the web app writes a `ClipboardItem`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'rich_clipboard_io.dart'
    if (dart.library.js_interop) 'rich_clipboard_web.dart';

final _log = Logger('rich_clipboard');

/// The runners' clipboard channel: `setHtml` with `text` and `html`.
const richClipboardChannel = MethodChannel('dev.shireitou.shireitou/clipboard');

/// Puts [text] and [html] (a fragment) on the clipboard, or only [text]
/// where HTML cannot be written.
Future<void> setRichClipboard({
  required String text,
  required String html,
}) async {
  try {
    if (await writeRichClipboard(text, htmlDocument(html))) return;
  } on Exception catch (error) {
    _log.fine('HTML copy failed, copying plain text: $error');
  }
  await Clipboard.setData(ClipboardData(text: text));
}

/// [fragment] with a UTF-8 charset, which pasting apps otherwise guess.
String htmlDocument(String fragment) => '<meta charset="utf-8">$fragment';

/// Writes [text] and [html] through [richClipboardChannel]; false when the
/// runner has no handler.
Future<bool> writeClipboardChannel(String text, String html) async {
  try {
    await richClipboardChannel.invokeMethod<void>('setHtml', {
      'text': text,
      'html': defaultTargetPlatform == TargetPlatform.windows
          ? windowsClipboardHtml(html)
          : html,
    });
    return true;
  } on MissingPluginException {
    return false;
  }
}

/// [html] in the Windows "HTML Format" clipboard layout: a header with the
/// UTF-8 byte offsets of the document and of the fragment in it.
String windowsClipboardHtml(String html) {
  const prefix = '<html><body>\r\n<!--StartFragment-->';
  const suffix = '<!--EndFragment-->\r\n</body></html>';
  String offset(int n) => n.toString().padLeft(10, '0');
  String header(int startHtml, int endHtml, int startFrag, int endFrag) =>
      'Version:0.9\r\n'
      'StartHTML:${offset(startHtml)}\r\n'
      'EndHTML:${offset(endHtml)}\r\n'
      'StartFragment:${offset(startFrag)}\r\n'
      'EndFragment:${offset(endFrag)}\r\n';
  final startHtml = header(0, 0, 0, 0).length;
  final startFrag = startHtml + prefix.length;
  final endFrag = startFrag + utf8.encode(html).length;
  final endHtml = endFrag + suffix.length;
  return '${header(startHtml, endHtml, startFrag, endFrag)}'
      '$prefix$html$suffix';
}
