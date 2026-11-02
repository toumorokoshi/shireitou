/// Rich copy and paste on desktop and mobile: through the runner's channel.
library;

import 'package:flutter/services.dart';

import 'rich_clipboard.dart';

/// Writes [text] and [html]; false when HTML cannot be written.
Future<bool> writeRichClipboard(String text, String html) =>
    writeClipboardChannel(text, html);

/// Reads HTML from the runner's channel; null if none or not implemented.
Future<String?> readRichClipboardHtml() async {
  try {
    return await richClipboardChannel.invokeMethod<String>('getHtml');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
