/// Rich copy and paste in the browser: using `navigator.clipboard`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

web.Blob _blob(String data, String type) =>
    web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: type));

/// Writes [text] and [html]; throws where the browser refuses.
Future<bool> writeRichClipboard(String text, String html) async {
  final items = JSObject()
    ..['text/plain'] = _blob(text, 'text/plain')
    ..['text/html'] = _blob(html, 'text/html');
  await web.window.navigator.clipboard
      .write([web.ClipboardItem(items)].toJS)
      .toDart;
  return true;
}

/// Reads HTML from the clipboard if available; null if none or refused.
Future<String?> readRichClipboardHtml() async {
  try {
    final items = await web.window.navigator.clipboard.read().toDart;
    final length = items.length;
    for (var i = 0; i < length; i++) {
      final item = items[i];
      final types = item.types.toDart;
      for (var t = 0; t < types.length; t++) {
        if (types[t].toDart == 'text/html') {
          final blob = await item.getType('text/html').toDart;
          final text = await blob.text().toDart;
          return text.toDart;
        }
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
