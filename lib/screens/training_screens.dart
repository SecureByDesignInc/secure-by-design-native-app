import 'package:flutter/material.dart';
import '../data/account.dart';
import '../data/catalog.dart';
import '../data/getting_started.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../data/published_catalog.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/getting_started.dart';
import '../widgets/training_share.dart';
import '../widgets/learning_rewards.dart';
import 'account_screen.dart';
import 'main_screens.dart' show ResourcesScreen;
import 'network_screen.dart';
import 'path_screen.dart';

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
    ]);
  }
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({super.key, required this.path, required this.store});
  final LearningPath path;
  final LearningStore store;
  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Semantics(
        label: '${path.title}. ${path.subtitle}',
        child: Panel(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
                height: scaled > 1.2 ? 310 * scaled : 310,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 78,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              gradient: SbdColors.gradient,
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            const SizedBox(width: 16),
                            TopicBadge(path.icon),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Text(
                                    path.id == 'dc01-dc02'
                                        ? '01 / BUILD'
                                        : '02 / AUTHORIZE',
                                    style: const TextStyle(
                                        color: SbdColors.cyan,
                                        fontWeight: FontWeight.w600)))
                          ])),
                      const SizedBox(height: 16),
                      Tooltip(
                          message: path.title,
                          child: Text(path.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium)),
                      const SizedBox(height: 8),
                      Text(path.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SbdColors.muted, fontSize: 14)),
                      const Spacer(),
                      const Wrap(spacing: 10, runSpacing: 6, children: [
                        Text('Training ready',
                            style:
                                TextStyle(color: SbdColors.cyan, fontSize: 13)),
                        Text('Video coming soon',
                            style:
                                TextStyle(color: SbdColors.muted, fontSize: 13))
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () => openLearningPath(
                                  context, store, path,
                                  showMaterials: true),
                              child: const Text('View materials'))),
                    ]))));
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
  @override
  Widget build(BuildContext context) {
    final matches = publishedPaths
        .where((p) => '${p.title} ${p.subtitle} ${p.category}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    return PageContent(children: [
      const PageTitle('Training Library',
          'Build the network. Understand the why. Prepare it for authorization.',
          kicker: 'Learn it. Share it. Pay it forward.'),
      TextField(
          decoration: const InputDecoration(
              labelText: 'Search training', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 24),
      if (matches.isEmpty)
        const Text('No matching training. Try another topic.'),
      ResponsiveCards(
          children: matches
              .map((p) => TrainingCard(path: p, store: widget.store))
              .toList()),
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

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen(
      {super.key, required this.store, required this.account});
  final LearningStore store;
  final AccountStore account;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([store, account]),
      builder: (context, _) => PageContent(children: [
            PageTitle('My Progress', store.storageLabel,
                kicker: 'Keep learning'),
            LearningDashboard(
                store: store, onPractice: () => openPractice(context, store)),
            const SizedBox(height: 26),
            Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      account.signedIn
                          ? 'Your learning, across devices.'
                          : 'Continue with your website account.',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                      account.signedIn
                          ? (store.cloudConnected
                              ? 'Sync lessons, streaks, XP, and saved materials with your account.'
                              : 'Connect account progress when you are ready. Your device-only records stay separate.')
                          : 'Sign in to sync. You can also keep learning and saving materials on this device.',
                      style:
                          const TextStyle(color: SbdColors.muted, height: 1.6)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 8, children: [
                    OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    AccountScreen(account: account))),
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                            account.signedIn ? 'Your account' : 'Sign in')),
                    if (account.signedIn)
                      FilledButton.icon(
                          onPressed: store.syncing
                              ? null
                              : () async {
                                  try {
                                    if (store.cloudConnected) {
                                      await store.sync();
                                    } else {
                                      await store.connectAccount(account);
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      showNotice(context,
                                          'Sign in again to connect your progress.');
                                    }
                                  }
                                },
                          icon: const Icon(Icons.sync),
                          label: Text(store.syncing
                              ? 'Syncing…'
                              : store.cloudConnected
                                  ? 'Sync now'
                                  : 'Connect progress')),
                  ]),
                  if (store.syncError != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(store.syncError!,
                            style: const TextStyle(color: SbdColors.cyan))),
                  if (store.lastSynced != null &&
                      !store.syncing &&
                      store.syncError == null)
                    const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Text('Progress synced.',
                            style: TextStyle(color: SbdColors.success))),
                  if (store.cloudConnected)
                    TextButton(
                        onPressed: store.syncing
                            ? null
                            : () async {
                                final approved = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Add device progress?'),
                                            content: Text(
                                                'Add this device’s offline lessons, learning activity, and bookmarks to ${account.email}. Existing account records will be kept.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel')),
                                              FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text(
                                                      'Add my progress'))
                                            ]));
                                if (approved == true) {
                                  await store.importDeviceProgress();
                                }
                              },
                        child: const Text('Add my device-only progress')),
                ])),
            const SizedBox(height: 26),
            for (final path in learningPaths)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Panel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(path.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 14),
                        ProgressLine(value: store.progressIn(path)),
                        const SizedBox(height: 10),
                        Text(
                            '${store.completedIn(path)} of ${path.lessons.length} complete'),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: () =>
                                openLearningPath(context, store, path),
                            child: const Text('Continue learning')),
                      ]))),
          ]));
}
