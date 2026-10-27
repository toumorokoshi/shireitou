/// The web cannot run `ssh`; the file viewer reads with `resourceRead`.
library;

import 'dart:typed_data';

/// Throws: browsers cannot start processes.
Future<Uint8List> readFileOverSsh(
  String host,
  String path, {
  required int maxBytes,
}) => throw UnsupportedError('Browsers cannot start processes.');
