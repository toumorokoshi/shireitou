/// The sign-in dialog for a protected resource (AHP-060 to AHP-062):
/// sign in with the browser (OAuth with PKCE) when the resource names an
/// authorization server, or paste an access token.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../host_connection.dart';

/// Signs in for a challenge, showing the dialog; used by "Sign in"
/// buttons.
typedef SignIn = Future<void> Function(AuthChallenge challenge);

/// The navigator sign-in prompts open on when no button asked for them
/// (`auth/required`, `-32007`).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// What the dialog says about [challenge].
String signInMessage(AuthChallenge challenge) =>
    challenge.description ??
    (challenge.expired
        ? 'Your sign-in to ${challenge.name} expired. Sign in again to '
              'continue.'
        : '${challenge.name} needs you to sign in.');

/// Asks the user to sign in for [challenge]; [browserSignIn] runs the
/// OAuth flow. Returns the token, or null when they cancel.
Future<ResourceToken?> showSignInDialog(
  BuildContext context,
  AuthChallenge challenge, {
  required Future<ResourceToken> Function(AuthChallenge challenge)
  browserSignIn,
}) => showDialog<ResourceToken>(
  context: context,
  builder: (context) =>
      SignInDialog(challenge: challenge, browserSignIn: browserSignIn),
);

/// Shows the dialog for [challenge] and pushes the token to [connection]'s
/// host. Shows a snackbar when sign-in fails or the host refuses the
/// token.
Future<void> signInFromUi(
  BuildContext context,
  HostConnection connection,
  AuthChallenge challenge,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final token = await showSignInDialog(
    context,
    challenge,
    browserSignIn: connection.browserSignIn,
  );
  if (token == null) return;
  try {
    await connection.pushToken(challenge.resource.resource, token);
  } on Object catch (error) {
    messenger?.showSnackBar(SnackBar(content: Text('Sign-in failed: $error')));
  }
}

/// Shows the dialog on [rootNavigatorKey] for a sign-in nobody clicked
/// for; null when no navigator is mounted.
Future<ResourceToken?> promptSignIn(
  AuthChallenge challenge, {
  required Future<ResourceToken> Function(AuthChallenge challenge)
  browserSignIn,
}) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return null;
  return showSignInDialog(context, challenge, browserSignIn: browserSignIn);
}

/// The dialog: "Sign in with browser", or an access token to paste.
class SignInDialog extends StatefulWidget {
  /// Creates a [SignInDialog].
  const SignInDialog({
    super.key,
    required this.challenge,
    required this.browserSignIn,
  });

  /// What to sign in to.
  final AuthChallenge challenge;

  /// Runs the browser sign-in.
  final Future<ResourceToken> Function(AuthChallenge challenge) browserSignIn;

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _token = TextEditingController();
  bool _waiting = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _useBrowser() async {
    setState(() {
      _waiting = true;
      _error = null;
    });
    try {
      final token = await widget.browserSignIn(widget.challenge);
      if (mounted) Navigator.pop(context, token);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _waiting = false;
          _error = 'Sign-in failed: $error';
        });
      }
    }
  }

  void _usePasted() {
    final text = _token.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(
      context,
      ResourceToken(token: text, obtainedAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final resource = challenge.resource;
    final docs = resource.resourceDocumentation;
    final browser = canSignInWithBrowser(resource);
    final scopes = scopesToRequest(challenge.requiredScopes, resource);
    final theme = Theme.of(context);
    final paste = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paste an access token for ${resource.resource}.'),
        if (docs != null)
          TextButton(
            onPressed: () => launchUrl(Uri.parse(docs)),
            child: const Text('How to get a token'),
          ),
        TextField(
          controller: _token,
          autofocus: !browser,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Access token'),
          onSubmitted: (_) => _usePasted(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: browser
              ? OutlinedButton(
                  onPressed: _usePasted,
                  child: const Text('Use token'),
                )
              : FilledButton(
                  onPressed: _usePasted,
                  child: const Text('Use token'),
                ),
        ),
      ],
    );
    return AlertDialog(
      title: Text('Sign in to ${challenge.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(signInMessage(challenge)),
            if (scopes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Access requested: ${scopes.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (browser) ...[
              const SizedBox(height: 16),
              if (_waiting)
                const Row(
                  children: [
                    SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Finish signing in in your browser…')),
                  ],
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Sign in with browser'),
                  onPressed: _useBrowser,
                ),
              if (_error case final error?) ...[
                const SizedBox(height: 8),
                Text(error, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Use an access token instead'),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [paste],
              ),
            ] else ...[
              const SizedBox(height: 8),
              paste,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
