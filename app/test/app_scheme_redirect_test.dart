import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/auth/app_scheme_redirect.dart';

void main() {
  test('the redirect URI is the app scheme', () {
    expect(
      appSchemeRedirectUri.toString(),
      'dev.shireitou.shireitou:/oauth/callback',
    );
  });

  test('the platform result completes the latest receiver', () async {
    final opened = <(Uri, String)>[];
    final browser = appSchemeBrowser(({required url, required scheme}) async {
      opened.add((url, scheme));
      return 'dev.shireitou.shireitou:/oauth/callback?code=c&state=s';
    });
    final receiver = await browser.receiver();
    expect(receiver.redirectUri, appSchemeRedirectUri);
    await browser.open(Uri.parse('https://auth.example/authorize?x=1'));
    final redirect = await receiver.redirect;
    expect(redirect.queryParameters, {'code': 'c', 'state': 's'});
    expect(opened.single.$1.host, 'auth.example');
    expect(opened.single.$2, appUrlScheme);
  });

  test('a cancelled sign-in fails the redirect', () async {
    final browser = appSchemeBrowser(
      ({required url, required scheme}) async =>
          throw PlatformException(code: 'cancelled'),
    );
    final receiver = await browser.receiver();
    await browser.open(Uri.parse('https://auth.example/authorize'));
    await expectLater(
      receiver.redirect,
      throwsA(
        isA<OAuthException>().having((e) => e.error, 'error', 'cancelled'),
      ),
    );
  });

  test('no URL back also counts as cancelled', () async {
    final browser = appSchemeBrowser(
      ({required url, required scheme}) async => null,
    );
    final receiver = await browser.receiver();
    await browser.open(Uri.parse('https://auth.example/authorize'));
    await expectLater(receiver.redirect, throwsA(isA<OAuthException>()));
  });

  test('closing the receiver ends a pending sign-in', () async {
    final receiver = AppSchemeRedirectReceiver();
    final redirect = expectLater(
      receiver.redirect,
      throwsA(isA<OAuthException>()),
    );
    await receiver.close();
    await redirect;
  });
}
