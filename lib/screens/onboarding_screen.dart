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
          const Kicker('A note from the creator'),
          const SizedBox(height: 20),
          Text('Hi, I’m Jon.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Text(
              'I built Secure By Design to help you connect what you learn to the systems you build and protect.\n\n'
              'You don’t need to know everything before you start. Pick one lesson, try the idea, and keep going at your own pace.\n\n'
              'If something here helps you, pay us back by sharing our content with someone who could use it.\n\n'
              'I’m glad you’re here.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          const Text('Jon',
              style: TextStyle(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  color: SbdColors.cyan)),
          const Text('Creator, Secure By Design'),
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
      (_step != 1 || _goals.isNotEmpty) &&
      (_step != 2 || _start != null);

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
            const Brand(),
            const SizedBox(height: 32),
            _heading('Build confidence.\nOne lesson at a time.',
                'Understand the systems you build and the security decisions behind them. Let’s find your first useful step.'),
            Panel(
                gradient: true,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('From learning to doing'),
                      const SizedBox(height: 18),
                      const _Outcome(
                          icon: Icons.hub_outlined,
                          title: 'Build the identity foundation',
                          body:
                              'Follow DC01 + DC02 through Active Directory and DNS.'),
                      const SizedBox(height: 20),
                      const _Outcome(
                          icon: Icons.verified_user_outlined,
                          title: 'Turn security decisions into evidence',
                          body:
                              'Work through RMF, the Body of Evidence, and authorization.'),
                    ])),
            const SizedBox(height: 22),
            const Text(
                'Two quick questions. A plan you can change. Start learning without an account.'),
          ],
        1 => [
            _heading('What brings you here?',
                'Choose one or more goals. Your answers decide which lessons we recommend.'),
            for (final goal in LearningGoal.values)
              _Choice(
                  label: goal.label,
                  body: goal.description,
                  selected: _goals.contains(goal),
                  onTap: () {
                    widget.store.haptics.selectionChanged();
                    setState(() => _goals.contains(goal)
                        ? _goals.remove(goal)
                        : _goals.add(goal));
                  }),
            const SizedBox(height: 12),
            const Text('Your choices stay on this device.'),
          ],
        2 => [
            _heading('Where would you like to start?',
                'There’s no test to pass here. Choose the approach that feels useful today.'),
            for (final start in LearningStart.values)
              _Choice(
                  label: start.label,
                  body: start.description,
                  selected: _start == start,
                  onTap: () {
                    if (_start == start) return;
                    widget.store.haptics.selectionChanged();
                    setState(() => _start = start);
                  }),
          ],
        3 => [
            _heading('Your starting point is ready.',
                'Here’s what your answers unlocked. You can explore every course whenever you like.'),
            Text(_profile.reason,
                style: const TextStyle(color: SbdColors.cyan)),
            const SizedBox(height: 22),
            for (final id in _profile.pathIds) _recommendation(id),
            const SizedBox(height: 12),
            const Text(
                'A simple rhythm: learn one idea, check your understanding, then save a reference for next time.'),
          ],
        _ => [
            const CreatorNote(),
            const SizedBox(height: 20),
            const Text('Learn it. Share it. Pay it forward.',
                style: TextStyle(color: SbdColors.cyan))
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
                          child: Text('Step ${_step + 1} of 5',
                              style: const TextStyle(color: SbdColors.cyan)))),
                  TextButton(
                      onPressed: _saving ? null : _close,
                      child: Text(widget.firstRun ? 'Skip' : 'Close')),
                ])),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 5,
                  minHeight: 4,
                    semanticsLabel: 'Welcome progress, step ${_step + 1} of 5',
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
                            : _step == 4
                                ? () => _finish(startLesson: true)
                                : () => _move(_step + 1),
                        child: Text(_saving
                            ? 'Saving…'
                            : switch (_step) {
                                0 => 'Find my starting point',
                                1 => 'Continue',
                                2 => 'Show my plan',
                                3 => 'A note before you begin',
                                _ => 'Start my first lesson',
                              }),
                      )),
                  if (_step == 4)
                    TextButton(
                        onPressed:
                            _saving ? null : () => _finish(startLesson: false),
                        child: const Text('Explore my plan first')),
                ])),
          ]),
        )))),
      );
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label,
      required this.body,
      required this.selected,
      required this.onTap});
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
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
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

class _Outcome extends StatelessWidget {
  const _Outcome({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: SbdColors.cyan),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
        ])),
      ]);
}
