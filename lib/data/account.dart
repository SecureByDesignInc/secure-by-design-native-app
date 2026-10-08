import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AccountFailure implements Exception {
  const AccountFailure(this.message, {this.status = 0});
  final String message;
  final int status;
}

abstract interface class AccountTransport {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object>? body,
    String? token,
  });
}

class NativeAccountTransport implements AccountTransport {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object>? body,
    String? token,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.openUrl(
          method,
          Uri.https('securebydesigninc.com', path),
        );
        request.followRedirects = false;
        request.headers.set('x-sbd-client', 'native-v1');
        request.headers.contentType = ContentType.json;
        if (token != null) {
          request.headers.set('authorization', 'Bearer $token');
        }
        if (body != null) request.write(jsonEncode(body));
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 16384) {
            throw const AccountFailure(
              'The account service could not respond. Try again.',
            );
          }
          bytes.addAll(chunk);
        }
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) {
          throw const AccountFailure(
            'The account service could not respond. Try again.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final message = decoded['error'];
          throw AccountFailure(
            message is String && message.length <= 512
                ? message
                : 'The account service is unavailable. Try again.',
            status: response.statusCode,
          );
        }
        return decoded;
      })()
          .timeout(const Duration(seconds: 15));
    } on AccountFailure {
      rethrow;
    } catch (_) {
      throw const AccountFailure(
        'Could not connect. Check your internet connection and try again.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

/// Opens [url] in the system's secure sign-in browser and returns the URL it
/// redirected to (with [callbackScheme]).
typedef BrowserAuthenticator = Future<String> Function(
    Uri url, String callbackScheme);

Future<String> systemBrowserSignIn(Uri url, String callbackScheme) =>
    FlutterWebAuth2.authenticate(
        url: url.toString(), callbackUrlScheme: callbackScheme);

/// This preview keeps the session in memory only. No password, token, or email
/// is written to preferences, analytics, crash logs, or an exported progress file.
class AccountStore extends ChangeNotifier {
  AccountStore({AccountTransport? transport, BrowserAuthenticator? browser})
      : _transport = transport ?? NativeAccountTransport(),
        _browser = browser ?? systemBrowserSignIn;
  final AccountTransport _transport;
  final BrowserAuthenticator _browser;
  static const callbackScheme = 'securebydesign';
  String? _token;
  String? email;
  String? accountId;
  String? error;
  bool busy = false;
  bool _disposed = false;
  Timer? _expiry;
  bool get signedIn => _token != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    _expiry?.cancel();
    _token = null;
    email = null;
    accountId = null;
  }

  Future<void> signIn(String emailAddress, String password) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      final data = await _transport.request(
        'POST',
        '/api/native-auth/signin',
        body: {'email': emailAddress.trim(), 'password': password},
      );
      if (_disposed) return;
      _accept(data);
    } on AccountFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Sign-in is temporarily unavailable. Try again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _accept(Map<String, dynamic> data) {
    final token = data['token'];
    final expiry = DateTime.tryParse(data['expiresAt']?.toString() ?? '');
    final user = data['user'];
    if (token is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(token) ||
        expiry == null ||
        !expiry.isAfter(DateTime.now()) ||
        user is! Map ||
        user['email'] is! String) {
      throw const AccountFailure(
        'The sign-in response was incomplete. Try again.',
      );
    }
    _clear();
    _token = token;
    email = user['email'] as String;
    accountId = user['id'] is String ? user['id'] as String : null;
    _expiry = Timer(expiry.difference(DateTime.now()), () {
      _clear();
      error = 'Your session ended. Sign in again when you are ready.';
      _notify();
    });
  }

  /// Signs in with Apple, Google, Microsoft, a passkey, or a website password.
  /// The website returns a one-time code; only this app holds the PKCE
  /// verifier that turns it into a session.
  Future<void> signInWithBrowser() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      final random = Random.secure();
      final verifier = base64Url
          .encode(List<int>.generate(48, (_) => random.nextInt(256)))
          .replaceAll('=', '');
      final challenge = base64Url
          .encode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');
      final result = await _browser(
        Uri.https('securebydesigninc.com', '/app-sign-in',
            {'challenge': challenge}),
        callbackScheme,
      );
      if (_disposed) return;
      final returned = Uri.tryParse(result);
      final code = returned?.queryParameters['code'];
      if (returned == null ||
          returned.scheme != callbackScheme ||
          returned.host != 'auth' ||
          code == null ||
          code.isEmpty) {
        throw const AccountFailure('Sign-in did not finish. Try again.');
      }
      final data = await _transport.request(
        'POST',
        '/api/native-auth/exchange',
        body: {'code': code, 'verifier': verifier},
      );
      if (_disposed) return;
      _accept(data);
    } on PlatformException catch (failure) {
      // Closing the sign-in sheet is not an error.
      if (failure.code != 'CANCELED') {
        error = 'Sign-in did not finish. Try again.';
      }
    } on AccountFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Sign-in is temporarily unavailable. Try again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  /// Permanently deletes the signed-in account and its data on the server.
  Future<bool> deleteAccount() async {
    final token = _token;
    if (token == null || busy || _disposed) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await _transport.request(
        'POST',
        '/api/native-auth/delete-account',
        token: token,
        body: {'confirm': 'DELETE'},
      );
      _clear();
      return true;
    } on AccountFailure catch (failure) {
      error = failure.message;
      return false;
    } catch (_) {
      error = 'Your account could not be deleted. Try again.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<Map<String, dynamic>> syncProgress(List<Map<String, Object>> records,
      List<Map<String, Object>> bookmarks) async {
    final token = _token;
    if (token == null) {
      throw const AccountFailure('Sign in to sync your progress.');
    }
    try {
      return await _transport.request('POST', '/api/native-progress',
          token: token, body: {'records': records, 'bookmarks': bookmarks});
    } on AccountFailure catch (failure) {
      if (failure.status == 401 && token == _token) {
        _clear();
        _notify();
      }
      rethrow;
    }
  }

  Future<List<dynamic>> syncActivity(List<Map<String, Object>> activity) async {
    final token = _token, owner = accountId;
    if (token == null || owner == null) {
      throw const AccountFailure('Sign in to sync your activity.');
    }
    Future<Map<String, dynamic>> page(
        List<Map<String, Object>> rows, String after) async {
      if (token != _token || owner != accountId) {
        throw const AccountFailure('Your account changed.');
      }
      try {
        final data = await _transport.request('POST', '/api/native-activity',
            token: token, body: {'activity': rows, 'after': after});
        if (data['accountId'] != owner ||
            data['activity'] is! List ||
            (data['nextCursor'] != null && data['nextCursor'] is! String)) {
          throw const FormatException('Invalid activity response');
        }
        return data;
      } on AccountFailure catch (failure) {
        if (failure.status == 401 && token == _token) {
          _clear();
          _notify();
        }
        rethrow;
      }
    }

    var offset = 0;
    while (activity.length - offset > 12) {
      await page(activity.sublist(offset, offset + 12), '');
      offset += 12;
    }
    var data = await page(activity.sublist(offset), '');
    final result = <dynamic>[...data['activity'] as List];
    String previous = '';
    while (data['nextCursor'] != null) {
      final cursor = data['nextCursor'] as String;
      if (cursor.compareTo(previous) <= 0) {
        throw const FormatException('Invalid activity cursor');
      }
      previous = cursor;
      data = await page([], cursor);
      result.addAll(data['activity'] as List);
    }
    return result;
  }

  Future<void> signOut() async {
    if (busy || _disposed) return;
    final token = _token;
    _clear();
    busy = true;
    error = null;
    _notify();
    try {
      if (token != null) {
        await _transport.request(
          'POST',
          '/api/native-auth/signout',
          token: token,
        );
      }
    } catch (_) {
      error =
          'Signed out on this device. The server session could not be closed and will expire within 12 hours.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _clear();
    super.dispose();
  }
}
