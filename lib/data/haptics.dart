import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional device feedback. Call only from an explicit user interaction;
/// loading, account synchronization, and playback must remain silent.
class AppHaptics extends ChangeNotifier {
  AppHaptics(this._preferences)
      : _enabled = _preferences.getBool(preferenceKey) ?? true;

  static const preferenceKey = 'sbd.haptics.enabled.v1';
  final SharedPreferences _preferences;
  bool _enabled;
  bool _changing = false;
  bool _disposed = false;

  bool get enabled => _enabled;
  bool get changing => _changing;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> setEnabled(bool value) async {
    if (_disposed || _changing || value == _enabled) return;
    _changing = true;
    notifyListeners();
    try {
      if (!await _preferences.setBool(preferenceKey, value)) {
        throw StateError('Could not save the haptic feedback preference.');
      }
      _enabled = value;
    } finally {
      _changing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void selectionChanged() => unawaited(_play(HapticFeedback.selectionClick));
  void bookmarkChanged() => unawaited(_play(HapticFeedback.lightImpact));
  void lessonCompleted() =>
      unawaited(_play(HapticFeedback.successNotification));

  /// A firmer tap reserved for streak milestones (7, 30, 100, 365 days).
  void milestoneReached() => unawaited(_play(HapticFeedback.heavyImpact));

  Future<void> _play(Future<void> Function() feedback) async {
    final state = WidgetsBinding.instance.lifecycleState;
    if (_disposed ||
        !_enabled ||
        _changing ||
        !supported ||
        (state != null && state != AppLifecycleState.resumed)) {
      return;
    }
    try {
      await feedback();
    } on PlatformException {
      // Device feedback must never interrupt navigation or a saved action.
    } on MissingPluginException {
      // Some devices and runners do not implement haptic feedback.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
