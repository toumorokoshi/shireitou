/// WebSocket transport for the web (browser `WebSocket`).
library;

import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol.dart';

/// Browsers cannot set headers on the upgrade request, so the token stays
/// in the `tkn` query parameter (AHP-002).
const defaultTokenTransport = TokenTransport.query;

/// Opens a WebSocket to [uri]. [headers] cannot be sent from a browser and
/// must be empty; [handshakeFor] with [TokenTransport.query] ensures that.
WebSocketChannel openWebSocket(Uri uri, Map<String, String> headers) {
  assert(headers.isEmpty, 'browsers cannot send WebSocket headers');
  return WebSocketChannel.connect(uri);
}
