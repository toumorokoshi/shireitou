/// WebSocket transport for native platforms (`dart:io`).
library;

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol.dart';

/// Native platforms can set handshake headers, so the token goes in both
/// the header and the query (AHP-002).
const defaultTokenTransport = TokenTransport.queryAndHeader;

/// Opens a WebSocket to [uri], sending [headers] in the upgrade request.
WebSocketChannel openWebSocket(Uri uri, Map<String, String> headers) =>
    IOWebSocketChannel.connect(uri, headers: headers.isEmpty ? null : headers);

/// Whether sockets are browser `WebSocket`s.
const isWebTransport = false;

/// The page the app was loaded from; null on native platforms.
Uri? pageUri() => null;
