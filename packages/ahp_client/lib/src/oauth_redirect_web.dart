/// No loopback server in a browser: the web app receives the redirect on
/// a page of its own instead (see the app's `oauth_callback.html`).
library;

import 'oauth.dart';

/// Not available on the web; [start] throws [UnsupportedError].
final class LoopbackRedirectReceiver implements RedirectReceiver {
  LoopbackRedirectReceiver._();

  /// Throws [UnsupportedError]: browsers cannot listen on a port.
  static Future<LoopbackRedirectReceiver> start({
    String path = '/callback',
  }) async => throw UnsupportedError('no loopback server in a browser');

  @override
  Uri get redirectUri => throw UnsupportedError('web');

  @override
  Future<Uri> get redirect => throw UnsupportedError('web');

  @override
  Future<void> close() async {}
}

/// Whether [LoopbackRedirectReceiver] works on this platform.
const loopbackRedirectSupported = false;
