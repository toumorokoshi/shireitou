/// Pure checks and messages for WebSocket connection problems: host URLs
/// typed as `http(s)://`, mixed content on the web, and handshake errors
/// (AHP-001, AHP-002). See the spec's "Web transport" section.
library;

/// A connection failure explained for the user.
class ConnectionProblem implements Exception {
  /// Creates a [ConnectionProblem] with a user-facing [message] and the
  /// underlying [cause], if any.
  const ConnectionProblem(this.message, [this.cause]);

  /// What went wrong and what to try.
  final String message;

  /// The error this explains.
  final Object? cause;

  @override
  String toString() => message;
}

/// Parses a host URL the user typed. `http://` becomes `ws://` and
/// `https://` becomes `wss://` (a tunnel or reverse proxy URL copied from
/// a browser), and a URL without a scheme gets `ws://`.
Uri normalizeHostUri(String text) {
  final trimmed = text.trim();
  final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)
      ? trimmed
      : 'ws://$trimmed';
  final uri = Uri.parse(withScheme);
  return switch (uri.scheme.toLowerCase()) {
    'http' => uri.replace(scheme: 'ws'),
    'https' => uri.replace(scheme: 'wss'),
    _ => uri,
  };
}

/// Whether [host] names this machine: `localhost` (and `*.localhost`),
/// `127.0.0.0/8` or `::1`. Browsers treat these as potentially
/// trustworthy, so a secure page may open `ws://` to them.
bool isLoopbackHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h.endsWith('.localhost')) return true;
  if (h == '::1' || h == '[::1]') return true;
  final parts = h.split('.');
  return parts.length == 4 &&
      parts.first == '127' &&
      parts.every((p) {
        final n = int.tryParse(p);
        return n != null && n >= 0 && n < 256;
      });
}

/// Why connecting to [host] cannot work before trying, or null.
///
/// [page] is the page the app is served from on the web (null on native
/// platforms). A page loaded over `https` may not open an unencrypted
/// `ws://` socket to another machine (mixed content); browsers block it
/// without telling the page why.
String? transportProblem(Uri host, {Uri? page}) {
  if (host.scheme != 'ws' && host.scheme != 'wss') {
    return 'Host URLs start with ws:// or wss:// (got "${host.scheme}://").';
  }
  if (page != null &&
      page.scheme == 'https' &&
      host.scheme == 'ws' &&
      !isLoopbackHost(host.host)) {
    return 'This page was loaded over https, so the browser blocks the '
        'unencrypted ws:// connection to ${host.host}. Use a wss:// URL '
        '(a TLS reverse proxy or a tunnel in front of the host), or open '
        'the app over http or as the desktop app.';
  }
  return null;
}

/// The HTTP status of a refused WebSocket upgrade in [text] (as `dart:io`
/// reports it: "... was not upgraded to websocket, HTTP status code: 403").
int? upgradeStatusOf(String text) =>
    switch (RegExp(r'HTTP status code: (\d{3})').firstMatch(text)) {
      final match? => int.parse(match.group(1)!),
      null => null,
    };

/// A user-facing explanation of [error], raised while opening a WebSocket
/// to [host]. [web] says whether the browser's `WebSocket` was used:
/// browsers report every failed handshake the same way (no status, no
/// reason), so the message lists the likely causes instead.
String describeTransportError(Object error, Uri host, {required bool web}) {
  final text = '$error';
  final address = host.hasPort ? '${host.host}:${host.port}' : host.host;
  if (web) {
    return 'Could not open a WebSocket to $address. Browsers do not say '
        'why; check that the host is running and listens on an address '
        'this device can reach (pi and VS Code listen on 127.0.0.1 unless '
        'told otherwise), that the token is right, that a wss:// host has '
        'a certificate this browser trusts, and that the host accepts '
        'connections from this page\'s origin.';
  }
  switch (upgradeStatusOf(text)) {
    case 401 || 403:
      return 'The host refused the connection (HTTP ${upgradeStatusOf(text)}): '
          'the token is missing or wrong, or the host does not accept this '
          'client.';
    case final status?:
      return 'The host answered HTTP $status instead of opening a '
          'WebSocket. Check the URL (a proxy may need a path).';
    case null:
      break;
  }
  if (text.contains('HandshakeException') ||
      text.contains('CERTIFICATE_VERIFY_FAILED') ||
      text.contains('TlsException')) {
    return 'The TLS handshake with $address failed: the host\'s '
        'certificate is not trusted, or the host does not speak TLS (try '
        'ws:// instead of wss://).';
  }
  if (text.contains('Connection refused')) {
    return 'Nothing is listening on $address. Is the host running, and '
        'listening on this address rather than 127.0.0.1 only?';
  }
  if (text.contains('Failed host lookup')) {
    return 'Could not find the host "${host.host}".';
  }
  if (text.contains('timed out')) {
    return 'Connecting to $address timed out.';
  }
  return 'Could not connect to $address: $text';
}
