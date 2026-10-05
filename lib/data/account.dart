import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

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

/// This preview keeps the session in memory only. No password, token, or email
/// is written to preferences, analytics, crash logs, or an exported progress file.
class AccountStore extends ChangeNotifier {
  AccountStore({AccountTransport? transport})
      : _transport = transport ?? NativeAccountTransport();
  final AccountTransport _transport;
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
    } on AccountFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Sign-in is temporarily unavailable. Try again.';
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
