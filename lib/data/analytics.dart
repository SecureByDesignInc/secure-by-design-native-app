import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'learning_activity.dart';

abstract interface class AnalyticsTransport {
  Future<void> send(Map<String, Object> event);
  void cancel();
}

/// Native-only, best-effort capture. No queue, replay, autocapture or retries.
class PostHogTransport implements AnalyticsTransport {
  final Set<HttpClient> _active = {};

  @override
  Future<void> send(Map<String, Object> event) async {
    if (_active.length >= 4) return;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    _active.add(client);
    try {
      await (() async {
        final request = await client.postUrl(
          Uri.parse('https://us.i.posthog.com/i/v0/e/'),
        );
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({
          // Public project ingestion token, never a personal/admin API key.
          'api_key': 'phc_DjBNWHmuWDptzRcSxfocitcyR8K7d5yBPByHXJCi5inX',
          ...event,
        }));
        final response = await request.close();
        await response.drain<void>();
      })().timeout(const Duration(seconds: 4));
    } finally {
      client.close(force: true);
      _active.remove(client);
    }
  }

  @override
  void cancel() {
    for (final client in _active) {
      client.close(force: true);
    }
    _active.clear();
  }
}

class LearningAnalytics extends ChangeNotifier {
  LearningAnalytics(this._preferences, {AnalyticsTransport? transport})
      : _transport = transport ?? PostHogTransport() {
    _id = _preferences.getString(idKey);
    _enabled = _preferences.getBool(consentKey) == true && _id != null;
  }

  static const consentKey = 'sbd.analytics.enabled.v1';
  static const idKey = 'sbd.analytics.id.v1';
  final SharedPreferences _preferences;
  final AnalyticsTransport _transport;
  late bool _enabled;
  String? _id;
  bool _changing = false;
  bool get enabled => _enabled;
  bool get changing => _changing;

  Future<void> setEnabled(bool value) async {
    if (_changing || (value && _enabled)) return;
    if (!value && !_enabled &&
        _preferences.getBool(consentKey) != true &&
        _preferences.getString(idKey) == null) {
      return;
    }
    _changing = true;
    // Stop outgoing work immediately when consent is withdrawn.
    if (!value) {
      _enabled = false;
      _id = null;
      _transport.cancel();
    }
    notifyListeners();
    try {
      if (value) {
        final random = Random.secure();
        final id = List.generate(16, (_) =>
            random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        if (!await _preferences.setString(idKey, id) ||
            !await _preferences.setBool(consentKey, true)) {
          throw StateError('Could not save analytics preference.');
        }
        _id = id;
        _enabled = true;
      } else {
        if (!await _preferences.setBool(consentKey, false) ||
            !await _preferences.remove(idKey)) {
          throw StateError('Could not save analytics preference.');
        }
      }
    } finally {
      _changing = false;
      notifyListeners();
    }
  }

  void _capture(String name, Map<String, Object> properties) {
    if (!_enabled || _changing || _id == null) return;
    final event = <String, Object>{
      'event': name,
      'distinct_id': _id!,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'properties': <String, Object>{
        r'$process_person_profile': false,
        'platform': defaultTargetPlatform.name,
        'environment': kReleaseMode ? 'beta' : 'development',
        'schema_version': 1,
        ...properties,
      },
    };
    unawaited(_send(event));
  }

  Future<void> _send(Map<String, Object> event) async {
    try {
      await _transport.send(event);
    } catch (_) {
      // Analytics must never interrupt learning or expose event data in logs.
    }
  }

  void appOpened() => _capture('app_opened', {});
  void feedbackOpened() => _capture('feedback_opened', {});

  /// Onboarding choices themselves never leave the device; only the outcome.
  void onboardingFinished(
          {required bool skipped, required bool startedLesson}) =>
      _capture('onboarding_completed',
          {'skipped': skipped, 'started_lesson': startedLesson});

  void dailyGoalChanged(int goal) {
    if (const [10, 20, 40].contains(goal)) {
      _capture('daily_goal_set', {'goal_xp': goal});
    }
  }

  void streakExtended(int streak) => _streak('streak_extended', streak);
  void streakMilestone(int days) {
    if (LearningStats.milestones.contains(days)) {
      _capture('streak_milestone', {'days': days});
    }
  }

  void earnBackOffered(int streak) => _streak('earn_back_offered', streak);
  void earnBackCompleted(int streak) => _streak('earn_back_completed', streak);
  void _streak(String name, int streak) {
    if (streak >= 0 && streak <= 100000) _capture(name, {'streak': streak});
  }

  void pathOpened(String id) {
    if (learningPaths.any((path) => path.id == id)) {
      _capture('path_opened', {'path_id': id});
    }
  }

  void lessonOpened(String id) => _lesson('lesson_opened', id);
  void lessonCompleted(String id) => _lesson('lesson_completed', id);
  void knowledgeCheckSubmitted(String id, bool correct) =>
      _lesson('knowledge_check_submitted', id, {'correct': correct});

  void _lesson(String name, String id,
      [Map<String, Object> extra = const {}]) {
    for (final path in learningPaths) {
      if (path.lessons.any((lesson) => lesson.id == id)) {
        _capture(name, {'path_id': path.id, 'lesson_id': id, ...extra});
        return;
      }
    }
  }

  void resourceOpened(String id) => _resource('resource_opened', id);
  void resourceSaved(String id) => _resource('resource_saved', id);
  void _resource(String name, String id) {
    if (resources.any((resource) => resource.id == id)) {
      _capture(name, {'resource_id': id});
    }
  }

  @override
  void dispose() {
    _enabled = false;
    _transport.cancel();
    super.dispose();
  }
}
