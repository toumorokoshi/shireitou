/// The OAuth redirect on iOS and Android (AHP-060): the app's own URL
/// scheme (RFC 8252 §7.1) instead of a loopback server, which iOS can
/// suspend while the browser is in front.
///
/// iOS signs in with `ASWebAuthenticationSession`, Android with the
/// system browser and an intent filter on the scheme; both are in the
/// runners (`ios/Runner/AppDelegate.swift`, `MainActivity.kt`) behind the
/// [webAuthChannel] method channel, which answers `authenticate` with the
/// URL the browser was redirected to.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';

import 'oauth_browser.dart';

/// The app's private-use URL scheme, its bundle and application ID.
const appUrlScheme = 'dev.shireitou.shireitou';

/// The redirect URI registered and sent on iOS and Android.
final appSchemeRedirectUri = Uri.parse('$appUrlScheme:/oauth/callback');

/// The method channel to the runners' sign-in code.
const webAuthChannel = MethodChannel('dev.shireitou.shireitou/web_auth');

/// Asks the platform to open [url] and returns the redirect URL.
typedef WebAuthenticate = Future<String?> Function({
  required Uri url,
  required String scheme,
});

/// [WebAuthenticate] through [webAuthChannel].
Future<String?> platformWebAuthenticate({
  required Uri url,
  required String scheme,
}) => webAuthChannel.invokeMethod<String>('authenticate', {
  'url': '$url',
  'scheme': scheme,
});

/// An [OAuthBrowser] that redirects to [appSchemeRedirectUri]: `open`
/// starts the platform's sign-in with [authenticate] and hands its
/// result to the receiver from the latest `receiver` call.
OAuthBrowser appSchemeBrowser([
  WebAuthenticate authenticate = platformWebAuthenticate,
]) {
  AppSchemeRedirectReceiver? latest;
  return OAuthBrowser(
    receiver: () async => latest = AppSchemeRedirectReceiver(),
    open: (url) async {
      final receiver = latest;
      if (receiver == null) throw StateError('no redirect receiver');
      unawaited(
        authenticate(url: url, scheme: appUrlScheme).then(
          receiver.receive,
          onError: (Object error) => receiver.fail(switch (error) {
            PlatformException(code: 'cancelled') => const OAuthException(
              'cancelled',
              'sign-in was cancelled',
            ),
            PlatformException(:final code, :final message) => OAuthException(
              code,
              message,
            ),
            _ => OAuthException('browser_failed', '$error'),
          }),
        ),
      );
    },
  );
}

/// Receives the redirect [appSchemeBrowser]'s platform sign-in returns.
final class AppSchemeRedirectReceiver implements RedirectReceiver {
  /// Creates a receiver waiting for its redirect.
  AppSchemeRedirectReceiver() {
    // Closed or failed before anyone waits (sign-in failed earlier):
    // not an uncaught error.
    _redirect.future.ignore();
  }

  final _redirect = Completer<Uri>();

  @override
  Uri get redirectUri => appSchemeRedirectUri;

  @override
  Future<Uri> get redirect => _redirect.future;

  /// Completes [redirect] with [url]; a null [url] means the user went
  /// back without signing in.
  void receive(String? url) {
    if (_redirect.isCompleted) return;
    if (url == null) {
      fail(const OAuthException('cancelled', 'sign-in was cancelled'));
    } else {
      _redirect.complete(Uri.parse(url));
    }
  }

  /// Fails [redirect] with [error].
  void fail(OAuthException error) {
    if (!_redirect.isCompleted) _redirect.completeError(error);
  }

  @override
  Future<void> close() async =>
      fail(const OAuthException('closed', 'sign-in was abandoned'));
}
