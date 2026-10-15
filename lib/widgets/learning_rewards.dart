import 'package:flutter/material.dart';
import '../data/learning_activity.dart';
import '../data/learning_store.dart';
import '../theme.dart';
import 'common.dart';

const _flame = Color(0xFFFFB15C);

Future<void> chooseDailyGoal(BuildContext context, LearningStore store) async {
  final goal = await showDialog<int>(
      context: context,
      builder: (context) =>
          SimpleDialog(title: const Text('Your daily XP goal'), children: [
            const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                    'One lesson or review keeps your streak alive. Your XP goal is an extra challenge.')),
            for (final entry in {
              10: 'Gentle · 10 XP',
              20: 'Steady · 20 XP',
              40: 'Focused · 40 XP'
            }.entries)
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, entry.key),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Icon(
                            store.dailyGoal == entry.key
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: SbdColors.cyan),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value))
                      ]))),
          ]));
  if (goal == null || !context.mounted) return;
  try {
    await store.setDailyGoal(goal);
    store.haptics.selectionChanged();
  } catch (_) {
    if (context.mounted) {
      showNotice(context, 'Your goal could not be saved. Try again.');
    }
  }
}

class DailyLearningCard extends StatelessWidget {
  const DailyLearningCard(
      {super.key, required this.store, this.onDetails, this.onLearn});
  final LearningStore store;
  final VoidCallback? onDetails;
  final VoidCallback? onLearn;
  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    return Panel(
        gradient: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 44, color: _flame),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${stats.streak}-day streak',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                      stats.learnedToday
                          ? 'You showed up today.'
                          : stats.streak > 0
                              ? 'One lesson keeps it going.'
                              : 'Your next lesson is day one.',
                      style:
                          const TextStyle(color: SbdColors.muted, height: 1.5)),
                ])),
          ]),
          const SizedBox(height: 22),
          LearningWeek(stats: stats),
          const SizedBox(height: 20),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${stats.todayXp} / ${stats.dailyGoal} XP today',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (stats.todayXp >= stats.dailyGoal)
                  const Text('Goal reached',
                      style: TextStyle(color: SbdColors.success)),
              ]),
          const SizedBox(height: 10),
          ProgressLine(value: (stats.todayXp / stats.dailyGoal).clamp(0, 1)),
          if (onLearn != null) ...[
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: onLearn,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                        stats.learnedToday ? 'Keep learning' : 'Learn today'))),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 4, children: [
            TextButton.icon(
                onPressed: () => chooseDailyGoal(context, store),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Daily goal')),
            if (onDetails != null)
              TextButton(
                  onPressed: onDetails, child: const Text('Quests & rewards')),
          ]),
        ]));
  }
}

/// A compact streak-and-goal strip for Home: the hero card leads with the
/// next lesson, so daily momentum shows small and stays one tap away.
class DailyStrip extends StatelessWidget {
  const DailyStrip({super.key, required this.store, this.onDetails});
  final LearningStore store;
  final VoidCallback? onDetails;
  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final today = parseLearningDay(stats.today)!;
    final first = today.subtract(const Duration(days: 6));
    return Panel(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 30, color: _flame),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${stats.streak}-day streak',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${stats.todayXp} / ${stats.dailyGoal} XP today',
                      style: const TextStyle(
                          color: SbdColors.muted, fontSize: 13)),
                ])),
            const SizedBox(width: 10),
            Semantics(
                label: 'Your learning week',
                child: ExcludeSemantics(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Builder(builder: (context) {
                          final key =
                              learningDay(first.add(Duration(days: i)));
                          final active = stats.days.containsKey(key);
                          final frozen = stats.frozenDays.contains(key);
                          final isToday = key == stats.today;
                          return Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? _flame.withValues(alpha: .22)
                                      : frozen
                                          ? SbdColors.cyan
                                              .withValues(alpha: .15)
                                          : SbdColors.surface,
                                  border: Border.all(
                                      color: isToday
                                          ? _flame
                                          : active
                                              ? _flame.withValues(alpha: .6)
                                              : SbdColors.border,
                                      width: isToday ? 2 : 1)));
                        })),
                ]))),
          ]),
          const SizedBox(height: 14),
          ProgressLine(value: (stats.todayXp / stats.dailyGoal).clamp(0, 1)),
          const SizedBox(height: 2),
          Wrap(spacing: 10, children: [
            TextButton.icon(
                onPressed: () => chooseDailyGoal(context, store),
                icon: const Icon(Icons.tune, size: 17),
                label: const Text('Daily goal')),
            if (onDetails != null)
              TextButton(
                  onPressed: onDetails, child: const Text('Quests & rewards')),
          ]),
        ]));
  }
}

class LearningWeek extends StatelessWidget {
  const LearningWeek({super.key, required this.stats});
  final LearningStats stats;
  @override
  Widget build(BuildContext context) {
    final today = parseLearningDay(stats.today)!;
    final first = today.subtract(const Duration(days: 6));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < 7; i++)
        Expanded(child: Builder(builder: (context) {
          final date = first.add(Duration(days: i)), key = learningDay(date);
          final active = stats.days.containsKey(key),
              frozen = stats.frozenDays.contains(key);
          final isToday = key == stats.today;
          return Semantics(
              label:
                  '$key, ${active ? 'lesson complete' : frozen ? 'streak freeze used' : date.isAfter(today) ? 'upcoming' : 'no lesson yet'}${isToday ? ', today' : ''}',
              child: ExcludeSemantics(
                  child: Column(children: [
                Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
                    style:
                        const TextStyle(color: SbdColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? _flame.withValues(alpha: .17)
                            : frozen
                                ? SbdColors.cyan.withValues(alpha: .12)
                                : SbdColors.surface,
                        border: Border.all(
                            color: isToday ? _flame : SbdColors.border,
                            width: isToday ? 2 : 1)),
                    child: Icon(
                        active
                            ? Icons.check_rounded
                            : frozen
                                ? Icons.ac_unit_rounded
                                : Icons.circle,
                        size: active || frozen ? 17 : 5,
                        color: active
                            ? _flame
                            : frozen
                                ? SbdColors.cyan
                                : SbdColors.muted)),
                const SizedBox(height: 6),
                Text('${date.day}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isToday ? SbdColors.ink : SbdColors.muted)),
              ])));
        })),
    ]);
  }
}

class LearningDashboard extends StatelessWidget {
  const LearningDashboard(
      {super.key, required this.store, required this.onPractice});
  final LearningStore store;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DailyLearningCard(store: store),
      const SizedBox(height: 16),
      StreakCalendar(stats: stats),
      const SizedBox(height: 16),
      Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 24, runSpacing: 16, children: [
          _Stat(Icons.bolt_rounded, '${stats.totalXp}', 'Total XP'),
          _Stat(Icons.workspace_premium_outlined, '${stats.level}', 'Level'),
          _Stat(Icons.local_fire_department_outlined, '${stats.longestStreak}',
              'Best streak'),
        ]),
        const SizedBox(height: 18),
        ProgressLine(value: stats.levelXp / 100),
        const SizedBox(height: 8),
        Text('${100 - stats.levelXp} XP to level ${stats.level + 1}',
            style: const TextStyle(color: SbdColors.muted)),
        const SizedBox(height: 22),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.ac_unit_rounded, color: SbdColors.cyan),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${stats.freezes} of 2 streak freezes ready',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text(
                    'You start with two freezes. Each one automatically protects a missed day. Earn another every 7 active days, up to 2. Missed a day with none left? Finish two lessons over the next two days to earn your streak back.',
                    style: TextStyle(color: SbdColors.muted, height: 1.5)),
              ])),
        ]),
      ])),
      const SizedBox(height: 26),
      Text('Daily quests', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      const Text('A fresh start every day. +10 XP for each quest.',
          style: TextStyle(color: SbdColors.muted)),
      const SizedBox(height: 14),
      for (final quest in stats.quests)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
                padding: const EdgeInsets.all(18),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          quest.complete
                              ? Icons.check_circle_rounded
                              : Icons.flag_outlined,
                          color: quest.complete
                              ? SbdColors.success
                              : SbdColors.cyan),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(quest.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text(quest.detail,
                                style: const TextStyle(
                                    color: SbdColors.muted, height: 1.5)),
                            const SizedBox(height: 12),
                            ProgressLine(value: quest.progress),
                            const SizedBox(height: 6),
                            Text(
                                quest.complete
                                    ? '+10 XP earned'
                                    : '${quest.current} / ${quest.target}',
                                style: TextStyle(
                                    color: quest.complete
                                        ? SbdColors.success
                                        : SbdColors.muted)),
                          ])),
                    ]))),
      const SizedBox(height: 6),
      FilledButton.icon(
          onPressed: onPractice,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(store.practiceLesson == null
              ? 'Start a lesson'
              : 'Practice what you know')),
      const SizedBox(height: 24),
      Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Kicker('This month'),
        const SizedBox(height: 10),
        Text(
            stats.monthlyQuestCount >= 30
                ? 'Monthly challenge complete!'
                : 'Build a month of momentum.',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ProgressLine(value: (stats.monthlyQuestCount / 30).clamp(0, 1)),
        const SizedBox(height: 8),
        Text('${stats.monthlyQuestCount} / 30 daily quests completed'),
      ])),
      const SizedBox(height: 26),
      Text('Your achievements', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      for (final badge in stats.badges)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                    badge.earned
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    color: badge.earned ? _flame : SbdColors.muted),
                title: Text(badge.title),
                subtitle: Text(badge.detail),
                trailing: badge.earned
                    ? const Icon(Icons.check, color: SbdColors.success)
                    : null)),
      const SizedBox(height: 12),
      const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('How streaks and XP work'),
          children: [
            Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                    'Complete a lesson or review to extend your streak. New lessons earn 20 XP, reviews earn 10 XP, and a correct first answer adds 5 XP. Each lesson earns XP once per calendar day. Quest rewards are added automatically.\n\n'
                    'If you miss a day without a freeze, finishing two lessons on the next two days restores a streak of 3 days or more. Big celebrations happen at 7, 30, 100 and 365 days.\n\n'
                    'Days follow your device’s local calendar when you learn. A freeze keeps the streak intact but adds no learning day or XP. Older completions stay saved; dated streak activity begins with this update. Your daily XP goal is saved on this device.',
                    style: TextStyle(color: SbdColors.muted, height: 1.6))),
          ]),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: SbdColors.cyan),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: const TextStyle(color: SbdColors.muted)),
      ]);
}

class LessonCelebration extends StatelessWidget {
  const LessonCelebration(
      {super.key,
      required this.reward,
      required this.onContinue,
      this.onMemberships});
  final LearningReward reward;
  final VoidCallback onContinue;
  final VoidCallback? onMemberships;
  static const _milestoneCopy = {
    7: ('One full week.',
        'Seven days in a row. This is where a habit starts to stick.'),
    30: ('A month of showing up.',
        'Thirty days straight. That’s real momentum.'),
    100: ('100 days. That’s a habit.',
        'You’ve practiced 100 days in a row.'),
    365: ('A full year.', '365 days of steady practice.'),
  };

  @override
  Widget build(BuildContext context) {
    final milestone = reward.milestone;
    final copy = milestone == null ? null : _milestoneCopy[milestone];
    final next = reward.stats.nextMilestone;
    return PageContent(maxWidth: 620, children: [
        const SizedBox(height: 16),
        if (milestone != null)
          MilestoneEmblem(days: milestone)
        else
          TweenAnimationBuilder<double>(
              tween: Tween(begin: .85, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: _flame, size: 92)),
        const SizedBox(height: 24),
        Text(
            copy?.$1 ??
                (reward.restoredStreak
                    ? 'Streak restored.'
                    : reward.review
                        ? 'Knowledge, reinforced.'
                        : 'Another step forward.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge),
        if (copy != null) ...[
          const SizedBox(height: 10),
          Text(copy.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SbdColors.ink, height: 1.6)),
        ],
        const SizedBox(height: 14),
        Text(reward.xp > 0 ? '+${reward.xp} XP' : 'Practice complete',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: SbdColors.cyan)),
        const SizedBox(height: 10),
        Text(
            reward.xp > 0
                ? 'Your learning and quest rewards are saved.'
                : 'You already earned XP for this lesson today. Your knowledge still grows.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: SbdColors.muted, height: 1.6)),
        const SizedBox(height: 24),
        Panel(
            gradient: true,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${reward.stats.streak}-day streak',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                  reward.restoredStreak
                      ? 'Welcome back. Your streak is whole again.'
                      : reward.extendedStreak
                          ? 'Today counts. Come back tomorrow.'
                          : 'Your streak is safe for today.',
                  style: const TextStyle(color: SbdColors.muted)),
              const SizedBox(height: 18),
              LearningWeek(stats: reward.stats),
              if (milestone == null &&
                  next != null &&
                  next - reward.stats.streak <= 2 &&
                  reward.stats.learnedToday) ...[
                const SizedBox(height: 16),
                Text(
                    next - reward.stats.streak == 1
                        ? 'One more day to your $next-day milestone.'
                        : 'Two more days to your $next-day milestone.',
                    style: const TextStyle(color: SbdColors.cyan)),
              ],
            ])),
        if (reward.freezeEarned) ...[
          const SizedBox(height: 12),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.ac_unit_rounded, color: SbdColors.cyan),
              title: Text('You earned a streak freeze'),
              subtitle: Text('It protects a missed day automatically.')),
        ],
        const SizedBox(height: 16),
        for (final badge in reward.newBadges)
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_rounded, color: _flame),
              title: Text(badge.title),
              subtitle: const Text('Achievement unlocked')),
        const SizedBox(height: 24),
        FilledButton(onPressed: onContinue, child: const Text('Continue')),
        if (onMemberships != null) ...[
          const SizedBox(height: 12),
          TextButton(
              onPressed: onMemberships,
              child: const Text('Membership options in My Account')),
        ],
      ]);
  }
}

/// The milestone hero: a short spring-in that is skipped when the device
/// asks for reduced motion. Shown only at 7, 30, 100 and 365 days.
class MilestoneEmblem extends StatelessWidget {
  const MilestoneEmblem({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
        label: '$days-day streak milestone',
        child: ExcludeSemantics(
            child: Center(
                child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 1.0 : .6, end: 1),
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SbdColors.surface,
                            border: Border.all(color: _flame, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: _flame.withValues(alpha: .28),
                                  blurRadius: 48,
                                  spreadRadius: 4)
                            ]),
                        child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: FittedBox(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: _flame,
                                      size: 34),
                                  Text('$days',
                                      style: const TextStyle(
                                          color: SbdColors.ink,
                                          fontSize: 56,
                                          height: 1,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  const Text('DAY STREAK',
                                      style: TextStyle(
                                          color: SbdColors.muted,
                                          fontSize: 11,
                                          letterSpacing: 1.6)),
                                ]))))))));
  }
}

/// A supportive restore offer for Home. It never shows the broken streak
/// as a loss; it shows the way back, and the learner can ignore it.
class EarnBackCard extends StatefulWidget {
  const EarnBackCard({super.key, required this.store, required this.onLearn});
  final LearningStore store;
  final VoidCallback onLearn;

  @override
  State<EarnBackCard> createState() => _EarnBackCardState();
}

class _EarnBackCardState extends State<EarnBackCard> {
  @override
  void initState() {
    super.initState();
    widget.store.noteEarnBackOffered();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.store.stats;
    final offer = stats.earnBack;
    if (offer == null) return const SizedBox.shrink();
    final remaining = offer.remaining;
    final when = offer.deadline == stats.today ? 'today' : 'tomorrow';
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.restart_alt_rounded,
                size: 30, color: SbdColors.cyan),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    'Your ${offer.streak}-day streak is still in reach.',
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 10),
          Text(
              'Finish $remaining more ${remaining == 1 ? 'lesson' : 'lessons'} by the end of $when and we’ll restore it, free.',
              style: const TextStyle(color: SbdColors.muted, height: 1.55)),
          const SizedBox(height: 14),
          Semantics(
              label:
                  'Earn-back progress, ${offer.done} of ${EarnBack.needed} lessons',
              child: ExcludeSemantics(
                  child: ProgressLine(
                      value: (offer.done / EarnBack.needed).clamp(0, 1)))),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: widget.onLearn,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start a lesson'))),
        ])));
  }
}

/// This month at a glance: practiced, frozen and restored days.
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key, required this.stats});
  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    final today = parseLearningDay(stats.today)!;
    final first = DateTime.utc(today.year, today.month);
    final daysInMonth = DateTime.utc(today.year, today.month + 1, 0).day;
    final lead = first.weekday - 1; // Monday-first, like the learning week.
    final practiced = stats.days.keys
        .where((d) => d.substring(0, 7) == stats.today.substring(0, 7))
        .length;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${months[today.month - 1]} ${today.year}',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
          '$practiced ${practiced == 1 ? 'day' : 'days'} practiced this month',
          style: const TextStyle(color: SbdColors.muted)),
      const SizedBox(height: 16),
      ExcludeSemantics(
          child: Row(children: [
        for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
          Expanded(
              child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          color: SbdColors.muted, fontSize: 12)))),
      ])),
      const SizedBox(height: 8),
      GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _CalendarDay(
                  date: DateTime.utc(today.year, today.month, day),
                  stats: stats),
          ]),
      const SizedBox(height: 14),
      const Wrap(spacing: 16, runSpacing: 8, children: [
        _Legend(color: _flame, label: 'Practiced'),
        _Legend(color: SbdColors.cyan, label: 'Freeze used'),
        _Legend(color: SbdColors.cyan, label: 'Earned back', outline: true),
      ]),
    ]));
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.date, required this.stats});
  final DateTime date;
  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    final key = learningDay(date);
    final active = stats.days.containsKey(key),
        frozen = stats.frozenDays.contains(key),
        repaired = stats.repairedDays.contains(key),
        isToday = key == stats.today,
        future = key.compareTo(stats.today) > 0;
    final state = active
        ? 'practiced'
        : frozen
            ? 'freeze used'
            : repaired
                ? 'earned back'
                : future
                    ? 'upcoming'
                    : 'no lesson';
    return Semantics(
        label: '$key, $state${isToday ? ', today' : ''}',
        child: ExcludeSemantics(
            child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? _flame.withValues(alpha: .2)
                        : frozen
                            ? SbdColors.cyan.withValues(alpha: .16)
                            : Colors.transparent,
                    border: Border.all(
                        color: isToday
                            ? SbdColors.ink
                            : repaired
                                ? SbdColors.cyan
                                : Colors.transparent,
                        width: isToday || repaired ? 1.5 : 0)),
                child: Center(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text('${date.day}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: future
                                        ? SbdColors.muted
                                            .withValues(alpha: .6)
                                        : active
                                            ? SbdColors.ink
                                            : SbdColors.muted))))))));
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, this.outline = false});
  final Color color;
  final String label;
  final bool outline;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outline ? Colors.transparent : color.withValues(alpha: .3),
                border: Border.all(color: color, width: 1.5))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: SbdColors.muted, fontSize: 12)),
      ]);
}
