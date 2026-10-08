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
    expect(stats.freezes, 2);
    expect(stats.quests.where((q) => q.complete), isEmpty);
  });

  test(
      'two starting freezes cover missed days, add no day, and exhaustion resets',
      () {
    final events = [activity('2026-10-01')];
    expect(LearningStats(events, DateTime(2026, 10, 2, 23, 59), 20).freezes, 2);
    final protected = LearningStats(events, DateTime(2026, 10, 3), 20);
    expect(protected.streak, 1);
    expect(protected.frozenDays, {'2026-10-02'});
    expect(protected.freezes, 1);
    expect(protected.totalXp, 30);
    final both = LearningStats(events, DateTime(2026, 10, 4), 20);
    expect(both.streak, 1);
    expect(both.frozenDays, {'2026-10-02', '2026-10-03'});
    expect(both.freezes, 0);
    final lost = LearningStats(events, DateTime(2026, 10, 5), 20);
    expect(lost.streak, 0);
    expect(lost.longestStreak, 1);
    expect(lost.earnBack, isNull, reason: 'a 1-day streak just restarts');
    expect(
        LearningStats(
                [...events, activity('2026-10-03')], DateTime(2026, 10, 3), 20)
            .streak,
        2);
    expect(
        LearningStats(
                [...events, activity('2026-10-04')], DateTime(2026, 10, 4), 20)
            .streak,
        2);
    expect(
        LearningStats(
                [...events, activity('2026-10-05')], DateTime(2026, 10, 5), 20)
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

  test('a missed day without freezes can be earned back with two lessons',
      () {
    final run = [
      for (var i = 1; i <= 5; i++) activity('2026-10-0$i'),
    ];
    // Oct 6 and 7 use both freezes; Oct 8 is the first unprotected miss.
    final offer = LearningStats(run, DateTime(2026, 10, 9), 20);
    expect(offer.streak, 0);
    expect(offer.frozenDays, {'2026-10-06', '2026-10-07'});
    expect(offer.earnBack, isNotNull);
    expect(offer.earnBack!.streak, 5);
    expect(offer.earnBack!.done, 0);
    expect(offer.earnBack!.remaining, 2);
    expect(offer.earnBack!.deadline, '2026-10-10');

    final halfway =
        LearningStats([...run, activity('2026-10-09')], DateTime(2026, 10, 9), 20);
    expect(halfway.streak, 1);
    expect(halfway.earnBack!.done, 1);

    final restored = LearningStats([
      ...run,
      activity('2026-10-09'),
      activity('2026-10-09', id: 'ad-2'),
    ], DateTime(2026, 10, 9), 20);
    expect(restored.earnBack, isNull);
    expect(restored.streak, 6);
    expect(restored.repairedDays, {'2026-10-08'});
    expect(restored.longestStreak, 6);

    final acrossTwoDays = LearningStats([
      ...run,
      activity('2026-10-09'),
      activity('2026-10-10'),
    ], DateTime(2026, 10, 10), 20);
    expect(acrossTwoDays.streak, 7);
    expect(acrossTwoDays.earnBack, isNull);

    final lastChance = LearningStats(run, DateTime(2026, 10, 10), 20);
    expect(lastChance.earnBack!.deadline, '2026-10-10');
    expect(lastChance.earnBack!.done, 0);

    final expired = LearningStats(run, DateTime(2026, 10, 11), 20);
    expect(expired.streak, 0);
    expect(expired.earnBack, isNull);
    final tooLate =
        LearningStats([...run, activity('2026-10-11')], DateTime(2026, 10, 11), 20);
    expect(tooLate.streak, 1);
    expect(tooLate.earnBack, isNull);
  });

  test('milestones, earn-back and freeze rewards reach the celebration',
      () async {
    var now = DateTime(2026, 10, 1);
    final store = await LearningStore.load(clock: () => now);
    addTearDown(store.dispose);
    LearningReward? reward;
    for (var i = 0; i < 7; i++) {
      reward = await store.finishLesson('ad-1');
      if (i < 6) {
        expect(reward!.milestone, isNull);
        now = now.add(const Duration(days: 1));
      }
    }
    expect(reward!.milestone, 7);
    expect(store.stats.nextMilestone, 30);
    // Three missed days: two freezes, then one day to earn back.
    now = DateTime(2026, 10, 11);
    expect(store.stats.earnBack!.streak, 7);
    final first = await store.finishLesson('ad-1');
    expect(first!.restoredStreak, false);
    final second = await store.finishLesson('ad-2');
    expect(second!.restoredStreak, true);
    expect(store.stats.streak, 8);
    expect(store.stats.earnBack, isNull);
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
