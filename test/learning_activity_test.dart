import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/account.dart';
import 'package:secure_by_design_app/data/learning_activity.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'progress_sync_test.dart' show Cloud, settled;

LearningActivity activity(String day,
        {String id = 'ad-1', bool review = false, bool perfect = false}) =>
    LearningActivity(day: day, lessonId: id, review: review, perfect: perfect);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('calendar days handle leap days and offset clocks without 24-hour math',
      () {
    expect(parseLearningDay('2028-02-29'), isNotNull);
    expect(parseLearningDay('2026-02-29'), isNull);
    expect(parseLearningDay('2026-13-01'), isNull);
    final stats = LearningStats([
      activity('2028-02-28'),
      activity('2028-02-29'),
      activity('2028-03-01')
    ], DateTime(2028, 3, 1, 0, 1), 40);
    expect(stats.streak, 3);
    expect(stats.learnedToday, true);
    expect(stats.todayXp, 30);
    expect(
        LearningStats([
          activity('2026-03-07'),
          activity('2026-03-08'),
          activity('2026-03-09')
        ], DateTime(2026, 3, 9), 20)
            .streak,
        3);
  });

  test('one learning day protects the streak independently of the daily goal',
      () {
    final stats = LearningStats(
        [activity('2026-10-05', review: true)], DateTime(2026, 10, 5), 40);
    expect(stats.streak, 1);
    expect(stats.todayXp, 10);
    expect(stats.freezes, 1);
    expect(stats.quests.where((q) => q.complete), isEmpty);
  });

  test('freeze covers a missed day, does not add a day, and exhaustion resets',
      () {
    final events = [activity('2026-10-01')];
    expect(LearningStats(events, DateTime(2026, 10, 2, 23, 59), 20).freezes, 1);
    final protected = LearningStats(events, DateTime(2026, 10, 3), 20);
    expect(protected.streak, 1);
    expect(protected.frozenDays, {'2026-10-02'});
    expect(protected.freezes, 0);
    expect(protected.totalXp, 30);
    final lost = LearningStats(events, DateTime(2026, 10, 4), 20);
    expect(lost.streak, 0);
    expect(lost.longestStreak, 1);
    expect(
        LearningStats(
                [...events, activity('2026-10-03')], DateTime(2026, 10, 3), 20)
            .streak,
        2);
    expect(
        LearningStats(
                [...events, activity('2026-10-04')], DateTime(2026, 10, 4), 20)
            .streak,
        1);
  });

  test(
      'seven active days refill a freeze, capped at two; future activity is ignored',
      () {
    final events = [
      for (var i = 1; i <= 21; i++)
        activity('2026-09-${i.toString().padLeft(2, '0')}')
    ];
    final stats = LearningStats(events, DateTime(2026, 9, 21), 20);
    expect(stats.freezes, 2);
    expect(stats.streak, 21);
    expect(LearningStats(events, DateTime(2026, 9, 23), 20).streak, 21);
    expect(LearningStats(events, DateTime(2026, 9, 24), 20).freezes, 0);
    expect(LearningStats(events, DateTime(2026, 9, 25), 20).streak, 0);
    expect(
        LearningStats([activity('2026-10-06')], DateTime(2026, 10, 5), 20)
            .totalXp,
        0);
  });

  test('daily quests award once and monthly progress resets with the calendar',
      () {
    final events = [
      activity('2026-09-30', perfect: true),
      activity('2026-09-30', id: 'ad-2')
    ];
    final september = LearningStats(events, DateTime(2026, 9, 30), 20);
    expect(september.totalXp, 75);
    expect(september.monthlyQuestCount, 3);
    final october = LearningStats(events, DateTime(2026, 10, 1), 20);
    expect(october.monthlyQuestCount, 0);
    expect(october.totalXp, 75);
    expect(october.todayXp, 0);
  });

  test(
      'completion, duplicate taps, review XP, goals and milestones survive restart',
      () async {
    var now = DateTime(2026, 10, 5, 23, 59);
    final store = await LearningStore.load(clock: () => now);
    addTearDown(store.dispose);
    final reward = await store.finishLesson('ad-1', perfect: true);
    expect(reward!.xp, 45);
    expect(reward.newBadges.map((b) => b.title), ['First spark']);
    final duplicate = await store.finishLesson('ad-1', perfect: true);
    expect(duplicate!.xp, 0);
    expect(duplicate.newBadges, isEmpty);
    await store.setDailyGoal(40);
    now = DateTime(2026, 10, 6, 0, 1);
    final review = await store.finishLesson('ad-1');
    expect(review!.xp, 10);
    expect(review.review, true);
    expect(store.stats.streak, 2);
    final restored = await LearningStore.load(clock: () => now);
    addTearDown(restored.dispose);
    expect(restored.stats.totalXp, 55);
    expect(restored.stats.streak, 2);
    expect(restored.dailyGoal, 40);
    expect(restored.completed, {'ad-1'});
  });

  test('legacy progress is preserved without inventing streak dates or rewards',
      () async {
    SharedPreferences.setMockInitialValues({
      'sbd.completed.v1': ['ad-1'],
      'sbd.haptics.enabled.v1': false
    });
    final store = await LearningStore.load(clock: () => DateTime(2026, 10, 5));
    addTearDown(store.dispose);
    expect(store.stats.totalXp, 0);
    expect(store.stats.streak, 0);
    expect(store.isCompleted('ad-1'), true);
    expect(store.haptics.enabled, false);
    expect((await store.finishLesson('ad-1'))!.xp, 10);
  });

  test(
      'activity imports explicitly, syncs to a second device and survives offline retry',
      () async {
    final cloud = Cloud();
    final auth = AccountStore(transport: cloud);
    addTearDown(auth.dispose);
    final store = await LearningStore.load(clock: () => DateTime(2026, 10, 5));
    addTearDown(store.dispose);
    await store.finishLesson('ad-1', perfect: true);
    await auth.signIn('alice@example.invalid', 'test');
    await store.connectAccount(auth);
    expect(store.stats.totalXp, 0);
    await store.importDeviceProgress();
    expect(store.stats.totalXp, 45);
    await store.importDeviceProgress();
    expect(store.stats.totalXp, 45);
    cloud.offline = true;
    await store.finishLesson('ad-2');
    await settled(store);
    expect(store.syncError, isNotNull);
    expect(store.stats.totalXp, 75);
    cloud.offline = false;
    await store.sync();
    expect(store.syncError, isNull);
    SharedPreferences.setMockInitialValues({});
    final second = await LearningStore.load(clock: () => DateTime(2026, 10, 5));
    addTearDown(second.dispose);
    await second.connectAccount(auth);
    expect(second.stats.totalXp, 75);
    expect(second.stats.streak, 1);
    await second.disconnectAccount();
    expect(second.stats.totalXp, 0);
  });

  test('a late activity response never enters another account or guest state',
      () async {
    final cloud = _DelayedActivityCloud();
    final account = AccountStore(transport: cloud);
    addTearDown(account.dispose);
    final store = await LearningStore.load(clock: () => DateTime(2026, 10, 5));
    addTearDown(store.dispose);
    await account.signIn('alice@example.invalid', 'test');
    await store.connectAccount(account);
    cloud.hold = true;
    final sync = store.sync();
    await cloud.started.future;
    await store.disconnectAccount();
    cloud.hold = false;
    cloud.user = 'bob';
    await account.signIn('bob@example.invalid', 'test');
    await store.connectAccount(account);
    cloud.reply.complete({
      'accountId': 'alice',
      'activity': [activity('2026-10-05').toJson()],
      'nextCursor': null
    });
    await sync;
    expect(store.accountScope, 'bob');
    expect(store.stats.totalXp, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('sbd.account.bob.state.v1')!)['activity'],
        isEmpty);
  });
}

class _DelayedActivityCloud extends Cloud {
  bool hold = false;
  final started = Completer<void>();
  final reply = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, Object>? body, String? token}) {
    if (hold && path == '/api/native-activity') {
      started.complete();
      return reply.future;
    }
    return super.request(method, path, body: body, token: token);
  }
}
