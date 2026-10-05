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

class LearningStore extends ChangeNotifier {
  LearningStore._(this._preferences, {AnalyticsTransport? transport})
      : analytics = LearningAnalytics(_preferences, transport: transport),
        haptics = AppHaptics(_preferences),
        gettingStarted = GettingStartedStore(_preferences) {
    gettingStarted.addListener(notifyListeners);
    _readLocal();
  }
  static Future<LearningStore> load({AnalyticsTransport? transport}) async {
    final store = LearningStore._(await SharedPreferences.getInstance(),
        transport: transport);
    await store.gettingStarted.initialize();
    return store;
  }

  final SharedPreferences _preferences;
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
  Set<String> get _resourceIds =>
      {...resources.map((r) => r.id), ...foundationResources.map((r) => r.id)};
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
  LearningPath get currentPath => learningPaths
      .firstWhere((p) => p.id == _lastPath, orElse: () => learningPaths.first);
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
    _completed = (_preferences.getStringList(_key('completed')) ?? [])
        .toSet()
        .intersection(_lessonIds);
    _started = (_preferences.getStringList(_key('started')) ?? [])
        .toSet()
        .intersection(_lessonIds);
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
        _completed =
            Set<String>.from(state['completed']).intersection(_lessonIds);
        _started = Set<String>.from(state['started']).intersection(_lessonIds);
        _saved = Set<String>.from(state['saved']).intersection(_resourceIds);
        _lastPath = state['lastPath'] as String?;
        _pendingRecords = Map<String, String>.from(state['pendingRecords']);
        _pendingBookmarks = Map<String, bool>.from(state['pendingBookmarks']);
      }
    } catch (_) {
      /* Existing version-one records remain the migration fallback. */
    }
    _pendingRecords.removeWhere((id, status) =>
        !_lessonIds.contains(id) ||
        !['completed', 'in_progress'].contains(status));
    _pendingBookmarks.removeWhere((id, _) => !_resourceIds.contains(id));
  }

  Future<void> _persist() async {
    final state = jsonEncode({
      'completed': _completed.toList(),
      'started': _started.toList(),
      'saved': _saved.toList(),
      'lastPath': _lastPath,
      'pendingRecords': _pendingRecords,
      'pendingBookmarks': _pendingBookmarks,
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
      try {
        await action();
      } catch (_) {
        _completed = completed;
        _started = started;
        _saved = saved;
        _pendingRecords = records;
        _pendingBookmarks = bookmarks;
        _lastPath = lastPath;
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
  Future<void> completeLesson(String id) => _record(id, true);
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
      if (cloudConnected) _pendingBookmarks[id] = _saved.contains(id);
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
          _pendingBookmarks[id] = true;
        }
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
        _saved = (data['bookmarks'] as List)
            .whereType<Map>()
            .where((r) =>
                r['saved'] == true &&
                r['id'] is String &&
                _resourceIds.contains(r['id']))
            .map((r) => r['id'] as String)
            .toSet();
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
        lastSynced = DateTime.now();
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
            (_pendingRecords.isNotEmpty || _pendingBookmarks.isNotEmpty)) {
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
