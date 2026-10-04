import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/account.dart';

class FakeAccountTransport implements AccountTransport {
  final calls = <Map<String, Object?>>[];
  bool failSignIn = false;
  bool failSignOut = false;
  int emailStatus = 200;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object>? body,
    String? token,
  }) async {
    calls.add({'method': method, 'path': path, 'body': body, 'token': token});
    if (path.endsWith('/signin')) {
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
    if (path.endsWith('/signout')) {
      if (failSignOut) throw const AccountFailure('Offline');
      return {'signedOut': true};
    }
    if (emailStatus != 200) {
      throw AccountFailure('Email unavailable', status: emailStatus);
    }
    return {
      'enrollment': method == 'GET' ? 'not_enrolled' : 'accepted',
      'consentText':
          'Email me three getting-started messages. I can unsubscribe at any time.',
      'consentVersion': 'app-onboarding-v1',
    };
  }
}

void main() {
  test(
    'sign-in alone never subscribes; opt-in sends no supplied identity',
    () async {
      final transport = FakeAccountTransport();
      final account = AccountStore(transport: transport);
      addTearDown(account.dispose);
      await account.signIn('reader@example.invalid', 'test password');
      expect(account.signedIn, true);
      expect(account.enrollment, 'not_enrolled');
      await account.optIn(consent: false);
      expect(transport.calls.length, 2);
      await account.optIn(consent: true);
      expect(account.enrollment, 'accepted');
      expect(transport.calls.last['body'], {
        'consent': true,
        'consentVersion': 'app-onboarding-v1',
      });
      await account.optIn(consent: true);
      expect(transport.calls.length, 3);
    },
  );
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
    'email service failure cannot invalidate a successful sign-in',
    () async {
      final transport = FakeAccountTransport()..emailStatus = 503;
      final account = AccountStore(transport: transport);
      addTearDown(account.dispose);
      await account.signIn('reader@example.invalid', 'password');
      expect(account.signedIn, true);
      expect(account.emailAvailable, false);
      await account.optIn(consent: true);
      expect(transport.calls.length, 2);
    },
  );
  test('session revocation clears the identity and email form', () async {
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    addTearDown(account.dispose);
    await account.signIn('reader@example.invalid', 'password');
    transport.emailStatus = 401;
    await account.refreshEmailStatus();
    expect(account.signedIn, false);
    expect(account.email, null);
    expect(account.emailAvailable, false);
  });
  test('failed opt-in is marked for review rather than auto-retried', () async {
    final transport = FakeAccountTransport();
    final account = AccountStore(transport: transport);
    addTearDown(account.dispose);
    await account.signIn('reader@example.invalid', 'password');
    transport.emailStatus = 502;
    await account.optIn(consent: true);
    expect(account.enrollment, 'review_required');
    final count = transport.calls.length;
    await account.optIn(consent: true);
    expect(transport.calls.length, count);
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
}
