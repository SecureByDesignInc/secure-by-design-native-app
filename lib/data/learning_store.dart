import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog.dart';
import 'analytics.dart';
import 'models.dart';
import 'getting_started.dart';
import 'account.dart';
import 'haptics.dart';
import 'learning_activity.dart';

class LearningStore extends ChangeNotifier {
  LearningStore._(this._preferences,
      {AnalyticsTransport? transport, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        analytics = LearningAnalytics(_preferences, transport: transport),
        haptics = AppHaptics(_preferences),
        gettingStarted = GettingStartedStore(_preferences) {
    gettingStarted.addListener(notifyListeners);
    _readLocal();
  }
  static Future<LearningStore> load(
      {AnalyticsTransport? transport, DateTime Function()? clock}) async {
    final store = LearningStore._(await SharedPreferences.getInstance(),
        transport: transport, clock: clock);
    await store.gettingStarted.initialize();
    return store;
  }

  final SharedPreferences _preferences;
  final DateTime Function() _clock;
  Map<String, LearningActivity> _activities = {};
  Set<String> _pendingActivity = {};
  int _dailyGoal = 20;
  LearningStats get stats =>
      LearningStats(_activities.values, _clock(), _dailyGoal);
  int get dailyGoal => _dailyGoal;
  void refreshDay() => _notify();
  bool rewardedToday(String id) =>
      _activities.containsKey('${learningDay(_clock())}|$id');
  Lesson? get practiceLesson {
    final lessons = learningPaths
        .expand((p) => p.lessons)
        .where((l) => isCompleted(l.id))
        .toList();
    String lastDay(Lesson lesson) {
      final dates = _activities.values
          .where((a) => a.lessonId == lesson.id)
          .map((a) => a.day)
          .toList()
        ..sort();
      return dates.isEmpty ? '' : dates.last;
    }

    lessons.sort((a, b) => lastDay(a).compareTo(lastDay(b)));
    return lessons.isEmpty ? null : lessons.first;
  }

  Future<void> setDailyGoal(int goal) {
    final epoch = _epoch;
    return _serialize(() async {
      if (epoch != _epoch) return;
      if (![10, 20, 40].contains(goal)) throw ArgumentError.value(goal);
      final changed = goal != _dailyGoal;
      _dailyGoal = goal;
      await _persist();
      if (changed) analytics.dailyGoalChanged(goal);
      _notify();
    });
  }

  String? _earnBackOfferedDay;

  /// Records, at most once per day, that the restore offer was shown.
  void noteEarnBackOffered() {
    final offer = stats.earnBack;
    final day = learningDay(_clock());
    if (offer == null || _earnBackOfferedDay == day) return;
    _earnBackOfferedDay = day;
    analytics.earnBackOffered(offer.streak);
  }

  final LearningAnalytics analytics;
  final AppHaptics haptics;
  final GettingStartedStore gettingStarted;
  Set<String> _completed = {}, _saved = {}, _started = {};
  Map<String, String> _pendingRecords = {};
  Map<String, bool> _pendingBookmarks = {};
  String? _lastPath, _scope;
  int _epoch = 0;
  bool _disposed = false;
  AccountStore? _account;
  bool syncing = false;
  String? syncError;
  DateTime? lastSynced;
  Future<void> _writes = Future.value();
  Set<String> get _lessonIds =>
      learningPaths.expand((p) => p.lessons).map((l) => l.id).toSet();

  /// October 2026 library restructure: course 1.5 (connect-segment) was removed
  /// and its time lesson moved into course 1.2; course 1.6 (pki-services) merged
  /// into course 1.4. Saved device progress follows the lessons to their new IDs
  /// (the website migrates account progress the same way). On 14 October 2026
  /// the consolidated courses split into one course per system; the withdrawn
  /// endpoint-protection and scanning lessons simply drop out (no lesson has their IDs).
  static const _movedLessons = {
    'training:connect-segment:time': 'training:domain-time:time', // moved again on 14 October 2026
    'training:pki-services:publication': 'training:two-tier-pki:publication',
    'training:pki-services:publish-trust': 'training:two-tier-pki:publish-trust',
    'training:pki-services:template-admin': 'training:two-tier-pki:template-admin',
    'training:pki-services:first-templates': 'training:two-tier-pki:first-templates',
    'training:pki-services:validate': 'training:two-tier-pki:validate',
    // 14 October 2026: one course per system (content/progress-moves.json on the website).
    'training:dns-configuration:time': 'training:domain-time:time',
    'training:harden-baseline:staging': 'training:stig-scap:staging',
    'training:harden-baseline:baseline': 'training:stig-scap:baseline',
    'training:tiered-admin:dhcp': 'training:dhcp:dhcp',
    'training:patch-protect:repo': 'training:linux-repository:repo',
    'training:patch-protect:mgmt': 'training:management-server:mgmt',
    'training:logging-pipeline:protect': 'training:audit-repository:protect',
    'training:logging-pipeline:analyze': 'training:splunk-analysis:analyze',
    'training:logging-pipeline:prove': 'training:splunk-analysis:prove',
  };
  static const _movedPaths = {'pki-services': 'two-tier-pki'};
  Set<String> _carried(Iterable<String> ids) =>
      ids.map((id) => _movedLessons[id] ?? id).toSet().intersection(_lessonIds);
  Object? _carriedActivity(Object? raw) => raw is Map &&
          _movedLessons.containsKey(raw['lessonId'])
      ? {...raw, 'lessonId': _movedLessons[raw['lessonId']]}
      : raw;
  Map<String, String> _carriedRecords(Map<String, String> records) {
    final carried = <String, String>{};
    records.forEach((id, status) {
      final target = _movedLessons[id] ?? id;
      if (carried[target] != 'completed') carried[target] = status;
    });
    return carried;
  }
  Set<String> get _resourceIds =>
      {...resources.map((r) => r.id), ...foundationResources.map((r) => r.id)};

  /// Materials the website's bookmark catalog does not list yet stay saved on
  /// this device; uploading them would make the server reject the batch.
  Set<String> get _deviceOnlyResourceIds =>
      resources.where((r) => !r.syncable).map((r) => r.id).toSet();
  bool _syncsBookmark(String id) => !_deviceOnlyResourceIds.contains(id);
  String _key(String suffix) =>
      _scope == null ? 'sbd.$suffix.v1' : 'sbd.account.$_scope.$suffix.v1';
  bool get cloudConnected => _scope != null;
  String? get accountScope => _scope;
  String get storageLabel => cloudConnected
      ? 'Account progress · available offline on this device'
      : 'Saved on this device';
  Set<String> get completed => Set.unmodifiable(_completed);
  Set<String> get saved => Set.unmodifiable(_saved);
  bool isCompleted(String id) => _completed.contains(id);
  bool isSaved(String id) => _saved.contains(id);
  int completedIn(LearningPath path) =>
      path.lessons.where((l) => isCompleted(l.id)).length;
  double progressIn(LearningPath path) =>
      completedIn(path) / path.lessons.length;
  int get totalLessons => learningPaths.fold(0, (n, p) => n + p.lessons.length);
  int get learnedMinutes => learningPaths
      .expand((p) => p.lessons)
      .where((l) => isCompleted(l.id))
      .fold(0, (n, l) => n + l.minutes);
  LearningPath get currentPath => learningPaths.firstWhere(
      (p) => p.id == _lastPath,
      orElse: () => learningPaths.firstWhere(
          (p) => p.id == gettingStarted.profile?.pathIds.first,
          orElse: () => learningPaths.first));
  Lesson? nextLesson(LearningPath path) {
    for (final lesson in path.lessons) {
      if (!isCompleted(lesson.id)) return lesson;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _readLocal() {
    _activities = {};
    _pendingActivity = {};
    _dailyGoal = 20;
    _completed = _carried(_preferences.getStringList(_key('completed')) ?? []);
    _started = _carried(_preferences.getStringList(_key('started')) ?? []);
    _saved = (_preferences.getStringList(_key('saved')) ?? [])
        .toSet()
        .intersection(_resourceIds);
    _lastPath = _preferences.getString(_key('lastPath'));
    try {
      _pendingRecords = Map<String, String>.from(
          jsonDecode(_preferences.getString(_key('pendingRecords')) ?? '{}'));
    } catch (_) {
      _pendingRecords = {};
    }
    try {
      _pendingBookmarks = Map<String, bool>.from(
          jsonDecode(_preferences.getString(_key('pendingBookmarks')) ?? '{}'));
    } catch (_) {
      _pendingBookmarks = {};
    }
    try {
      final raw = _preferences.getString(_key('state'));
      if (raw != null) {
        final state = jsonDecode(raw) as Map;
        _completed = _carried(Set<String>.from(state['completed']));
        _started = _carried(Set<String>.from(state['started']));
        _saved = Set<String>.from(state['saved']).intersection(_resourceIds);
        _lastPath = state['lastPath'] as String?;
        _pendingRecords = Map<String, String>.from(state['pendingRecords']);
        _pendingBookmarks = Map<String, bool>.from(state['pendingBookmarks']);
        for (final raw in state['activity'] is List ? state['activity'] : []) {
          final event =
              LearningActivity.fromJson(_carriedActivity(raw), _lessonIds);
          if (event != null) _activities[event.key] = event;
        }
        _pendingActivity = (state['pendingActivity'] is List
                ? (state['pendingActivity'] as List).whereType<String>().toSet()
                : <String>{})
            .intersection(_activities.keys.toSet());
        if ([10, 20, 40].contains(state['dailyGoal'])) {
          _dailyGoal = state['dailyGoal'] as int;
        }
      }
    } catch (_) {
      /* Existing version-one records remain the migration fallback. */
    }
    final lastPath = _lastPath;
    if (_movedPaths.containsKey(lastPath)) _lastPath = _movedPaths[lastPath];
    _pendingRecords = _carriedRecords(_pendingRecords);
    _pendingRecords.removeWhere((id, status) =>
        !_lessonIds.contains(id) ||
        !['completed', 'in_progress'].contains(status));
    _pendingBookmarks.removeWhere(
        (id, _) => !_resourceIds.contains(id) || !_syncsBookmark(id));
  }

  Future<void> _persist() async {
    final state = jsonEncode({
      'completed': _completed.toList(),
      'started': _started.toList(),
      'saved': _saved.toList(),
      'lastPath': _lastPath,
      'pendingRecords': _pendingRecords,
      'pendingBookmarks': _pendingBookmarks,
      'activity': _activities.values.map((e) => e.toJson()).toList(),
      'pendingActivity': _pendingActivity.toList(),
      'dailyGoal': _dailyGoal,
    });
    if (!await _preferences.setString(_key('state'), state)) {
      throw StateError('Could not save learning progress.');
    }
  }

  Future<void> _serialize(Future<void> Function() action) {
    final operation = _writes.then((_) async {
      final completed = Set<String>.of(_completed),
          started = Set<String>.of(_started),
          saved = Set<String>.of(_saved);
      final records = Map<String, String>.of(_pendingRecords),
          bookmarks = Map<String, bool>.of(_pendingBookmarks);
      final lastPath = _lastPath;
      final activity = Map<String, LearningActivity>.of(_activities);
      final pendingActivity = Set<String>.of(_pendingActivity);
      final goal = _dailyGoal;
      try {
        await action();
      } catch (_) {
        _completed = completed;
        _started = started;
        _saved = saved;
        _pendingRecords = records;
        _pendingBookmarks = bookmarks;
        _lastPath = lastPath;
        _activities = activity;
        _pendingActivity = pendingActivity;
        _dailyGoal = goal;
        rethrow;
      }
    });
    _writes = operation.then((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<void> openPath(String id) {
    final epoch = _epoch;
    return _serialize(() async {
      if (epoch != _epoch) return;
      if (!learningPaths.any((p) => p.id == id)) throw ArgumentError.value(id);
      _lastPath = id;
      await _persist();
      _notify();
    });
  }

  Future<void> startLesson(String id) => _record(id, false);
  Future<void> completeLesson(String id) async {
    await finishLesson(id);
  }

  Future<LearningReward?> finishLesson(String id,
      {bool perfect = false}) async {
    final epoch = _epoch;
    LearningReward? reward;
    await _serialize(() async {
      if (epoch != _epoch) return;
      if (!_lessonIds.contains(id)) throw ArgumentError.value(id);
      final before = stats;
      final review = isCompleted(id);
      final event = LearningActivity(
          day: learningDay(_clock()),
          lessonId: id,
          review: review,
          perfect: perfect);
      _started.add(id);
      _completed.add(id);
      if (!_activities.containsKey(event.key)) {
        _activities[event.key] = event;
        if (cloudConnected) _pendingActivity.add(event.key);
      }
      if (cloudConnected) _pendingRecords[id] = 'completed';
      await _persist();
      final after = stats;
      final extended = !before.learnedToday && after.learnedToday;
      final restored = before.earnBack != null &&
          after.earnBack == null &&
          after.streak > before.streak + 1;
      final milestone = after.streak > before.streak &&
              LearningStats.milestones.contains(after.streak)
          ? after.streak
          : null;
      reward = LearningReward(
          xp: after.totalXp - before.totalXp,
          review: review,
          stats: after,
          extendedStreak: extended,
          restoredStreak: restored,
          freezeEarned: after.freezes > before.freezes,
          milestone: milestone,
          newBadges: after.badges
              .where((b) =>
                  b.earned &&
                  !before.badges
                      .any((old) => old.title == b.title && old.earned))
              .toList());
      if (!review) analytics.lessonCompleted(id);
      if (extended) analytics.streakExtended(after.streak);
      if (restored) analytics.earnBackCompleted(after.streak);
      if (milestone != null) analytics.streakMilestone(milestone);
      _notify();
    });
    if (cloudConnected) unawaited(sync());
    return reward;
  }

  Future<void> _record(String id, bool done) async {
    final epoch = _epoch;
    await _serialize(() async {
      if (epoch != _epoch) return;
      if (!_lessonIds.contains(id)) throw ArgumentError.value(id);
      if (done && _completed.contains(id)) return;
      _started.add(id);
      if (done) _completed.add(id);
      if (cloudConnected) {
        _pendingRecords[id] =
            _completed.contains(id) ? 'completed' : 'in_progress';
      }
      await _persist();
      if (done) analytics.lessonCompleted(id);
      _notify();
    });
    if (cloudConnected) unawaited(sync());
  }

  Future<void> toggleSaved(String id) async {
    final epoch = _epoch;
    await _serialize(() async {
      if (epoch != _epoch) return;
      if (!_resourceIds.contains(id)) throw ArgumentError.value(id);
      _saved.contains(id) ? _saved.remove(id) : _saved.add(id);
      if (cloudConnected && _syncsBookmark(id)) {
        _pendingBookmarks[id] = _saved.contains(id);
      }
      await _persist();
      if (_saved.contains(id)) analytics.resourceSaved(id);
      _notify();
    });
    if (cloudConnected) unawaited(sync());
  }

  Future<void> connectAccount(AccountStore account) async {
    if (!account.signedIn || account.accountId == null) {
      throw StateError('Sign in again to connect progress.');
    }
    _epoch++;
    await _writes;
    _account = account;
    _scope = account.accountId;
    syncing = false;
    syncError = null;
    lastSynced = null;
    _readLocal();
    _notify();
    await sync();
  }

  Future<void> disconnectAccount() async {
    _epoch++;
    await _writes;
    _account = null;
    _scope = null;
    syncing = false;
    syncError = null;
    lastSynced = null;
    _readLocal();
    _notify();
  }

  Future<void> importDeviceProgress() async {
    if (!cloudConnected) return;
    final epoch = _epoch;
    await _serialize(() async {
      if (epoch != _epoch) return;
      Map guest = {};
      try {
        guest =
            jsonDecode(_preferences.getString('sbd.state.v1') ?? '{}') as Map;
      } catch (_) {}
      for (final id in (guest['completed'] as List?)?.cast<String>() ??
          _preferences.getStringList('sbd.completed.v1') ??
          <String>[]) {
        if (_lessonIds.contains(id)) {
          _completed.add(id);
          _pendingRecords[id] = 'completed';
        }
      }
      for (final id in (guest['saved'] as List?)?.cast<String>() ??
          _preferences.getStringList('sbd.saved.v1') ??
          <String>[]) {
        if (_resourceIds.contains(id)) {
          _saved.add(id);
          if (_syncsBookmark(id)) _pendingBookmarks[id] = true;
        }
      }
      for (final raw in guest['activity'] is List ? guest['activity'] : []) {
        final event = LearningActivity.fromJson(raw, _lessonIds);
        if (event == null) continue;
        _activities[event.key] = _activities[event.key]?.merge(event) ?? event;
        _pendingActivity.add(event.key);
      }
      await _persist();
      _notify();
    });
    await sync();
  }

  static String cloudId(String id) =>
      id.startsWith('training:') ? id : 'native:$id';
  static String localId(String id) =>
      id.startsWith('native:') ? id.substring(7) : id;
  Future<void> sync() async {
    final account = _account;
    if (syncing ||
        _scope == null ||
        account == null ||
        !account.signedIn ||
        account.accountId != _scope) {
      return;
    }
    final epoch = _epoch, scope = _scope;
    syncing = true;
    syncError = null;
    _notify();
    final records = Map<String, String>.from(_pendingRecords);
    final bookmarks = Map<String, bool>.from(_pendingBookmarks);
    final activity = {
      for (final key in _pendingActivity) key: _activities[key]!
    };
    try {
      final data = await account.syncProgress(
        records.entries
            .map((e) => {'id': cloudId(e.key), 'status': e.value})
            .toList(),
        bookmarks.entries.map((e) => {'id': e.key, 'saved': e.value}).toList(),
      );
      if (epoch != _epoch || scope != _scope || account.accountId != scope) {
        return;
      }
      if (data['accountId'] != scope ||
          data['records'] is! List ||
          data['bookmarks'] is! List) {
        throw const FormatException('Invalid progress response');
      }
      await _serialize(() async {
        if (epoch != _epoch) return;
        for (final e in records.entries) {
          if (_pendingRecords[e.key] == e.value) _pendingRecords.remove(e.key);
        }
        for (final e in bookmarks.entries) {
          if (_pendingBookmarks[e.key] == e.value) {
            _pendingBookmarks.remove(e.key);
          }
        }
        final received = <String, String>{};
        for (final row in data['records'] as List) {
          if (row is Map &&
              row['id'] is String &&
              ['completed', 'in_progress'].contains(row['status'])) {
            final id = localId(row['id'] as String);
            if (_lessonIds.contains(id)) received[id] = row['status'] as String;
          }
        }
        received.addAll(_pendingRecords);
        _started = received.keys.toSet();
        _completed = received.entries
            .where((e) => e.value == 'completed')
            .map((e) => e.key)
            .toSet();
        final deviceOnly = _saved.where((id) => !_syncsBookmark(id)).toSet();
        _saved = (data['bookmarks'] as List)
            .whereType<Map>()
            .where((r) =>
                r['saved'] == true &&
                r['id'] is String &&
                _resourceIds.contains(r['id']) &&
                _syncsBookmark(r['id'] as String))
            .map((r) => r['id'] as String)
            .toSet()
          ..addAll(deviceOnly);
        for (final e in _pendingBookmarks.entries) {
          e.value ? _saved.add(e.key) : _saved.remove(e.key);
        }
        final active = received.entries
            .where((e) => e.value == 'in_progress')
            .map((e) => e.key)
            .toSet();
        for (final path in learningPaths) {
          if (path.lessons.any((l) => active.contains(l.id))) {
            _lastPath = path.id;
            break;
          }
        }
        await _persist();
      });
      if (epoch != _epoch || account.accountId != scope) return;
      final activityData = await account
          .syncActivity(activity.values.map((e) => e.toJson()).toList());
      if (epoch != _epoch || account.accountId != scope) return;
      await _serialize(() async {
        if (epoch != _epoch) return;
        for (final raw in activityData) {
          final event = LearningActivity.fromJson(raw, _lessonIds);
          if (event == null) {
            throw const FormatException('Invalid learning activity');
          }
          _activities[event.key] =
              _activities[event.key]?.merge(event) ?? event;
        }
        for (final entry in activity.entries) {
          if (_activities[entry.key]?.xp == entry.value.xp) {
            _pendingActivity.remove(entry.key);
          }
        }
        await _persist();
        lastSynced = _clock();
      });
    } catch (_) {
      if (epoch == _epoch) {
        syncError =
            'Could not sync. Your changes are saved here; reconnect and try again.';
      }
    } finally {
      if (epoch == _epoch) {
        syncing = false;
        _notify();
        if (syncError == null &&
            (_pendingRecords.isNotEmpty ||
                _pendingBookmarks.isNotEmpty ||
                _pendingActivity.isNotEmpty)) {
          unawaited(sync());
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    gettingStarted.removeListener(notifyListeners);
    gettingStarted.dispose();
    analytics.dispose();
    haptics.dispose();
    super.dispose();
  }
}
