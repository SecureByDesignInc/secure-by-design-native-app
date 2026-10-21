import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/catalog.dart';
import '../data/learning_activity.dart';
import '../widgets/learning_rewards.dart';
import '../widgets/lesson_video.dart';
import '../data/learning_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'course_screen.dart';
import 'lab_mode_screen.dart';

Future<void> openLearningPath(
  BuildContext context,
  LearningStore store,
  LearningPath path, {
  bool showMaterials = false,
}) async {
  try {
    await store.openPath(path.id);
  } catch (_) {
    if (context.mounted) {
      showNotice(context, 'Your place could not be saved on this device.');
    }
  }
  if (context.mounted) {
    store.analytics.pathOpened(path.id);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => path.published
            ? CourseScreen(
                store: store, path: path, initialTab: showMaterials ? 2 : 0)
            : PathScreen(store: store, path: path),
      ),
    );
  }
}

Future<void> openPractice(BuildContext context, LearningStore store) async {
  final lesson = store.practiceLesson ??
      store.nextLesson(store.currentPath) ??
      store.currentPath.lessons.first;
  final path =
      learningPaths.firstWhere((p) => p.lessons.any((l) => l.id == lesson.id));
  await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LessonScreen(
          store: store,
          lesson: lesson,
          path: path,
          practice: store.isCompleted(lesson.id))));
}

class PathScreen extends StatelessWidget {
  const PathScreen({super.key, required this.store, required this.path});
  final LearningStore store;
  final LearningPath path;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final next = store.nextLesson(path);
          return Scaffold(
            appBar: AppBar(
              title: Text(path.category, style: const TextStyle(fontSize: 16)),
            ),
            body: PageContent(
              maxWidth: 760,
              children: [
                TopicBadge(path.icon, size: 60),
                const SizedBox(height: 24),
                Text(path.title,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 14),
                Text(
                  path.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${path.lessons.length} short lessons',
                      style: const TextStyle(color: SbdColors.ink),
                    ),
                    Text(
                      'About ${path.minutes} min',
                      style: const TextStyle(color: SbdColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your progress',
                              style: TextStyle(color: SbdColors.ink),
                            ),
                          ),
                          Text(
                            '${store.completedIn(path)} / ${path.lessons.length}',
                            style: const TextStyle(color: SbdColors.cyan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ProgressLine(value: store.progressIn(path)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (next != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LessonScreen(
                              store: store, lesson: next, path: path),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        store.completedIn(path) == 0
                            ? 'Start the first lesson'
                            : 'Continue learning',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: SbdColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You completed this path. Revisit any lesson below.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                const Kicker('Inside this path'),
                const SizedBox(height: 14),
                for (var i = 0; i < path.lessons.length; i++) ...[
                  _LessonRow(
                    index: i,
                    lesson: path.lessons[i],
                    completed: store.isCompleted(path.lessons[i].id),
                    current: next != null && path.lessons[i].id == next.id,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LessonScreen(
                          store: store,
                          lesson: path.lessons[i],
                          path: path,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Sample learning path · Original explanations with links to official references.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.completed,
    required this.onTap,
    this.current = false,
  });
  final int index;
  final Lesson lesson;
  final bool completed;
  final bool current;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current
                    ? SbdColors.cyan.withValues(alpha: 0.14)
                    : SbdColors.surface,
                border: Border.all(
                  color: completed
                      ? SbdColors.success.withValues(alpha: 0.5)
                      : current
                          ? SbdColors.cyan
                          : SbdColors.border,
                ),
              ),
              child: Center(
                child: completed
                    ? const Icon(
                        Icons.check,
                        color: SbdColors.success,
                        size: 21,
                      )
                    : current
                        ? const Icon(
                            Icons.play_arrow_rounded,
                            color: SbdColors.cyan,
                            size: 22,
                          )
                        : Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: const TextStyle(color: SbdColors.muted),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: completed || current
                          ? SbdColors.ink
                          : SbdColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed
                        ? 'Completed · ${lesson.minutes} min'
                        : current
                            ? 'Up next · ${lesson.minutes} min'
                            : '${lesson.minutes} min · Read & reflect',
                    style: const TextStyle(
                      color: SbdColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: SbdColors.muted, size: 20),
          ],
        ),
      );
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.store,
    required this.lesson,
    required this.path,
    this.practice = false,
  });
  final bool practice;
  final LearningStore store;
  final Lesson lesson;
  final LearningPath path;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.analytics.lessonOpened(widget.lesson.id);
    widget.store.startLesson(widget.lesson.id).catchError((Object _) {});
  }

  late final List<QuizQuestion> _questions = widget.lesson.questions;
  late final List<int?> _answers = List.filled(_questions.length, null);
  bool _saving = false;
  bool _madeMistake = false;
  LearningReward? _reward;
  bool _isCorrect(int q) => _answers[q] == _questions[q].correctAnswer;

  /// Every knowledge check must be answered correctly before completion.
  bool get _correct =>
      Iterable<int>.generate(_questions.length).every(_isCorrect);

  Future<void> _complete() async {
    setState(() => _saving = true);
    final scope = widget.store.accountScope;
    try {
      final reward = await widget.store
          .finishLesson(widget.lesson.id, perfect: !_madeMistake);
      if (!mounted) return;
      if (scope != widget.store.accountScope || reward == null) {
        setState(() => _saving = false);
        showNotice(context,
            'Your account changed. Complete this lesson for the current learner.');
        return;
      }
      widget.store.haptics.lessonCompleted();
      setState(() => _reward = reward);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showNotice(context, 'Progress could not be saved. Please try again.');
      }
    }
  }

  Widget _question(BuildContext context, Lesson lesson, int q) {
    final question = _questions[q], answer = _answers[q];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(_questions.length == 1
              ? 'Pause & reflect'
              : 'Check ${q + 1} of ${_questions.length}'),
          const SizedBox(height: 14),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < question.answers.length; i++) ...[
            Semantics(
              selected: answer == i,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (answer == i) return;
                          setState(() {
                            _answers[q] = i;
                            if (!_isCorrect(q)) _madeMistake = true;
                          });
                          widget.store.haptics.selectionChanged();
                          widget.store.analytics.knowledgeCheckSubmitted(
                            lesson.id,
                            i == question.correctAnswer,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                      color: answer == i ? SbdColors.cyan : SbdColors.border,
                    ),
                    backgroundColor: answer == i
                        ? SbdColors.cyan.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        answer == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 19,
                        color: answer == i ? SbdColors.cyan : SbdColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(question.answers[i])),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (answer != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isCorrect(q)
                      ? question.explanation
                      : 'Try again. Revisit the explanation above and choose another answer.',
                  style: TextStyle(
                    color: _isCorrect(q) ? SbdColors.success : SbdColors.muted,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reward != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Session complete')),
          body: LessonCelebration(
              reward: _reward!,
              onContinue: () => Navigator.pop(context)));
    }
    final lesson = widget.lesson;
    final completed = widget.store.isCompleted(lesson.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.practice ? 'Practice' : 'Your lesson',
            style: const TextStyle(fontSize: 16)),
      ),
      body: PageContent(
        maxWidth: 760,
        children: [
          Kicker(
            'Lesson ${widget.path.lessons.indexOf(lesson) + 1} of ${widget.path.lessons.length} · ${lesson.minutes} min',
          ),
          const SizedBox(height: 16),
          Text(lesson.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          Text(lesson.summary, style: Theme.of(context).textTheme.bodyLarge),
          if (lesson.hasVideo) ...[
            const SizedBox(height: 24),
            LessonVideo(youtubeId: lesson.youtubeId, title: lesson.title),
          ],
          if (!widget.practice && lesson.objectives.isNotEmpty) ...[
            const SizedBox(height: 24),
            Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Kicker('In this lesson you will'),
                  const SizedBox(height: 12),
                  for (final objective in lesson.objectives)
                    _Bullet(objective),
                ])),
          ],
          if (!widget.practice && lesson.labSteps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Panel(
                gradient: true,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Kicker('Follow along at your keyboard'),
                  const SizedBox(height: 10),
                  Text('Lab mode', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      '${lesson.labSteps.length} steps, one at a time, with copy buttons for the commands. '
                      'The screen stays on, and your checks and notes match the website’s course guide.',
                      style: const TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      key: const ValueKey('start-lab-mode'),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => LabModeScreen(
                                  store: widget.store,
                                  path: widget.path,
                                  lesson: lesson))),
                      icon: const Icon(Icons.science_outlined, size: 19),
                      label: const Text('Start lab mode')),
                ])),
          ],
          const SizedBox(height: 32),
          if (widget.practice)
            const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Recall it. Check it. Make it stick.',
                    style: TextStyle(color: SbdColors.cyan))),
          if (!widget.practice)
            for (final section in lesson.sections) ...[
              Text(
                section.heading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(section.body, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
            ],
          for (var q = 0; q < _questions.length; q++) ...[
            if (q > 0) const SizedBox(height: 16),
            _question(context, lesson, q),
          ],
          if (!widget.practice &&
              (lesson.recap.isNotEmpty || lesson.nextStep.isNotEmpty)) ...[
            const SizedBox(height: 22),
            Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (lesson.recap.isNotEmpty) ...[
                    const Kicker('Recap'),
                    const SizedBox(height: 12),
                    for (final point in lesson.recap) _Bullet(point),
                  ],
                  if (lesson.nextStep.isNotEmpty) ...[
                    if (lesson.recap.isNotEmpty) const SizedBox(height: 8),
                    const Kicker('Next step'),
                    const SizedBox(height: 10),
                    Text(lesson.nextStep,
                        style: const TextStyle(height: 1.6)),
                  ],
                ])),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _correct && !_saving ? _complete : null,
              icon: Icon(
                completed ? Icons.check_circle_outline : Icons.check_rounded,
              ),
              label: Text(
                _saving
                    ? 'Saving progress…'
                    : completed
                        ? 'Complete review'
                        : 'Complete lesson',
              ),
            ),
          ),
          if (!_correct)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _questions.length == 1
                    ? 'Choose the correct answer to complete this lesson.'
                    : 'Answer all ${_questions.length} questions correctly to complete this lesson.',
                style: const TextStyle(color: SbdColors.muted, fontSize: 13),
              ),
            ),
          if (widget.practice)
            ExpansionTile(
                title: const Text('Review the lesson notes'),
                children: [
                  for (final section in lesson.sections)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(section.heading,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(section.body,
                                  style: Theme.of(context).textTheme.bodyLarge)
                            ]))
                ]),
          const SizedBox(height: 26),
          const Divider(color: SbdColors.border),
          const SizedBox(height: 12),
          const Text(
            'Go deeper',
            style: TextStyle(color: SbdColors.ink, fontSize: 14),
          ),
          TextButton.icon(
            onPressed: () => openResource(context, lesson.sourceUrl),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(lesson.sourceLabel),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle_outline,
                  size: 18, color: SbdColors.cyan)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.6))),
        ]),
      );
}
