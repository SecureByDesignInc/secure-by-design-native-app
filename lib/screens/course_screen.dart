import 'package:flutter/material.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/lesson_video.dart';
import 'path_screen.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen(
      {super.key,
      required this.store,
      required this.path,
      this.initialTab = 0});
  final LearningStore store;
  final LearningPath path;
  final int initialTab;
  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

/// The DC01/DC02 guide has chapters, the authorization course has modules,
/// and the configuration courses have lessons.
String _unit(LearningPath path) => path.id == 'dc01-dc02'
    ? 'chapters'
    : path.lessons.every((l) => l.id.startsWith('training:rmf-boe-ato:'))
        ? 'modules'
        : 'lessons';

class _CourseScreenState extends State<CourseScreen> {
  late int _tab;
  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  void _open(Lesson lesson) => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => LessonScreen(
              store: widget.store, lesson: lesson, path: widget.path)));

  void _selectTab(int tab) {
    if (_tab == tab) return;
    widget.store.haptics.selectionChanged();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final path = widget.path, store = widget.store;
        final next = store.nextLesson(path);
        return Scaffold(
            appBar: AppBar(title: const Text('Training Hub')),
            body: SafeArea(
                child: PageContent(maxWidth: 820, children: [
              Kicker(path.number.isEmpty
                  ? path.category
                  : 'Course ${path.number} · ${path.category}'),
              const SizedBox(height: 12),
              Text(path.title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(path.subtitle,
                  style: const TextStyle(color: SbdColors.muted, height: 1.6)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 8, children: [
                Chip(label: Text(path.studyTime)),
                Chip(
                    avatar: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text(
                        '${path.materials.length} training materials')),
              ]),
              const SizedBox(height: 16),
              ProgressLine(value: store.progressIn(path)),
              const SizedBox(height: 8),
              Text(
                  '${store.completedIn(path)} of ${path.lessons.length} ${_unit(path)} complete'),
              const SizedBox(height: 22),
              SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Overview')),
                    ButtonSegment(value: 1, label: Text('Lessons')),
                    ButtonSegment(value: 2, label: Text('Materials'))
                  ],
                  selected: {
                    _tab
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => _selectTab(v.first)),
              const SizedBox(height: 24),
              if (_tab == 0) ...[
                if (path.hasTrailer) ...[
                  LessonVideo(
                      youtubeId: path.trailerYoutubeId,
                      title: '${path.title} trailer',
                      kicker: 'Course trailer'),
                  const SizedBox(height: 24),
                ],
                Text(path.description,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                FilledButton.icon(
                    onPressed: () => _open(next ?? path.lessons.first),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(next == null
                        ? 'Revisit this course'
                        : store.completedIn(path) == 0
                            ? 'Start the first lesson'
                            : 'Continue learning')),
                const SizedBox(height: 24),
                Panel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Kicker('Your learning path'),
                      const SizedBox(height: 12),
                      for (final lesson in path.lessons)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(lesson.title)),
                    ])),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                    onPressed: () => _selectTab(2),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('View training materials')),
              ],
              if (_tab == 1)
                // One path, shown in order: done, up next, still ahead.
                for (var i = 0; i < path.lessons.length; i++)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Builder(builder: (context) {
                        final lesson = path.lessons[i];
                        final done = store.isCompleted(lesson.id);
                        final current = next != null && lesson.id == next.id;
                        return Panel(
                            padding: const EdgeInsets.all(16),
                            onTap: () => _open(lesson),
                            child: Row(children: [
                              Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: current
                                          ? SbdColors.cyan
                                              .withValues(alpha: 0.14)
                                          : SbdColors.surface,
                                      border: Border.all(
                                          color: done
                                              ? SbdColors.success
                                                  .withValues(alpha: 0.5)
                                              : current
                                                  ? SbdColors.cyan
                                                  : SbdColors.border)),
                                  child: Center(
                                      child: done
                                          ? const Icon(Icons.check_rounded,
                                              color: SbdColors.success,
                                              size: 20)
                                          : current
                                              ? const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: SbdColors.cyan,
                                                  size: 22)
                                              : Text('${i + 1}'.padLeft(2, '0'),
                                                  style: const TextStyle(
                                                      color: SbdColors.muted,
                                                      fontSize: 13)))),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(lesson.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                color: done || current
                                                    ? SbdColors.ink
                                                    : SbdColors.muted)),
                                    const SizedBox(height: 6),
                                    Text(
                                        done
                                            ? 'Completed · ${lesson.minutes} min'
                                            : current
                                                ? 'Up next · ${lesson.minutes} min${lesson.hasVideo ? ' · Video' : ''}'
                                                : '${lesson.minutes} min${lesson.hasVideo ? ' · Video' : ''}',
                                        style: const TextStyle(
                                            color: SbdColors.muted,
                                            height: 1.5,
                                            fontSize: 13))
                                  ])),
                              const Icon(Icons.chevron_right),
                            ]));
                      })),
              if (_tab == 2) ...[
                const Text(
                    'Open the interactive guide, or download every training material in one file.',
                    style: TextStyle(color: SbdColors.muted, height: 1.6)),
                const SizedBox(height: 20),
                for (final resource in path.materials)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Panel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(resource.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Text(resource.description),
                                const SizedBox(height: 12),
                                Wrap(spacing: 12, children: [
                                  TextButton.icon(
                                      onPressed: () =>
                                          openResource(context, resource.url),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open material')),
                                  IconButton(
                                      tooltip: store.isSaved(resource.id)
                                          ? 'Remove saved material'
                                          : 'Save material',
                                      onPressed: () async {
                                        final wasSaved =
                                            store.isSaved(resource.id);
                                        final scope = store.accountScope;
                                        try {
                                          await store.toggleSaved(resource.id);
                                          if (context.mounted &&
                                              scope == store.accountScope &&
                                              wasSaved !=
                                                  store.isSaved(resource.id)) {
                                            store.haptics.bookmarkChanged();
                                          }
                                        } catch (_) {
                                          if (context.mounted) {
                                            showNotice(context,
                                                'Could not save this material. Try again.');
                                          }
                                        }
                                      },
                                      icon: Icon(store.isSaved(resource.id)
                                          ? Icons.bookmark
                                          : Icons.bookmark_outline))
                                ]),
                              ]))),
              ],
            ])));
      });
}
