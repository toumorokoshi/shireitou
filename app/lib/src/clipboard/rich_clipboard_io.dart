/// Rich copy on desktop and mobile: through the runner's channel.
library;

import 'rich_clipboard.dart';

/// Writes [text] and [html]; false when HTML cannot be written.
Future<bool> writeRichClipboard(String text, String html) =>
    writeClipboardChannel(text, html);
