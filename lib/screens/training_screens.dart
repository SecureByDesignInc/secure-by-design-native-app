import 'package:flutter/material.dart';
import '../app_tabs.dart';
import '../data/catalog.dart';
import '../data/getting_started.dart';
import '../data/learning_store.dart';
import '../data/training_categories.dart';
import '../widgets/training_card.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/getting_started.dart';
import '../widgets/learning_rewards.dart';
import 'path_screen.dart';
import 'hub_screens.dart';

export '../widgets/training_card.dart' show TrainingCard, ComingSoonCard;
export 'my_account_screen.dart' show MyLearningScreen;

class TrainingHome extends StatelessWidget {
  const TrainingHome({super.key, required this.store, required this.onTab});
  final LearningStore store;
  final ValueChanged<int> onTab;

  void _openQuests(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Quests & rewards')),
              body: SafeArea(child: AnimatedBuilder(animation: store,
                  builder: (context, _) => PageContent(children: [
                        LearningDashboard(store: store,
                            onPractice: () => openPractice(context, store)),
                      ]))))));

  @override
  Widget build(BuildContext context) {
    final path = store.currentPath;
    final next = store.nextLesson(path);
    final done = store.completedIn(path);
    final started = done > 0 && next != null;
    final upNext = [
      for (final p in publishedPaths)
        if (p.id != path.id && store.nextLesson(p) != null) p
    ].take(2).toList();
    return PageContent(children: [
      const Kicker('Cybersecurity starts with curiosity.'),
      const SizedBox(height: 12),
      Text(started ? 'Pick up where you left off.' : 'Your next chapter.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 22),
      // The hero leads with content: one card, one primary action.
      Panel(
          gradient: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(next == null
                ? 'Path completed'
                : '${categoryFor(path).title} · Lesson '
                    '${path.lessons.indexOf(next) + 1} of ${path.lessons.length}'),
            const SizedBox(height: 14),
            Text(path.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
                next?.title ??
                    'You completed this path. Revisit what you learned.',
                style: const TextStyle(color: SbdColors.muted, height: 1.6)),
            if (next != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.schedule_outlined,
                    size: 15, color: SbdColors.cyan),
                const SizedBox(width: 6),
                Text('${next.minutes} min',
                    style:
                        const TextStyle(color: SbdColors.ink, fontSize: 13)),
              ]),
            ],
            const SizedBox(height: 18),
            ProgressLine(value: store.progressIn(path)),
            const SizedBox(height: 8),
            Text('$done of ${path.lessons.length} lessons complete',
                style: const TextStyle(color: SbdColors.muted, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: () {
                      if (started) {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => LessonScreen(
                                store: store, lesson: next, path: path)));
                      } else {
                        openLearningPath(context, store, path);
                      }
                    },
                    icon: Icon(next == null
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(next == null
                        ? 'Revisit this path'
                        : started
                            ? 'Continue lesson'
                            : 'Start learning'))),
          ])),
      const SizedBox(height: 14),
      DailyStrip(store: store, onDetails: () => _openQuests(context)),
      const SizedBox(height: 24),
      if (upNext.isNotEmpty) ...[
        Row(children: [
          Expanded(
              child: Text('Up next',
                  style: Theme.of(context).textTheme.titleLarge)),
          TextButton(
              onPressed: () => onTab(AppTab.training.index),
              child: const Text('View all'))
        ]),
        const SizedBox(height: 10),
        for (final p in upNext)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                  padding: const EdgeInsets.all(16),
                  onTap: () => openLearningPath(context, store, p),
                  child: Row(children: [
                    TopicBadge(p.icon, size: 42),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(store.nextLesson(p)!.title,
                              style: const TextStyle(
                                  color: SbdColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                              '${store.nextLesson(p)!.minutes} min · '
                              '${categoryFor(p).title}',
                              style: const TextStyle(
                                  color: SbdColors.muted, fontSize: 13)),
                        ])),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: SbdColors.muted, size: 20),
                  ]))),
        const SizedBox(height: 12),
      ],
      if (store.gettingStarted.next == GettingStartedMessage.welcome)
        GettingStartedCard(store: store, onTab: onTab),
      LearningPlanChecklist(store: store, onTab: onTab),
      Text('Build. Then authorize.',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      ResponsiveCards(
          children: publishedPaths
              .map((p) => TrainingCard(path: p, store: store))
              .toList()),
      const SizedBox(height: 28),
      if (resources.any((r) => store.isSaved(r.id))) ...[
        Text('Saved for your next session',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final r in resources.where((r) => store.isSaved(r.id)).take(3))
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark, color: SbdColors.cyan),
              title: Text(r.title),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openResource(context, r.url)),
        const SizedBox(height: 22),
      ],
      if (store.gettingStarted.next != GettingStartedMessage.welcome)
        GettingStartedCard(store: store, onTab: onTab),
    ]);
  }
}

class TrainingLibraryScreen extends StatefulWidget {
  const TrainingLibraryScreen({super.key, required this.store, this.onSystemHub});
  final LearningStore store;

  /// Opens the System Hub tab from the Tools (website, 27 October 2026).
  final VoidCallback? onSystemHub;
  @override
  State<TrainingLibraryScreen> createState() => _TrainingLibraryScreenState();
}

class _TrainingLibraryScreenState extends State<TrainingLibraryScreen> {
  String query = '';
  String category = '';

  bool _matches(String text) =>
      text.toLowerCase().contains(query.trim().toLowerCase());

  /// Course numbers in the website's order: 1.9 and 1.10 sit between 1.8 and 1.11.
  static List<int> _order(String number) =>
      number.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  static int _compare(String a, String b) {
    final x = _order(a), y = _order(b);
    for (var i = 0; i < x.length && i < y.length; i++) {
      if (x[i] != y[i]) return x[i].compareTo(y[i]);
    }
    return x.length.compareTo(y.length);
  }

  @override
  Widget build(BuildContext context) {
    final matches = publishedPaths.where((path) {
      final group = categoryFor(path);
      return (category.isEmpty || group.id == category) &&
          _matches('${path.title} ${path.subtitle} ${path.description} ${group.title}');
    }).toList();
    final soon = currentCatalog.comingSoon.where((course) =>
        (category.isEmpty || course.categoryId == category) &&
        _matches('${course.number} ${course.title} ${course.subtitle} ${course.description} coming soon'));
    return PageContent(children: [
      Text('Training Hub', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Build the network. Prepare it for authorization.'),
      const SizedBox(height: 18),
      TextField(
          decoration: const InputDecoration(
              labelText: 'Search training', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 18),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        ChoiceChip(label: const Text('All training'), selected: category.isEmpty,
            onSelected: (_) => setState(() => category = '')),
        for (final group in trainingCategories) ...[
          const SizedBox(width: 8),
          ChoiceChip(label: Text(group.title), selected: category == group.id,
              onSelected: (_) {
                widget.store.haptics.selectionChanged();
                setState(() => category = group.id);
              }),
        ],
      ])),
      const SizedBox(height: 28),
      if (matches.isEmpty && soon.isEmpty)
        const Text('No matching training. Try another topic.'),
      for (final group in trainingCategories)
        if (matches.any(group.contains) || soon.any((c) => c.categoryId == group.id)) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TopicBadge(group.icon, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(group.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_countLabel(matches.where(group.contains).length,
                  soon.where((c) => c.categoryId == group.id).length)),
            ])),
          ]),
          const SizedBox(height: 16),
          ResponsiveCards(children: [
            for (final (_, card) in <(String, Widget)>[
              for (final path in matches.where(group.contains))
                (path.number, TrainingCard(key: ValueKey(path.id),
                    path: path, store: widget.store)),
              for (final course in soon.where((c) => c.categoryId == group.id))
                (course.number, ComingSoonCard(key: ValueKey(course.id), course: course)),
            ]..sort((a, b) => _compare(a.$1, b.$1)))
              card,
          ]),
          const SizedBox(height: 32),
          // The ATO Package Builder lives here, as on the website (27 October 2026):
          // the Tools and the seven RMF steps, until a search or a filter is set.
          // Owner direction, 1 November 2026: the Training Hub opens on Build the
          // Network, so the Tools and the steps follow that group, as on the website.
          if (group.id == 'network-build' && query.trim().isEmpty && category.isEmpty) ...[
            AtoBuilderSection(store: widget.store, onSystemHub: widget.onSystemHub),
            const SizedBox(height: 4),
          ],
        ],
    ]);
  }

  static String _countLabel(int courses, int soon) {
    final open = '$courses ${courses == 1 ? 'course' : 'courses'}';
    return soon == 0 ? open : '$open · $soon coming soon';
  }
}
