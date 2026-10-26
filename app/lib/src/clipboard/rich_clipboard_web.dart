/// Rich copy in the browser: one `ClipboardItem` with both types.
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
