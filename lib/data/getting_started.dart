import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding.dart';

enum GettingStartedMessage { welcome, resources, feedback }

/// Local encouragement only: no account identity, email, push, or analytics.
class GettingStartedStore extends ChangeNotifier {
  GettingStartedStore(this._preferences, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _started = DateTime.tryParse(
          _preferences.getString('sbd.guidance.started.v1') ?? '',
        )?.toUtc() ??
        _now().toUtc();
    _dismissed =
        (_preferences.getStringList('sbd.guidance.dismissed.v1') ?? []).toSet();
    _enabled = _preferences.getBool('sbd.guidance.enabled.v1') ?? true;
    // An upgrade must not interrupt returning learners with a new first run.
    _existingInstall = _preferences.containsKey('sbd.guidance.started.v1') ||
        _preferences.containsKey('sbd.state.v1') ||
        _dismissed.isNotEmpty;
    try {
      final value = jsonDecode(_preferences.getString(_onboardingKey) ?? '{}');
      if (value is Map) {
        _welcomeFinished = value['finished'] == true;
        _profile = OnboardingProfile.fromJson(value['profile']);
      }
    } catch (_) {/* A malformed optional profile must not block learning. */}
  }

  final SharedPreferences _preferences;
  final DateTime Function() _now;
  late final DateTime _started;
  late Set<String> _dismissed;
  late bool _enabled;
  bool _disposed = false;
  bool busy = false;
  bool get enabled => _enabled;
  static const _onboardingKey = 'sbd.onboarding.v1';
  late final bool _existingInstall;
  bool _welcomeFinished = false;
  OnboardingProfile? _profile;
  OnboardingProfile? get profile => _profile;
  bool get welcomeFinished => _welcomeFinished;
  bool get shouldPresentWelcome =>
      _enabled && !_existingInstall && !_welcomeFinished;

  Future<void> finishWelcome({OnboardingProfile? profile}) async {
    if (busy || _disposed) return;
    busy = true;
    _notify();
    try {
      if (!await _preferences.setString(
          _onboardingKey,
          jsonEncode({
            'finished': true,
            'profile': profile?.toJson(),
          }))) {
        throw StateError('Could not save your learning plan.');
      }
      _profile = profile;
      _welcomeFinished = true;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> initialize() async {
    if (_preferences.containsKey('sbd.guidance.started.v1')) return;
    // Optional guidance must never prevent offline lessons from opening.
    try {
      await _preferences.setString(
          'sbd.guidance.started.v1', _started.toIso8601String());
    } catch (_) {/* Continue with this session's start time. */}
  }

  GettingStartedMessage? get next {
    if (!_enabled) return null;
    final age = _now().toUtc().difference(_started);
    for (final message in GettingStartedMessage.values) {
      if (message == GettingStartedMessage.welcome && _welcomeFinished) {
        continue;
      }
      final days = switch (message) {
        GettingStartedMessage.welcome => 0,
        GettingStartedMessage.resources => 3,
        GettingStartedMessage.feedback => 7,
      };
      if (!_dismissed.contains(message.name) &&
          (days == 0 || age >= Duration(days: days))) {
        return message;
      }
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> dismiss(GettingStartedMessage message) async {
    if (busy || _disposed || _dismissed.contains(message.name)) return;
    busy = true;
    _notify();
    try {
      final updated = {..._dismissed, message.name};
      if (!await _preferences.setStringList(
          'sbd.guidance.dismissed.v1', updated.toList())) {
        throw StateError('Could not save dismissal.');
      }
      _dismissed = updated;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (busy || _disposed || _enabled == value) return;
    busy = true;
    _notify();
    try {
      if (!await _preferences.setBool('sbd.guidance.enabled.v1', value)) {
        throw StateError('Could not save preference.');
      }
      _enabled = value;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
