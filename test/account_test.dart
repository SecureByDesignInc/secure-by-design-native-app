import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/account.dart';

class FakeAccountTransport implements AccountTransport {
  final calls = <Map<String, Object?>>[];
  bool failSignIn = false;
  bool failSignOut = false;
  bool failExchange = false;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object>? body,
    String? token,
  }) async {
    calls.add({'method': method, 'path': path, 'body': body, 'token': token});
    if (path.endsWith('/signin') || path.endsWith('/exchange')) {
      if (failExchange && path.endsWith('/exchange')) {
        throw const AccountFailure(
          'That sign-in link expired. Try again.',
          status: 400,
        );
      }
      if (failSignIn) {
        throw const AccountFailure(
          'Email or password did not match.',
          status: 401,
        );
      }
      return {
        'token': List.filled(64, 'a').join(),
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 12))
            .toUtc()
            .toIso8601String(),
        'user': {'email': 'reader@example.invalid'},
      };
    }
    if (path.endsWith('/delete-account')) return {'deleted': true};
    if (path.endsWith('/signout')) {
      if (failSignOut) throw const AccountFailure('Offline');
      return {'signedOut': true};
    }
    throw StateError('Unexpected account request: $path');
  }
}

void main() {
  test('sign-in never contacts the marketing enrollment service', () async {
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    addTearDown(account.dispose);
    await account.signIn('reader@example.invalid', 'test password');
    expect(account.signedIn, true);
    expect(transport.calls.length, 1);
    expect(transport.calls.single['path'], '/api/native-auth/signin');
  });
  test('wrong password leaves the app signed out', () async {
    final transport = FakeAccountTransport()..failSignIn = true;
    final account = AccountStore(transport: transport);
    addTearDown(account.dispose);
    await account.signIn('reader@example.invalid', 'wrong');
    expect(account.signedIn, false);
    expect(account.error, contains('did not match'));
    expect(transport.calls.length, 1);
  });
  test(
    'offline sign-out clears memory and reports remote revocation failure',
    () async {
      final transport = FakeAccountTransport()..failSignOut = true;
      final account = AccountStore(transport: transport);
      addTearDown(account.dispose);
      await account.signIn('reader@example.invalid', 'password');
      await account.signOut();
      expect(account.signedIn, false);
      expect(account.email, null);
      expect(account.error, contains('12 hours'));
      final other = AccountStore(transport: transport);
      addTearDown(other.dispose);
      expect(other.signedIn, false);
    },
  );
  group('browser sign-in', () {
    test('exchanges the returned code with the PKCE verifier', () async {
      final transport = FakeAccountTransport();
      late Uri opened;
      late String scheme;
      final account = AccountStore(
        transport: transport,
        browser: (url, callbackScheme) async {
          opened = url;
          scheme = callbackScheme;
          return 'securebydesign://auth?code=one-time-code';
        },
      );
      addTearDown(account.dispose);
      await account.signInWithBrowser();
      expect(account.signedIn, true);
      expect(account.error, null);
      expect(scheme, 'securebydesign');
      expect(opened.host, 'securebydesigninc.com');
      expect(opened.path, '/app-sign-in');
      final call = transport.calls.single;
      expect(call['path'], '/api/native-auth/exchange');
      final body = call['body'] as Map<String, Object>;
      expect(body['code'], 'one-time-code');
      final verifier = body['verifier'] as String;
      expect(verifier.length, greaterThanOrEqualTo(43));
      final expected = base64Url
          .encode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');
      expect(opened.queryParameters['challenge'], expected);
    });

    test('a different scheme or host is rejected without an exchange',
        () async {
      for (final returned in [
        'https://evil.example/auth?code=x',
        'securebydesign://other?code=x',
        'securebydesign://auth',
      ]) {
        final transport = FakeAccountTransport();
        final account = AccountStore(
          transport: transport,
          browser: (_, __) async => returned,
        );
        await account.signInWithBrowser();
        expect(account.signedIn, false, reason: returned);
        expect(account.error, contains('did not finish'), reason: returned);
        expect(transport.calls, isEmpty, reason: returned);
        account.dispose();
      }
    });

    test('closing the sign-in sheet is not reported as an error', () async {
      final transport = FakeAccountTransport();
      final account = AccountStore(
        transport: transport,
        browser: (_, __) async =>
            throw PlatformException(code: 'CANCELED', message: 'User canceled'),
      );
      addTearDown(account.dispose);
      await account.signInWithBrowser();
      expect(account.signedIn, false);
      expect(account.error, null);
      expect(account.busy, false);
      expect(transport.calls, isEmpty);
    });

    test('an expired code shows the server message', () async {
      final transport = FakeAccountTransport()..failExchange = true;
      final account = AccountStore(
        transport: transport,
        browser: (_, __) async => 'securebydesign://auth?code=old',
      );
      addTearDown(account.dispose);
      await account.signInWithBrowser();
      expect(account.signedIn, false);
      expect(account.error, contains('expired'));
    });
  });

  test('delete account sends confirmation with the session and signs out',
      () async {
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    addTearDown(account.dispose);
    expect(await account.deleteAccount(), false);
    expect(transport.calls, isEmpty);
    await account.signIn('reader@example.invalid', 'password');
    expect(await account.deleteAccount(), true);
    final call = transport.calls.last;
    expect(call['path'], '/api/native-auth/delete-account');
    expect(call['token'], List.filled(64, 'a').join());
    expect(call['body'], {'confirm': 'DELETE'});
    expect(account.signedIn, false);
    expect(account.email, null);
  });
}
