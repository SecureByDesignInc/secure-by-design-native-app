import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'models.dart';

/// Device-local prototype state. No accounts, server, or cloud synchronization.
class LearningStore extends ChangeNotifier {
  LearningStore._(this._preferences) {
    final lessonIds =
        learningPaths.expand((p) => p.lessons).map((l) => l.id).toSet();
    final resourceIds = resources.map((r) => r.id).toSet();
    _completed = (_preferences.getStringList('sbd.completed.v1') ?? [])
        .toSet()
        .intersection(lessonIds);
    _saved = (_preferences.getStringList('sbd.saved.v1') ?? [])
        .toSet()
        .intersection(resourceIds);
    final last = _preferences.getString('sbd.lastPath.v1');
    _lastPath = learningPaths.any((p) => p.id == last) ? last : null;
  }

  static Future<LearningStore> load() async =>
      LearningStore._(await SharedPreferences.getInstance());
  final SharedPreferences _preferences;
  late Set<String> _completed;
  late Set<String> _saved;
  String? _lastPath;
  Future<void> _writes = Future.value();

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
        orElse: () => learningPaths.first,
      );
  Lesson? nextLesson(LearningPath path) {
    for (final lesson in path.lessons) {
      if (!isCompleted(lesson.id)) return lesson;
    }
    return null;
  }

  Future<void> _serialize(Future<void> Function() action) {
    final operation = _writes.then((_) => action());
    _writes = operation.then((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<void> openPath(String id) => _serialize(() async {
        if (!learningPaths.any((p) => p.id == id)) {
          throw ArgumentError.value(id, 'id');
        }
        if (!await _preferences.setString('sbd.lastPath.v1', id)) {
          throw StateError('Could not save the selected path.');
        }
        _lastPath = id;
        notifyListeners();
      });

  Future<void> completeLesson(String id) => _serialize(() async {
        if (!learningPaths.expand((p) => p.lessons).any((l) => l.id == id)) {
          throw ArgumentError.value(id, 'id');
        }
        if (_completed.contains(id)) return;
        final next = {..._completed, id};
        if (!await _preferences.setStringList(
            'sbd.completed.v1', next.toList())) {
          throw StateError('Could not save lesson progress.');
        }
        _completed = next;
        notifyListeners();
      });

  Future<void> toggleSaved(String id) => _serialize(() async {
        if (!resources.any((r) => r.id == id)) {
          throw ArgumentError.value(id, 'id');
        }
        final next = {..._saved};
        next.contains(id) ? next.remove(id) : next.add(id);
        if (!await _preferences.setStringList('sbd.saved.v1', next.toList())) {
          throw StateError('Could not save the resource.');
        }
        _saved = next;
        notifyListeners();
      });
}
