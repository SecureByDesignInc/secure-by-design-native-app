import 'package:flutter_test/flutter_test.dart';
import 'package:secure_by_design_app/data/account.dart';

class FakeAccountTransport implements AccountTransport {
  final calls = <Map<String, Object?>>[];
  bool failSignIn = false;
  bool failSignOut = false;
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
}
