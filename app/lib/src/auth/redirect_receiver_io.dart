/// The redirect receiver of the native apps: a loopback server.
library;

import 'package:ahp_client/ahp_client.dart';

/// Starts a loopback receiver (`http://127.0.0.1:<port>/callback`).
Future<RedirectReceiver> startRedirectReceiver() =>
    LoopbackRedirectReceiver.start();
