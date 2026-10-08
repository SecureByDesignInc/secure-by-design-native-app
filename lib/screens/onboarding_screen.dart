import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../data/onboarding.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'path_screen.dart';

Future<void> openOnboarding(BuildContext context, LearningStore store,
    {bool firstRun = false}) async {
  final startLesson = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
        builder: (_) => OnboardingScreen(store: store, firstRun: firstRun)),
  );
  if (startLesson != true || !context.mounted) return;
  final profile = store.gettingStarted.profile;
  if (profile == null) return;
  final path = learningPaths.firstWhere((p) => p.id == profile.pathIds.first);
  try {
    await store.openPath(path.id);
  } catch (_) {
    if (context.mounted) {
      showNotice(context,
          'Your plan is saved. Your place in this lesson could not be saved yet.');
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(MaterialPageRoute(
    builder: (_) => LessonScreen(
        store: store,
        path: path,
        lesson: store.nextLesson(path) ?? path.lessons.first),
  ));
}

class CreatorNote extends StatelessWidget {
  const CreatorNote({super.key});

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Kicker('A note from Secure By Design'),
          const SizedBox(height: 20),
          Text('Hi, we’re Secure By Design.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Text(
              'We built Secure By Design to help you connect what you learn to the systems you build and protect.\n\n'
              'You don’t need to know everything before you start. Pick one lesson, try the idea, and keep going at your own pace.\n\n'
              'If something here helps you, help someone else find it — share it with someone who could use it.\n\n'
              'We’re glad you’re here.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          const Text('Secure By Design',
              style: TextStyle(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  color: SbdColors.cyan)),
        ]),
      );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen(
      {super.key, required this.store, this.firstRun = false});
  final LearningStore store;
  final bool firstRun;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;
  late Set<LearningGoal> _goals;
  LearningStart? _start;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final saved = widget.store.gettingStarted.profile;
    _goals = {...?saved?.goals};
    _start = saved?.start;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  OnboardingProfile get _profile =>
      OnboardingProfile(goals: _goals, start: _start!);
  bool get _canContinue =>
      !_saving &&
      (_step != 0 || _goals.isNotEmpty) &&
      (_step != 1 || _start != null);

  void _move(int step) {
    if (_saving) return;
    widget.store.haptics.selectionChanged();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _step = step);
  }

  Future<void> _finish({required bool startLesson, bool skip = false}) async {
    if (_saving || widget.store.gettingStarted.busy) return;
    setState(() => _saving = true);
    try {
      await widget.store.gettingStarted
          .finishWelcome(profile: skip ? null : _profile);
      widget.store.analytics
          .onboardingFinished(skipped: skip, startedLesson: startLesson);
      if (mounted) Navigator.pop(context, startLesson);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showNotice(context, 'Could not save your plan. Please try again.');
      }
    }
  }

  void _close() {
    if (_saving) return;
    if (widget.firstRun) {
      _finish(startLesson: false, skip: true);
    } else {
      Navigator.pop(context, false);
    }
  }

  Widget _heading(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ]),
      );

  List<Widget> _content() => switch (_step) {
        0 => [
            if (widget.firstRun) ...[
              Center(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/brand/brand-mark.png',
                          width: 92, height: 92))),
              const SizedBox(height: 18),
              const Center(
                  child: Kicker('Cybersecurity starts with curiosity')),
              const SizedBox(height: 10),
              Center(
                  child: Text('Learn security by building it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium)),
              const SizedBox(height: 30),
            ] else ...[
              const Brand(compact: true),
              const SizedBox(height: 28),
            ],
            _heading('What would you like to learn?',
                'Choose one or more goals. We’ll help you find a useful place to begin.'),
            for (final goal in LearningGoal.values)
              _Choice(
                  icon: switch (goal) {
                    LearningGoal.build => Icons.hub_outlined,
                    LearningGoal.authorize => Icons.verified_user_outlined,
                    LearningGoal.monitor => Icons.insights_outlined,
                  },
                  label: goal.label,
                  body: goal.description,
                  selected: _goals.contains(goal),
                  onTap: () {
                    widget.store.haptics.selectionChanged();
                    setState(() => _goals.contains(goal)
                        ? _goals.remove(goal) : _goals.add(goal));
                  }),
            const SizedBox(height: 8),
            const Text('Two quick choices. Learn at your own pace. Sign-in is optional.'),
          ],
        1 => [
            _heading('Where are you starting from?',
                'Pick the level that feels right today. You can change your plan in My Account.'),
            LayoutBuilder(builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 20;
              return Wrap(spacing: 16, children: [
                for (final start in LearningStart.values)
                  SizedBox(width: twoColumns
                      ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                      child: _Choice(
                          icon: start == LearningStart.foundations
                              ? Icons.school_outlined : Icons.terminal_outlined,
                          label: start.label,
                          body: start.description,
                          selected: _start == start,
                          onTap: () {
                            if (_start == start) return;
                            widget.store.haptics.selectionChanged();
                            setState(() => _start = start);
                          })),
              ]);
            }),
            const SizedBox(height: 12),
            const Panel(child: Text(
                'Every course remains available. Your choice simply helps us recommend your first lesson.')),
          ],
        _ => [
            _heading('Your starting point is ready.',
                'A practical next step, chosen for your goals and experience.'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final goal in _goals)
                ActionChip(label: Text(goal.label), onPressed: () => _move(0)),
              ActionChip(label: Text(_start!.label), onPressed: () => _move(1)),
            ]),
            const SizedBox(height: 22),
            for (final id in _profile.pathIds) _recommendation(id),
            const Text('Learn one idea, check your understanding, then save a useful reference.'),
            const SizedBox(height: 24),
            Text('Set a daily goal',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
                'Small and steady beats cramming. You can change this anytime.'),
            const SizedBox(height: 12),
            AnimatedBuilder(
                animation: widget.store,
                builder: (context, _) =>
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final goal in const {
                        10: 'Gentle · 10 XP',
                        20: 'Steady · 20 XP',
                        40: 'Focused · 40 XP'
                      }.entries)
                        ChoiceChip(
                            label: Text(goal.value),
                            selected: widget.store.dailyGoal == goal.key,
                            onSelected: (_) async {
                              try {
                                await widget.store.setDailyGoal(goal.key);
                                widget.store.haptics.selectionChanged();
                              } catch (_) {
                                if (context.mounted) {
                                  showNotice(context,
                                      'Your goal could not be saved. Try again.');
                                }
                              }
                            }),
                    ])),
            const SizedBox(height: 24),
            _AnalyticsChoice(store: widget.store),
            const SizedBox(height: 16),
            const ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('A note from Secure By Design'),
                children: [CreatorNote()]),
            const SizedBox(height: 12),
            const Text('Your learning choices stay on this device.'),
          ],
      };

  Widget _recommendation(String id) {
    final path = learningPaths.firstWhere((p) => p.id == id);
    final lesson = widget.store.nextLesson(path) ?? path.lessons.first;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Panel(
          gradient: id == _profile.pathIds.first,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(id == _profile.pathIds.first
                ? 'Start here · ${lesson.minutes} min'
                : 'Also in your plan · ${lesson.minutes} min'),
            const SizedBox(height: 12),
            Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(lesson.summary),
            const SizedBox(height: 14),
            Text(path.title, style: const TextStyle(color: SbdColors.cyan)),
          ]),
        ));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !widget.firstRun && _step == 0 && !_saving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving) {
            if (_step > 0) {
              _move(_step - 1);
            } else {
              _close();
            }
          }
        },
        child: Scaffold(
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
                child: Row(children: [
                  if (_step > 0)
                    IconButton(
                        tooltip: 'Previous step',
                        onPressed: _saving ? null : () => _move(_step - 1),
                        icon: const Icon(Icons.arrow_back)),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text('Step ${_step + 1} of 3',
                              style: const TextStyle(color: SbdColors.cyan)))),
                  TextButton(
                      onPressed: _saving ? null : _close,
                      child: Text(widget.firstRun ? 'Skip' : 'Close')),
                ])),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  minHeight: 4,
                    semanticsLabel: 'Welcome progress, step ${_step + 1} of 3',
                  borderRadius: BorderRadius.circular(8),
                )),
            Expanded(
                child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: Duration(
                    milliseconds:
                        MediaQuery.disableAnimationsOf(context) ? 0 : 180),
                child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _content()),
              ),
            )),
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                child: Column(children: [
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: !_canContinue
                            ? null
                            : _step == 2
                                ? () => _finish(startLesson: true)
                                : () => _move(_step + 1),
                        child: Text(_saving
                            ? 'Saving…'
                            : switch (_step) {
                                0 => 'Continue',
                                1 => 'Show my plan',
                                _ => 'Start my first lesson',
                              }),
                      )),
                  if (_step == 2)
                    TextButton(
                        onPressed:
                            _saving ? null : () => _finish(startLesson: false),
                        child: const Text('Save my plan for later')),
                ])),
          ]),
        )))),
      );
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.icon,
      required this.label,
      required this.body,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String label, body;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Semantics(
            button: true,
            selected: selected,
            child: Material(
              color: selected ? SbdColors.surface : SbdColors.surfaceLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                      color: selected ? SbdColors.cyan : SbdColors.border)),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              selected ? Icons.check_circle_rounded : icon,
                              color:
                                  selected ? SbdColors.cyan : SbdColors.muted),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Text(body),
                              ])),
                        ])),
              ),
            )),
      );
}

/// An honest, optional ask at the moment it makes sense. Neither answer is
/// preselected and the learner can continue without choosing.
class _AnalyticsChoice extends StatefulWidget {
  const _AnalyticsChoice({required this.store});
  final LearningStore store;
  @override
  State<_AnalyticsChoice> createState() => _AnalyticsChoiceState();
}

class _AnalyticsChoiceState extends State<_AnalyticsChoice> {
  bool _declined = false;

  Future<void> _set(bool value) async {
    final analytics = widget.store.analytics;
    widget.store.haptics.selectionChanged();
    try {
      await analytics.setEnabled(value);
      if (mounted) setState(() => _declined = !value);
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Could not save this choice. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store.analytics,
      builder: (context, _) {
        final analytics = widget.store.analytics;
        return Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Kicker('Optional'),
          const SizedBox(height: 10),
          Text('Help us improve the app?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
              'Share anonymous usage, like lessons finished and streak milestones, '
              'so we can see what helps. No name, email, or answer text. '
              'Change it anytime in My Account.',
              style: TextStyle(color: SbdColors.muted, height: 1.55)),
          const SizedBox(height: 14),
          if (analytics.enabled)
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: SbdColors.cyan),
              const SizedBox(width: 10),
              const Expanded(child: Text('Thanks. Sharing is on.')),
              TextButton(
                  onPressed: analytics.changing ? null : () => _set(false),
                  child: const Text('Turn off')),
            ])
          else if (_declined)
            Row(children: [
              const Expanded(
                  child: Text('Not sharing.',
                      style: TextStyle(color: SbdColors.muted))),
              TextButton(
                  onPressed: analytics.changing ? null : () => _set(true),
                  child: const Text('Share instead')),
            ])
          else
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.tonal(
                  onPressed: analytics.changing ? null : () => _set(true),
                  child: const Text('Yes, share anonymously')),
              OutlinedButton(
                  onPressed: analytics.changing ? null : () => _set(false),
                  child: const Text('No thanks')),
            ]),
        ]));
      });
}
