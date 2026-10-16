/// How the app sends the user to an authorization server and gets the
/// redirect back (AHP-060): the system browser and a loopback server on
/// native platforms, a new tab and `oauth_callback.html` on the web.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'redirect_receiver_io.dart'
    if (dart.library.js_interop) 'redirect_receiver_web.dart';

/// Opens authorization URLs and receives redirects.
class OAuthBrowser {
  /// Creates an [OAuthBrowser].
  const OAuthBrowser({required this.receiver, required this.open});

  /// Starts listening for the redirect.
  final Future<RedirectReceiver> Function() receiver;

  /// Opens the authorization URL for the user.
  final Future<void> Function(Uri url) open;
}

/// Opens [url] in the system browser (a new tab on the web).
Future<void> openInBrowser(Uri url) async {
  final opened = await launchUrl(
    url,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!opened) throw StateError('could not open the browser');
}

/// The platform's [OAuthBrowser]; the fake host tests replace it with one
/// that fetches the URL itself.
final oauthBrowserProvider = Provider<OAuthBrowser>(
  (ref) =>
      const OAuthBrowser(receiver: startRedirectReceiver, open: openInBrowser),
);
