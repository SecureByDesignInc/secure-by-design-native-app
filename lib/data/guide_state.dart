import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';
import 'models.dart';

/// One lesson's checklist, observations and finished steps in lab mode.
///
/// Checks and notes are the website course guide's own records
/// (scripts/course-guide/renderer.js): `checks` keyed `<chapter>-<index>` and
/// `notes` keyed by chapter, inside the guide's `sbd-<course>` state. On this
/// device they live in preferences; for a signed-in learner they also sync to
/// the account, so what you tick in lab mode is ticked on the website's guide
/// and the other way around. The finished-step marks are lab mode's own and
/// stay on the device.
class LabNotes extends ChangeNotifier {
  LabNotes._(this._preferences, this.lesson, this.guide, this._account,
      this._chapterIndex, this._clock);

  /// Loads the lesson's saved checks and notes, then refreshes them from the
  /// account in the background when [account] is signed in.
  static Future<LabNotes> open(Lesson lesson,
      {required int chapterIndex,
      AccountStore? account,
      DateTime Function()? clock}) async {
    final guide = lesson.guide;
    if (guide == null) throw ArgumentError('This lesson has no course guide.');
    final notes = LabNotes._(await SharedPreferences.getInstance(), lesson,
        guide, account, chapterIndex.clamp(0, 99), clock ?? DateTime.now);
    notes._loadLocal();
    if (account != null && account.signedIn) unawaited(notes._pull());
    return notes;
  }

  final SharedPreferences _preferences;
  final Lesson lesson;
  final LessonGuide guide;
  final AccountStore? _account;
  final int _chapterIndex;
  final DateTime Function() _clock;

  /// The whole guide state as the website keeps it, so saving one lesson's
  /// checks never erases another lesson's notes.
  Map<String, Object> _state = {};
  Set<int> _doneSteps = {};
  Timer? _push;
  bool _disposed = false;

  /// What the learner sees about where their notes are kept.
  String status = '';
  bool get syncs => _account?.signedIn ?? false;

  String get _guideKey => 'sbd.guide.v1.${guide.id}';
  String get _stepsKey => 'sbd.lab.steps.v1.${lesson.id}';

  Map<String, Object> _map(String key) {
    final value = _state[key];
    return value is Map<String, Object> ? value : <String, Object>{};
  }

  bool checked(int index) => _map('checks')[guide.checkKey(index)] == true;
  String get note {
    final value = _map('notes')[guide.chapter];
    return value is String ? value : '';
  }

  bool stepDone(int index) => _doneSteps.contains(index);
  int get checkedCount =>
      [for (var i = 0; i < guide.checklist.length; i++) checked(i)]
          .where((c) => c)
          .length;

  void _loadLocal() {
    try {
      final raw = _preferences.getString(_guideKey);
      if (raw != null) _state = _clean(jsonDecode(raw)) ?? {};
    } catch (_) {
      _state = {};
    }
    _doneSteps = {
      for (final item in _preferences.getStringList(_stepsKey) ?? const <String>[])
        if (int.tryParse(item) case final int step) step,
    };
    status = syncs
        ? 'Saved to your account and the website’s course guide.'
        : 'Saved on this device. Sign in to keep these with the website’s course guide.';
  }

  /// A guide state the website would accept, or null.
  static Map<String, Object>? _clean(Object? raw) {
    if (raw is! Map) return null;
    Map<String, Object> keyed(Object? value, bool Function(Object?) keep) => {
          if (value is Map)
            for (final entry in value.entries)
              if (entry.key is String &&
                  RegExp(r'^[a-z0-9-]{1,80}$').hasMatch(entry.key as String) &&
                  keep(entry.value))
                entry.key as String: entry.value as Object,
        };
    final chapter = raw['chapter'];
    final completed = raw['completed'];
    final savedAt = raw['savedAt'];
    return {
      'chapter': chapter is int && chapter >= 0 && chapter < 100 ? chapter : 0,
      'notes': keyed(raw['notes'], (v) => v is String && v.length <= 30000),
      'checks': keyed(raw['checks'], (v) => v is bool),
      'answers': keyed(raw['answers'], (v) => v is int && v >= 0 && v < 20),
      'completed': [
        if (completed is List)
          for (final id in completed)
            if (id is String && RegExp(r'^[a-z0-9-]{1,80}$').hasMatch(id)) id,
      ],
      'savedAt': savedAt is int && savedAt >= 0 ? savedAt : 0,
    };
  }

  int _savedAt(Map<String, Object> state) {
    final value = state['savedAt'];
    return value is int ? value : 0;
  }

  /// Takes the account's copy unless this device changed the lesson since.
  Future<void> _pull() async {
    try {
      final remote = _clean(await _account!.guideState(guide.id));
      if (_disposed) return;
      if (remote != null && _savedAt(remote) >= _savedAt(_state)) {
        _state = remote;
        await _preferences.setString(_guideKey, jsonEncode(_state));
      } else if (_state.isNotEmpty) {
        _schedulePush(immediately: true);
      }
      status = 'Saved to your account and the website’s course guide.';
    } catch (_) {
      status = 'Saved on this device. Your account copy will update when you’re back online.';
    }
    _notify();
  }

  Future<void> setChecked(int index, bool value) =>
      _edit(() => (_state['checks'] = {..._map('checks'), guide.checkKey(index): value}));

  Future<void> setNote(String value) => _edit(() => (_state['notes'] = {
        ..._map('notes'),
        guide.chapter: value.length > 30000 ? value.substring(0, 30000) : value,
      }));

  Future<void> setStepDone(int index, bool value) async {
    value ? _doneSteps.add(index) : _doneSteps.remove(index);
    await _preferences.setStringList(
        _stepsKey, [for (final step in _doneSteps.toList()..sort()) '$step']);
    _notify();
  }

  Future<void> _edit(void Function() change) async {
    if (_state.isEmpty) _state = _clean({'chapter': _chapterIndex})!;
    change();
    _state['savedAt'] = _clock().millisecondsSinceEpoch;
    await _preferences.setString(_guideKey, jsonEncode(_state));
    _schedulePush();
    _notify();
  }

  void _schedulePush({bool immediately = false}) {
    if (!syncs) return;
    _push?.cancel();
    _push = Timer(immediately ? Duration.zero : const Duration(milliseconds: 1200),
        () => unawaited(_send()));
  }

  Future<void> _send() async {
    try {
      final saved = _clean(await _account!.guideState(guide.id, state: _state));
      if (saved != null && !_disposed) {
        status = 'Saved to your account and the website’s course guide.';
      }
    } catch (_) {
      status = 'Saved on this device. Your account copy will update when you’re back online.';
    }
    _notify();
  }

  /// Sends any change still waiting, then stops.
  Future<void> close() async {
    if (_push?.isActive ?? false) {
      _push!.cancel();
      await _send();
    }
    _disposed = true;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _push?.cancel();
    _disposed = true;
    super.dispose();
  }
}
