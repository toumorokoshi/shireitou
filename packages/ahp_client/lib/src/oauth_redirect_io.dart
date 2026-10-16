/// The loopback redirect receiver for native apps (RFC 8252 §7.3).
library;

import 'dart:async';
import 'dart:io';

import 'oauth.dart';

/// Receives the browser's redirect on `http://127.0.0.1:<port>/callback`,
/// a loopback HTTP server on a random port (RFC 8252 §7.3), and answers
/// the browser with a page saying it can be closed.
final class LoopbackRedirectReceiver implements RedirectReceiver {
  LoopbackRedirectReceiver._(this._server, this.redirectUri) {
    _server.listen(_onRequest);
  }

  /// Starts listening on the IPv4 loopback address.
  static Future<LoopbackRedirectReceiver> start({
    String path = '/callback',
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return LoopbackRedirectReceiver._(
      server,
      Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: path),
    );
  }

  final HttpServer _server;
  final _redirect = Completer<Uri>();

  @override
  final Uri redirectUri;

  @override
  Future<Uri> get redirect => _redirect.future;

  Future<void> _onRequest(HttpRequest request) async {
    final response = request.response;
    if (request.uri.path != redirectUri.path || _redirect.isCompleted) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final failed = request.uri.queryParameters.containsKey('error');
    response.headers.contentType = ContentType.html;
    response.write(
      '<!doctype html><meta charset="utf-8"><title>shireitou</title>'
      '<p>${failed ? 'Sign-in did not finish.' : 'Signed in.'} '
      'You can close this window and return to shireitou.</p>',
    );
    await response.close();
    _redirect.complete(request.requestedUri);
  }

  @override
  Future<void> close() => _server.close(force: true);
}

/// Whether [LoopbackRedirectReceiver] works on this platform.
const loopbackRedirectSupported = true;
