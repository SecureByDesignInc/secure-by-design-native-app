import 'package:flutter/material.dart';

import '../data/learning_store.dart';
import '../data/models.dart';
import '../data/training_categories.dart';
import '../screens/path_screen.dart';
import '../theme.dart';
import 'common.dart';
import 'tile_art.dart';

/// The width of a tile in a row that scrolls sideways (training-hub.css,
/// phones: grid-auto-columns 240px).
const tileWidth = 240.0;

/// A course tile the way the Training Hub draws one (.th-tile): the art on
/// its ground, the course number ghosted top right, a mono chip, the title
/// over a fade at the foot, and a meta line beneath. Tapping it opens the
/// course beneath its row, as on the website; with no [onOpen] the tile opens
/// its course directly beneath itself.
class TrainingCard extends StatefulWidget {
  const TrainingCard({
    super.key,
    required this.path,
    required this.store,
    this.open,
    this.onOpen,
    this.width,
  });
  final LearningPath path;
  final LearningStore store;

  /// Whether the course is open (highlights the tile). Read only with [onOpen].
  final bool? open;
  final VoidCallback? onOpen;
  final double? width;

  @override
  State<TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<TrainingCard> {
  bool _open = false;
  bool get _isOpen => widget.onOpen == null ? _open : (widget.open ?? false);

  void _toggle() {
    widget.store.haptics.selectionChanged();
    if (widget.onOpen != null) {
      widget.onOpen!();
    } else {
      setState(() => _open = !_open);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final path = widget.path;
        final tile = HubTile(
          key: ValueKey('expand-${path.id}'),
          family: artFamilyFor(path.id, path.categoryId),
          number: path.number,
          chip: 'Course ${path.number} · ${topicFor(path.id, categoryFor(path).title)}',
          title: path.title,
          meta: courseMeta(path, widget.store),
          active: _isOpen,
          semanticsLabel: '${_isOpen ? 'Close' : 'Open'} course ${path.number}: ${path.title}',
          onTap: _toggle,
        );
        if (widget.onOpen != null) {
          return widget.width == null ? tile : SizedBox(width: widget.width, child: tile);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: widget.width ?? tileWidth, child: tile),
          AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SizedBox(
                          width: double.infinity,
                          child: CourseExpansion(path: path, store: widget.store, onClose: _toggle)))
                  : const SizedBox.shrink()),
        ]);
      });
}

/// The meta line beneath a tile: lessons, time and whether a video exists,
/// with the learner's progress once there is some.
String courseMeta(LearningPath path, LearningStore store) {
  final done = store.completedIn(path);
  final size = '${path.lessons.length} lessons';
  final time = path.studyTime.isNotEmpty ? path.studyTime.split(' · ').last : 'Self-paced';
  final video = path.lessons.any((l) => l.hasVideo) || path.hasTrailer ? 'Video' : 'Written guide';
  return done > 0 ? '$done of ${path.lessons.length} complete · $time · $video' : '$size · $time · $video';
}

/// The tile itself; [TrainingCard] and [ComingSoonCard] both draw one.
class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.family,
    required this.number,
    required this.chip,
    required this.title,
    required this.meta,
    this.active = false,
    this.comingSoon = false,
    this.onTap,
    this.semanticsLabel,
  });
  final String family, number, chip, title, meta;
  final bool active, comingSoon;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(fit: StackFit.expand, children: [
          TileArt(family: family),
          if (comingSoon)
            const DecoratedBox(decoration: BoxDecoration(color: Color(0x6B071521))),
          if (number.isNotEmpty)
            Positioned(
                right: 12,
                top: 2,
                child: ExcludeSemantics(
                    child: Text(number,
                        style: const TextStyle(
                            fontFamily: sbdMono,
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.6,
                            height: 1.1,
                            color: Color(0x1AEEF7FC))))),
          Positioned(
              left: 10,
              top: 10,
              right: 10,
              child: Row(children: [
                Flexible(child: ChipLabel(chip)),
              ])),
          if (comingSoon)
            const Positioned(
                left: 10,
                top: 38,
                child: ChipLabel('Coming soon', icon: Icons.schedule, amber: true)),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 30, 12, 11),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.58, 1],
                          colors: [Color(0x00050F19), Color(0xF0050F19), Color(0xF0050F19)])),
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          letterSpacing: -0.15)))),
        ]),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? title,
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? SbdColors.cyan : SbdColors.borderTile),
                boxShadow: active
                    ? [BoxShadow(color: SbdColors.cyan.withValues(alpha: 0.22), spreadRadius: 3)]
                    : const [],
              ),
              child: thumb,
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 9, 2, 0),
            child: Text(meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: SbdColors.muted, fontSize: 12.5, height: 1.4))),
      ]),
    );
  }
}

/// A mono chip on the art (.th-chip; .th-soon in amber).
class ChipLabel extends StatelessWidget {
  const ChipLabel(this.text, {super.key, this.icon, this.amber = false});
  final String text;
  final IconData? icon;
  final bool amber;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: amber ? SbdColors.amber : const Color(0xCC071521),
            borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: amber ? SbdColors.amberInk : SbdColors.ink),
            const SizedBox(width: 5),
          ],
          Flexible(
              child: Text(text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: sbdMono,
                      fontSize: 10.5,
                      fontWeight: amber ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.8,
                      height: 1.4,
                      color: amber ? SbdColors.amberInk : SbdColors.ink))),
        ]),
      );
}

/// A course opened beneath its row (the website's expanded tile): what the
/// course covers, its lessons, and the course overview and materials.
class CourseExpansion extends StatelessWidget {
  const CourseExpansion({super.key, required this.path, required this.store, required this.onClose});
  final LearningPath path;
  final LearningStore store;
  final VoidCallback onClose;

  Future<void> _openLesson(BuildContext context, Lesson lesson) async {
    try {
      await store.openPath(path.id);
    } catch (_) {
      if (context.mounted) showNotice(context, 'Your place could not be saved yet.');
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
            store: store, path: path, lesson: lesson, practice: store.isCompleted(lesson.id))));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final done = store.completedIn(path);
        final family = artFamilyFor(path.id, path.categoryId);
        return Panel(
            key: ValueKey('course-${path.id}'),
            radius: 20,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Kicker('Course ${path.number} · ${topicFor(path.id, categoryFor(path).title)}',
                      color: SbdColors.family(family)),
                  const SizedBox(height: 8),
                  Text(path.title, style: Theme.of(context).textTheme.headlineSmall),
                ])),
                const SizedBox(width: 8),
                IconButton(
                    tooltip: 'Close the course',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20)),
              ]),
              if (path.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(path.subtitle, style: const TextStyle(color: SbdColors.ink, fontSize: 14, height: 1.5)),
              ],
              const SizedBox(height: 14),
              Text(path.description, style: Theme.of(context).textTheme.bodyMedium),
              if (path.studyTime.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(path.studyTime,
                    style: const TextStyle(
                        fontFamily: sbdMono, fontSize: 12, color: SbdColors.muted, letterSpacing: 0.2)),
              ],
              const SizedBox(height: 16),
              ProgressLine(value: store.progressIn(path)),
              const SizedBox(height: 8),
              Text('$done of ${path.lessons.length} lessons complete',
                  style: TextStyle(
                      fontSize: 13,
                      color: done == path.lessons.length ? SbdColors.success : SbdColors.muted)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton(
                    onPressed: () => openLearningPath(context, store, path),
                    child: Text(done == 0
                        ? 'Open the course'
                        : done == path.lessons.length
                            ? 'Revisit the course'
                            : 'Continue the course')),
                OutlinedButton(
                    onPressed: () => openLearningPath(context, store, path, showMaterials: true),
                    child: Text('View materials (${path.materials.length})')),
              ]),
              const SizedBox(height: 22),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text('Lessons', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final lesson in path.lessons)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: 44,
                    leading: Icon(
                        store.isCompleted(lesson.id)
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_outline,
                        color: store.isCompleted(lesson.id) ? SbdColors.success : SbdColors.cyan),
                    title: Text(lesson.title),
                    subtitle: Text(
                        '${lesson.minutes} min · ${store.isCompleted(lesson.id) ? 'Review lesson' : 'Read & practice'}'),
                    onTap: () => _openLesson(context, lesson)),
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                  label: const Text('Close the course')),
            ]));
      });
}

/// A catalog tile the website labels "Coming soon": shown in its place in the
/// course order so learners see what's next, with nothing to open yet.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key, required this.course, this.width});
  final ComingSoonCourse course;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tile = HubTile(
      family: artFamilyFor(course.id, course.categoryId),
      number: course.number,
      chip: 'Course ${course.number} · ${topicFor(course.id, course.subtitle.isEmpty ? 'Coming soon' : course.subtitle)}',
      title: course.title,
      meta: 'Training materials in preparation',
      comingSoon: true,
      semanticsLabel: '${course.number} ${course.title}. Coming soon.',
    );
    return width == null ? tile : SizedBox(width: width, child: tile);
  }
}

/// A row of tiles (.th-shelf): sideways on phones, a grid on wider screens;
/// the open course spans the width beneath the row, as on the website.
class CourseShelf extends StatefulWidget {
  const CourseShelf({
    super.key,
    required this.store,
    required this.courses,
    this.comingSoon = const [],
    this.title,
    this.note,
    this.sort,
    this.grid = false,
  });
  final LearningStore store;
  final List<LearningPath> courses;
  final List<ComingSoonCourse> comingSoon;
  final String? title;
  final String? note;

  /// Always a wrapping grid (a library group or search results), never a row
  /// that scrolls sideways.
  final bool grid;

  /// Orders the tiles by course number when the row mixes courses and
  /// coming-soon tiles; by default courses come first in their own order.
  final int Function(String a, String b)? sort;

  @override
  State<CourseShelf> createState() => _CourseShelfState();
}

class _CourseShelfState extends State<CourseShelf> {
  String? _openId;

  @override
  void didUpdateWidget(CourseShelf old) {
    super.didUpdateWidget(old);
    if (_openId != null && !widget.courses.any((c) => c.id == _openId)) _openId = null;
  }

  void _toggle(String id) => setState(() => _openId = _openId == id ? null : id);

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Widget Function(double? width))>[
      for (final course in widget.courses)
        (
          course.number,
          (width) => TrainingCard(
              key: ValueKey(course.id),
              path: course,
              store: widget.store,
              open: _openId == course.id,
              onOpen: () => _toggle(course.id),
              width: width),
        ),
      for (final course in widget.comingSoon)
        (course.number, (width) => ComingSoonCard(key: ValueKey(course.id), course: course, width: width)),
    ];
    if (widget.sort != null) entries.sort((a, b) => widget.sort!(a.$1, b.$1));
    final open = widget.courses.where((c) => c.id == _openId).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.title != null) ...[
        ShelfHeading(widget.title!, note: widget.note),
        const SizedBox(height: 12),
      ],
      LayoutBuilder(builder: (context, constraints) {
        if (!widget.grid && constraints.maxWidth < 620) {
          // Phones: the row scrolls sideways and its tiles run past the
          // gutter, the way the website's rows do.
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  entries[i].$2(tileWidth),
                ],
              ]));
        }
        final columns = (constraints.maxWidth / 240).floor().clamp(widget.grid ? 1 : 2, 5);
        final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
        return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [for (final entry in entries) entry.$2(width)]);
      }),
      if (open != null)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CourseExpansion(path: open, store: widget.store, onClose: () => _toggle(open.id))),
    ]);
  }
}
