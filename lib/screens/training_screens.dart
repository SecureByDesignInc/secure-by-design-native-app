import 'package:flutter/material.dart';
import '../data/catalog.dart';
import '../data/getting_started.dart';
import '../data/learning_store.dart';
import '../data/published_catalog.dart';
import '../data/training_categories.dart';
import '../widgets/training_card.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/getting_started.dart';
import '../widgets/learning_rewards.dart';
import 'main_screens.dart' show ResourcesScreen;
import 'network_screen.dart';
import 'threat_map_screen.dart';
import 'path_screen.dart';
import 'membership_screen.dart';

export '../widgets/training_card.dart' show TrainingCard;
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
          TextButton(onPressed: () => onTab(1), child: const Text('View all'))
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
      if (store.completed.isNotEmpty) const MembershipInvitation(),
    ]);
  }
}

class TrainingLibraryScreen extends StatefulWidget {
  const TrainingLibraryScreen({super.key, required this.store});
  final LearningStore store;
  @override
  State<TrainingLibraryScreen> createState() => _TrainingLibraryScreenState();
}

class _TrainingLibraryScreenState extends State<TrainingLibraryScreen> {
  String query = '';
  String category = '';
  @override
  Widget build(BuildContext context) {
    final matches = publishedPaths.where((path) {
      final group = categoryFor(path);
      return (category.isEmpty || group.id == category) &&
          '${path.title} ${path.subtitle} ${path.description} ${group.title}'
              .toLowerCase().contains(query.trim().toLowerCase());
    }).toList();
    return PageContent(children: [
      Text('Training Library', style: Theme.of(context).textTheme.headlineMedium),
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
      if (matches.isEmpty)
        const Text('No matching training. Try another topic.'),
      for (final group in trainingCategories)
        if (matches.any(group.contains)) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TopicBadge(group.icon, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(group.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${matches.where(group.contains).length} '
                  '${matches.where(group.contains).length == 1 ? 'course' : 'courses'}'),
            ])),
          ]),
          const SizedBox(height: 16),
          ResponsiveCards(children: matches.where(group.contains)
              .map((path) => TrainingCard(key: ValueKey(path.id),
                  path: path, store: widget.store)).toList()),
          const SizedBox(height: 32),
        ],
      const SizedBox(height: 30),
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Foundation lessons'),
          subtitle: const Text('Keep building on your earlier learning.'),
          children: foundationPaths
              .map((p) => ListTile(
                  title: Text(p.title),
                  subtitle: Text(
                      '${widget.store.completedIn(p)} of ${p.lessons.length} complete'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openLearningPath(context, widget.store, p)))
              .toList()),
    ]);
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key, required this.store});
  final LearningStore store;
  Widget link(BuildContext context, String title, String subtitle,
          IconData icon, VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Panel(
              padding: const EdgeInsets.all(18),
              onTap: onTap,
              child: Row(children: [
                Icon(icon, color: SbdColors.cyan),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: const TextStyle(
                              color: SbdColors.muted, height: 1.5))
                    ])),
                const Icon(Icons.chevron_right)
              ])));
  @override
  Widget build(BuildContext context) => PageContent(children: [
        const PageTitle('Explore',
            'Follow a connection. Find a useful resource. Bring your experience.',
            kicker: 'Keep your curiosity moving'),
        // The map is the most distinctive feature here, so it leads.
        Panel(
            gradient: true,
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const NetworkScreen())),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Kicker('Interactive map')),
                    Icon(Icons.hub_outlined,
                        color: SbdColors.cyan.withValues(alpha: 0.7),
                        size: 34),
                  ]),
                  const SizedBox(height: 10),
                  Text('Inside the Network',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Walk the systems, traffic processes, what-ifs, and policy rules behind every lesson.',
                      style: TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => const NetworkScreen())),
                      icon: const Icon(Icons.explore_outlined, size: 19),
                      label: const Text('Open the map')),
                ])),
        const SizedBox(height: 14),
        Panel(
            gradient: true,
            onTap: () => openThreatMap(context),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Kicker('Live from Radware')),
                    Icon(Icons.public,
                        color: SbdColors.cyan.withValues(alpha: 0.7),
                        size: 34),
                  ]),
                  const SizedBox(height: 10),
                  Text('Live Threat Map',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Watch attacks detected around the world as they happen, then learn the defenses in your training.',
                      style: TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                      onPressed: () => openThreatMap(context),
                      icon: const Icon(Icons.public, size: 19),
                      label: const Text('Watch live attacks')),
                ])),
        const SizedBox(height: 28),
        Text('Your library', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        link(
            context,
            'Saved resources & materials',
            'Your bookmarks, workbooks, and reference links.',
            Icons.bookmarks_outlined,
            () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Resources')),
                        body: AnimatedBuilder(
                            animation: store,
                            builder: (context, child) =>
                                ResourcesScreen(store: store)))))),
        link(
            context,
            'Cybersecurity Resources',
            'Find practical tools and learning material.',
            Icons.menu_book_outlined,
            () => openResource(
                context, 'https://securebydesigninc.com/careers#resources')),
        const SizedBox(height: 14),
        Text('Community', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        link(
            context,
            'Career Goals & Support',
            'Explore your goals and start a conversation.',
            Icons.explore_outlined,
            () => openResource(
                context, 'https://securebydesigninc.com/careers#goals')),
        link(
            context,
            'Share What You Know',
            'Contribute a resource, idea, or lesson from your work.',
            Icons.people_outline,
            () => openResource(
                context, 'https://securebydesigninc.com/careers#contribute')),
        link(
            context,
            'Cyber Range · Request access',
            'Explore the learning-path setup and request access.',
            Icons.terminal_outlined,
            () => openResource(
                context, 'https://securebydesigninc.com/cyber-range')),
      ]);
}

