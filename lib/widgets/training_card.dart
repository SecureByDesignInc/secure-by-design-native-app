import 'package:flutter/material.dart';

import '../data/learning_store.dart';
import '../data/models.dart';
import '../data/training_categories.dart';
import '../screens/path_screen.dart';
import '../theme.dart';
import 'common.dart';

class TrainingCard extends StatefulWidget {
  const TrainingCard({super.key, required this.path, required this.store});
  final LearningPath path;
  final LearningStore store;

  @override
  State<TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<TrainingCard> {
  bool _expanded = false;

  void _toggle() {
    widget.store.haptics.selectionChanged();
    setState(() => _expanded = !_expanded);
  }

  Future<void> _openLesson(Lesson lesson) async {
    final store = widget.store;
    try {
      await store.openPath(widget.path.id);
    } catch (_) {
      if (mounted) showNotice(context, 'Your place could not be saved yet.');
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
            store: store,
            path: widget.path,
            lesson: lesson,
            practice: store.isCompleted(lesson.id))));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final path = widget.path;
        final done = widget.store.completedIn(path);
        return Panel(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Semantics(
                  button: true,
                  expanded: _expanded,
                  child: InkWell(
                      key: ValueKey('expand-${path.id}'),
                      onTap: _toggle,
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  TopicBadge(path.icon, size: 38),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(categoryFor(path).title, style: const TextStyle(
                                        color: SbdColors.cyan, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(path.title, style: Theme.of(context).textTheme.titleMedium),
                                  ])),
                                  const SizedBox(width: 8),
                                  Icon(_expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                      color: SbdColors.cyan),
                                ]),
                                const SizedBox(height: 12),
                                Text(path.subtitle, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 18),
                                ProgressLine(value: widget.store.progressIn(path)),
                                const SizedBox(height: 8),
                                Text('$done of ${path.lessons.length} lessons complete',
                                    style: TextStyle(color: done == path.lessons.length
                                        ? SbdColors.success : SbdColors.muted)),
                                const SizedBox(height: 14),
                                Text(_expanded ? 'Hide lessons' : 'Show lessons',
                                    style: const TextStyle(color: SbdColors.cyan,
                                        fontWeight: FontWeight.w600)),
                              ])))),
              AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero : const Duration(milliseconds: 180),
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Divider(height: 1),
                            const SizedBox(height: 20),
                            Text('What you’ll learn',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(path.description),
                            const SizedBox(height: 12),
                            Text(path.studyTime,
                                style: const TextStyle(color: SbdColors.cyan)),
                            const SizedBox(height: 16),
                            for (var index = 0; index < path.lessons.length; index++)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                      color: SbdColors.surfaceLow,
                                      borderRadius: BorderRadius.circular(16),
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          leading: Icon(widget.store.isCompleted(path.lessons[index].id)
                                              ? Icons.check_circle_rounded : Icons.play_circle_outline,
                                              color: widget.store.isCompleted(path.lessons[index].id)
                                                  ? SbdColors.success : SbdColors.cyan),
                                          title: Text(path.lessons[index].title),
                                          subtitle: Text('${path.lessons[index].minutes} min · '
                                              '${widget.store.isCompleted(path.lessons[index].id) ? 'Review lesson' : 'Read & practice'}'),
                                          onTap: () => _openLesson(path.lessons[index])))),
                            TextButton.icon(
                                onPressed: () => openLearningPath(context, widget.store, path),
                                icon: const Icon(Icons.auto_stories_outlined),
                                label: const Text('Open course overview')),
                          ]))
                      : const SizedBox.shrink()),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: OutlinedButton.icon(
                      onPressed: () => openLearningPath(context, widget.store,
                          path, showMaterials: true),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text('View materials (${path.materials.length})'))),
            ]));
      });
}
