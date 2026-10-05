import 'package:flutter/material.dart';
import '../data/catalog.dart';
import '../data/getting_started.dart';
import '../data/learning_store.dart';
import '../data/published_catalog.dart';
import '../data/training_categories.dart';
import '../widgets/training_card.dart';
export '../widgets/training_card.dart' show TrainingCard;
export 'my_account_screen.dart' show MyLearningScreen;
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/getting_started.dart';
import '../widgets/training_share.dart';
import '../widgets/learning_rewards.dart';
import 'main_screens.dart' show ResourcesScreen;
import 'network_screen.dart';
import 'path_screen.dart';
import 'membership_screen.dart';

class TrainingHome extends StatelessWidget {
  const TrainingHome({super.key, required this.store, required this.onTab});
  final LearningStore store;
  final ValueChanged<int> onTab;
  @override
  Widget build(BuildContext context) {
    final path = store.currentPath;
    final next = store.nextLesson(path);
    return PageContent(children: [
      const Kicker('Cybersecurity starts with curiosity.'),
      const SizedBox(height: 12),
      Text('Your next chapter.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 22),
      DailyLearningCard(
          store: store,
          onDetails: () => onTab(3),
          onLearn: () {
            if (next == null) {
              openPractice(context, store);
              return;
            }
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) =>
                    LessonScreen(store: store, lesson: next, path: path)));
          }),
      const SizedBox(height: 18),
      if (store.gettingStarted.next == GettingStartedMessage.welcome)
        GettingStartedCard(store: store, onTab: onTab),
      LearningPlanChecklist(store: store, onTab: onTab),
      Panel(
          gradient: true,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(store.completedIn(path) > 0
                ? 'Continue learning'
                : 'A good place to start'),
            const SizedBox(height: 14),
            Text(path.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
                next?.title ??
                    'You completed this path. Revisit what you learned.',
                style: const TextStyle(color: SbdColors.muted, height: 1.6)),
            const SizedBox(height: 20),
            ProgressLine(value: store.progressIn(path)),
            const SizedBox(height: 10),
            Text(
                '${store.completedIn(path)} of ${path.lessons.length} learning units complete'),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: () => openLearningPath(context, store, path),
                icon: const Icon(Icons.play_arrow),
                label: Text(store.completedIn(path) == 0
                    ? 'Start learning'
                    : 'Continue learning')),
          ])),
      if (store.practiceLesson != null) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () => openPractice(context, store),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Practice what you know')),
      ],
      const SizedBox(height: 28),
      Row(children: [
        Expanded(
            child: Text('Build. Then authorize.',
                style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: () => onTab(1), child: const Text('View all'))
      ]),
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
      const TrainingShare(),
      if (store.completed.isNotEmpty) ...[
        const SizedBox(height: 22),
        const MembershipInvitation(),
      ],
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
      const PageTitle('Training Library',
          'Build the network. Understand the why. Prepare it for authorization.',
          kicker: 'Learn it. Share it. Pay it forward.'),
      TextField(
          decoration: const InputDecoration(
              labelText: 'Search training', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(label: const Text('All training'), selected: category.isEmpty,
            onSelected: (_) => setState(() => category = '')),
        for (final group in trainingCategories)
          ChoiceChip(label: Text(group.title), selected: category == group.id,
              onSelected: (_) {
                widget.store.haptics.selectionChanged();
                setState(() => category = group.id);
              }),
      ]),
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
          const SizedBox(height: 12),
          Text(group.description,
              style: const TextStyle(color: SbdColors.muted, height: 1.5)),
          const SizedBox(height: 18),
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
        link(
            context,
            'Inside the Network',
            'Explore systems, services, and six traffic flows.',
            Icons.hub_outlined,
            () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const NetworkScreen()))),
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
            'Career Goals & Support',
            'Explore your goals and start a conversation.',
            Icons.explore_outlined,
            () => openResource(
                context, 'https://securebydesigninc.com/careers#goals')),
        link(
            context,
            'Cybersecurity Resources',
            'Find practical tools and learning material.',
            Icons.menu_book_outlined,
            () => openResource(
                context, 'https://securebydesigninc.com/careers#resources')),
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
        const SizedBox(height: 12),
        const TrainingShare(),
      ]);
}

