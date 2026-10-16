/// The redirect receiver of the web app: `oauth_callback.html`, a page of
/// the app's own origin, posts the redirect URL on a `BroadcastChannel`.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:ahp_client/ahp_client.dart';
import 'package:web/web.dart' as web;

/// The channel `web/oauth_callback.html` posts to.
const oauthChannelName = 'shireitou-oauth';

/// Starts listening for `oauth_callback.html`'s message.
Future<RedirectReceiver> startRedirectReceiver() async =>
    _BroadcastRedirectReceiver();

final class _BroadcastRedirectReceiver implements RedirectReceiver {
  _BroadcastRedirectReceiver() {
    _channel.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>() && !_redirect.isCompleted) {
        _redirect.complete(Uri.parse((data! as JSString).toDart));
      }
    }).toJS;
  }

  final _channel = web.BroadcastChannel(oauthChannelName);
  final _redirect = Completer<Uri>();

  @override
  Uri get redirectUri => Uri.base.resolve('oauth_callback.html');

  @override
  Future<Uri> get redirect => _redirect.future;

  @override
  Future<void> close() async => _channel.close();
}
