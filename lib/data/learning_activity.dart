import 'dart:math' as math;

/// Calendar days, not 24-hour durations: DST and travel cannot re-date a lesson.
String learningDay(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
DateTime? parseLearningDay(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final date = DateTime.tryParse('${value}T00:00:00Z');
  return date != null && learningDay(date) == value ? date : null;
}

class LearningActivity {
  const LearningActivity(
      {required this.day,
      required this.lessonId,
      required this.review,
      required this.perfect});
  final String day, lessonId;
  final bool review, perfect;
  String get key => '$day|$lessonId';
  int get xp => (review ? 10 : 20) + (perfect ? 5 : 0);
  Map<String, Object> toJson() =>
      {'day': day, 'lessonId': lessonId, 'review': review, 'perfect': perfect};
  static LearningActivity? fromJson(Object? raw, Set<String> validIds) {
    if (raw is! Map ||
        parseLearningDay(raw['day']) == null ||
        !validIds.contains(raw['lessonId']) ||
        raw['review'] is! bool ||
        raw['perfect'] is! bool) {
      return null;
    }
    return LearningActivity(
        day: raw['day'] as String,
        lessonId: raw['lessonId'] as String,
        review: raw['review'] as bool,
        perfect: raw['perfect'] as bool);
  }

  /// A union is commutative and retry-safe across offline devices.
  LearningActivity merge(LearningActivity other) => LearningActivity(
      day: day,
      lessonId: lessonId,
      review: review && other.review,
      perfect: perfect || other.perfect);
}

class DailyQuest {
  const DailyQuest(this.title, this.detail, this.current, this.target);
  final String title, detail;
  final int current, target;
  bool get complete => current >= target;
  double get progress => (current / target).clamp(0, 1);
}

class LearningBadge {
  const LearningBadge(this.title, this.detail, this.earned);
  final String title, detail;
  final bool earned;
}

/// A streak that broke recently and can still be restored, free: finish
/// [needed] lessons on the two calendar days after the first missed day.
class EarnBack {
  const EarnBack(
      {required this.streak, required this.done, required this.deadline});
  static const needed = 2;

  /// The streak length before the miss, restored when the learner earns it back.
  final int streak;

  /// Lessons or reviews already finished inside the earn-back window.
  final int done;

  /// The last calendar day of the window (inclusive).
  final String deadline;
  int get remaining => math.max(0, needed - done);
}

class LearningStats {
  /// New learners start fully protected: two freezes cover their first misses.
  static const startingFreezes = 2, maxFreezes = 2;

  /// Shorter streaks simply restart; there is little to earn back.
  static const earnBackMinimum = 3;

  /// Big celebrations happen only at these streak lengths.
  static const milestones = [7, 30, 100, 365];

  LearningStats(
      Iterable<LearningActivity> activities, DateTime now, this.dailyGoal) {
    today = learningDay(now);
    for (final event in activities) {
      if (event.day.compareTo(today) <= 0) {
        (days[event.day] ??= []).add(event);
      }
    }
    final dates = days.keys.toList()..sort();
    DateTime? previous;
    var run = 0, learned = 0;

    // Bridges [gap] missed days after [from]. Freezes go first; one or two
    // remaining missed days can be earned back with two lessons on the two
    // days after the first miss. Returns whether the run survives.
    bool bridge(DateTime from, int gap) {
      final protected = math.min(gap, freezes);
      for (var i = 1; i <= protected; i++) {
        frozenDays.add(learningDay(from.add(Duration(days: i))));
      }
      freezes -= protected;
      final unprotected = gap - protected;
      if (unprotected == 0) return true;
      if (unprotected > 2 || run < earnBackMinimum) return false;
      final missed = from.add(Duration(days: protected + 1));
      final window = [
        learningDay(missed.add(const Duration(days: 1))),
        learningDay(missed.add(const Duration(days: 2))),
      ];
      final done = window.fold(0, (n, day) => n + (days[day]?.length ?? 0));
      if (done >= EarnBack.needed) {
        for (var i = 0; i < unprotected; i++) {
          repairedDays.add(learningDay(missed.add(Duration(days: i))));
        }
        return true;
      }
      if (today.compareTo(window.last) <= 0) {
        earnBack = EarnBack(streak: run, done: done, deadline: window.last);
      }
      return false;
    }

    for (final key in dates) {
      final date = parseLearningDay(key)!;
      if (previous == null) {
        freezes = startingFreezes;
      } else if (!bridge(previous, date.difference(previous).inDays - 1)) {
        run = 0;
      }
      run++;
      learned++;
      if (learned % 7 == 0) freezes = math.min(maxFreezes, freezes + 1);
      longestStreak = math.max(longestStreak, run);
      previous = date;
    }
    if (previous != null) {
      // Today stays open until midnight. Only past missed days use a freeze.
      final gap =
          math.max(0, parseLearningDay(today)!.difference(previous).inDays - 1);
      if (!bridge(previous, gap)) run = 0;
    }
    streak = run;
  }
  late final String today;
  final int dailyGoal;
  final Map<String, List<LearningActivity>> days = {};
  final Set<String> frozenDays = {};

  /// Missed days covered by a completed earn-back.
  final Set<String> repairedDays = {};

  /// Set while a recently broken streak can still be restored.
  EarnBack? earnBack;
  int streak = 0, longestStreak = 0, freezes = 0;

  /// The next celebration ahead of the current streak, or null after a year.
  int? get nextMilestone {
    for (final m in milestones) {
      if (m > streak) return m;
    }
    return null;
  }

  bool get learnedToday => days.containsKey(today);
  int get learningDays => days.length;
  List<DailyQuest> questsOn(String day) {
    final events = days[day] ?? <LearningActivity>[];
    return [
      DailyQuest('Earn 20 lesson XP', 'Learn something new or review.',
          events.fold(0, (n, e) => n + e.xp), 20),
      DailyQuest('Complete 2 different lessons', 'A second small step.',
          events.length, 2),
      DailyQuest('Get a check right first try', 'Put your knowledge to work.',
          events.where((e) => e.perfect).length, 1),
    ];
  }

  List<DailyQuest> get quests => questsOn(today);
  int xpOn(String day) =>
      (days[day] ?? []).fold(0, (n, e) => n + e.xp) +
      questsOn(day).where((q) => q.complete).length * 10;
  int get todayXp => xpOn(today);
  int get totalXp => days.keys.fold(0, (n, day) => n + xpOn(day));
  int get level => totalXp ~/ 100 + 1;
  int get levelXp => totalXp % 100;
  int get practiceCount =>
      days.values.expand((e) => e).where((e) => e.review).length;
  int get monthlyQuestCount => days.keys
      .where((d) => d.substring(0, 7) == today.substring(0, 7))
      .fold(0, (n, d) => n + questsOn(d).where((q) => q.complete).length);
  List<LearningBadge> get badges => [
        LearningBadge(
            'First spark', 'Complete your first lesson.', learningDays > 0),
        LearningBadge(
            'Finding a rhythm', 'Reach a 3-day streak.', longestStreak >= 3),
        LearningBadge(
            'A week of learning', 'Reach a 7-day streak.', longestStreak >= 7),
        LearningBadge(
            'Steady learner', 'Reach a 30-day streak.', longestStreak >= 30),
        LearningBadge('Practice pays off', 'Complete 5 lesson reviews.',
            practiceCount >= 5),
        LearningBadge('Knowledge builder', 'Earn 500 XP.', totalXp >= 500),
      ];
}

class LearningReward {
  const LearningReward(
      {required this.xp,
      required this.review,
      required this.stats,
      required this.newBadges,
      required this.extendedStreak,
      this.milestone,
      this.restoredStreak = false,
      this.freezeEarned = false});
  final int xp;
  final bool review, extendedStreak;

  /// True when this lesson completed an earn-back and restored the streak.
  final bool restoredStreak;

  /// True when this lesson refilled a streak freeze.
  final bool freezeEarned;

  /// The streak milestone this lesson reached, if any (7, 30, 100 or 365).
  final int? milestone;
  final LearningStats stats;
  final List<LearningBadge> newBadges;
}
