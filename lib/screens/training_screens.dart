import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../data/training_categories.dart';
import '../theme.dart';
import '../widgets/account_navigation.dart';
import '../widgets/common.dart';
import '../widgets/site_footer.dart';
import '../widgets/tile_art.dart';
import '../widgets/training_card.dart';
import 'hub_screens.dart';
import 'path_screen.dart';

export '../widgets/training_card.dart' show TrainingCard, ComingSoonCard, CourseShelf, CourseExpansion;
export 'my_account_screen.dart' show MyLearningScreen;

/// The Training Hub, as the website lays it out (app/videos/training-hub.tsx):
/// a greeting with search and Saved, the library's groups as a row of links,
/// then the hub's rows: Build the Network (1 November 2026: first, all twelve
/// courses in order), the Tools and the seven RMF steps, Logging & monitoring,
/// Authorize the network, and the closing line to the System Hub. A group link
/// or a search shows that group or the results instead.
class TrainingLibraryScreen extends StatefulWidget {
  const TrainingLibraryScreen(
      {super.key, required this.store, this.onSystemHub, this.onAccount, this.footer = true});
  final LearningStore store;

  /// Opens the System Hub tab from the Tools (website, 27 October 2026).
  final VoidCallback? onSystemHub;

  /// Opens My Account (Saved materials, the free Community account).
  final VoidCallback? onAccount;
  final bool footer;
  @override
  State<TrainingLibraryScreen> createState() => _TrainingLibraryScreenState();
}

class _TrainingLibraryScreenState extends State<TrainingLibraryScreen> {
  String query = '';
  String category = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String text) => text.toLowerCase().contains(query.trim().toLowerCase());

  /// Course numbers in the website's order: 1.9 and 1.10 sit between 1.8 and 1.11.
  static List<int> _order(String number) =>
      number.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  static int compareNumbers(String a, String b) {
    final x = _order(a), y = _order(b);
    for (var i = 0; i < x.length && i < y.length; i++) {
      if (x[i] != y[i]) return x[i].compareTo(y[i]);
    }
    return x.length.compareTo(y.length);
  }

  void _openAccount() {
    if (widget.onAccount != null) {
      widget.onAccount!();
    } else {
      AccountNavigation.openAccount(context);
    }
  }

  void _go(String group) {
    widget.store.haptics.selectionChanged();
    setState(() {
      category = group;
      query = '';
      _search.clear();
    });
  }

  static String greeting(DateTime now) =>
      now.hour < 12 ? 'Good morning.' : now.hour < 18 ? 'Good afternoon.' : 'Good evening.';

  static String countLabel(int courses, int soon) {
    final open = '$courses ${courses == 1 ? 'course' : 'courses'}';
    return soon == 0 ? open : '$open · $soon coming soon';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final searching = query.trim().isNotEmpty;
    final matches = publishedPaths.where((path) {
      final group = categoryFor(path);
      return (category.isEmpty || group.id == category) &&
          _matches('${path.title} ${path.subtitle} ${path.description} ${group.title}');
    }).toList();
    final soon = currentCatalog.comingSoon
        .where((course) =>
            (category.isEmpty || course.categoryId == category) &&
            _matches('${course.number} ${course.title} ${course.subtitle} ${course.description} coming soon'))
        .toList();
    final selected = trainingCategories.where((g) => g.id == category).firstOrNull;
    final signedIn = store.cloudConnected;

    return AnimatedBuilder(
        animation: store,
        builder: (context, _) => PageContent(
            footer: widget.footer ? SiteFooter(analytics: store.analytics) : null,
            children: [
              // The library's groups (the website's sidebar; a row of links on phones).
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(children: [
                    ChoiceChip(
                        label: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.home_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Hub'),
                        ]),
                        selected: category.isEmpty && !searching,
                        onSelected: (_) => _go('')),
                    for (final group in trainingCategories) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                          avatar: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: SbdColors.family(group.id == 'network-authorization'
                                      ? 'authorize'
                                      : 'identity'),
                                  borderRadius: BorderRadius.circular(2))),
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(group.title),
                            const SizedBox(width: 8),
                            Text('${group.pathIds.length + group.comingSoon.length}',
                                style: const TextStyle(
                                    fontFamily: sbdMono,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: SbdColors.dim)),
                          ]),
                          selected: category == group.id,
                          onSelected: (_) => _go(group.id)),
                    ],
                  ])),
              const SizedBox(height: 22),
              // The greeting, the search and Saved (.th-top).
              Text(greeting(DateTime.now()), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                  signedIn
                      ? 'Welcome back. Here’s what’s new in your library.'
                      : 'Welcome to the Training Hub: every course to build the network and take it to an Authorization to Operate, in one library.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15)),
              if (!signedIn) ...[
                const SizedBox(height: 6),
                Text.rich(TextSpan(children: [
                  WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: InkWell(
                          onTap: _openAccount,
                          child: const Text('Create a free Community account',
                              style: TextStyle(
                                  color: SbdColors.cyan, fontSize: 14, fontWeight: FontWeight.w600)))),
                  const TextSpan(
                      text: ' to keep your progress and saved materials.',
                      style: TextStyle(color: SbdColors.muted, fontSize: 14)),
                ])),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                            hintText: 'Search a course, system or topic',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(() {
                                      query = '';
                                      _search.clear();
                                    }))),
                        onChanged: (v) => setState(() => query = v))),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                    key: const ValueKey('saved-materials'),
                    onPressed: _openAccount,
                    icon: const Icon(Icons.bookmark_border, size: 16, color: SbdColors.cyan),
                    label: Text(MediaQuery.sizeOf(context).width < 400 ? '' : 'Saved'),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width < 400 ? 10 : 14))),
              ]),
              const SizedBox(height: 24),
              if (searching) ...[
                Text(
                    '${matches.length + soon.length} ${matches.length + soon.length == 1 ? 'result' : 'results'} for “${query.trim()}”',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (matches.isEmpty && soon.isEmpty)
                  Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('No matching training. Try another topic.',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text(
                        'Search by a name like SBD-DC01, or clear the search to see the full library.',
                        style: TextStyle(color: SbdColors.muted, fontSize: 14)),
                  ]))
                else
                  CourseShelf(
                      store: store,
                      courses: matches,
                      comingSoon: soon,
                      grid: true,
                      sort: compareNumbers),
              ] else if (selected != null) ...[
                TextButton.icon(
                    onPressed: () => _go(''),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to the Hub')),
                const SizedBox(height: 10),
                _GroupHead(group: selected, count: countLabel(matches.length, soon.length)),
                const SizedBox(height: 16),
                CourseShelf(
                    store: store,
                    courses: matches,
                    comingSoon: soon,
                    grid: true,
                    sort: compareNumbers),
                if (selected.id == 'network-authorization') ...[
                  const SizedBox(height: 24),
                  AtoBuilderSection(store: store, onSystemHub: widget.onSystemHub),
                ],
              ] else ...[
                if (signedIn) _featured(context),
                for (final group in trainingCategories)
                  if (group.id == 'network-build') ...[
                    CourseShelf(
                        title: group.title,
                        note: '${group.pathIds.length + group.comingSoon.length} courses · take them in order',
                        store: store,
                        courses: publishedPaths.where(group.contains).toList(),
                        comingSoon: group.comingSoon,
                        sort: compareNumbers),
                    const SizedBox(height: 34),
                    // The ATO Package Builder lives here, as on the website (27 October 2026):
                    // the Tools and the seven RMF steps follow the Build the Network row.
                    AtoBuilderSection(store: store, onSystemHub: widget.onSystemHub),
                    const SizedBox(height: 10),
                    _logging(context),
                  ] else ...[
                    CourseShelf(
                        title: group.id == 'network-authorization' ? 'Authorize the network' : group.title,
                        note: countLabel(group.pathIds.length, group.comingSoon.length),
                        store: store,
                        courses: publishedPaths.where(group.contains).toList(),
                        comingSoon: group.comingSoon,
                        sort: compareNumbers),
                    const SizedBox(height: 34),
                  ],
                HubFootnote(onSystemHub: widget.onSystemHub ?? () {}),
              ],
            ]));
  }

  /// The signed-in learner's course in progress (the website shows the featured
  /// course only then), with its next lesson a tap away.
  Widget _featured(BuildContext context) {
    final store = widget.store;
    final path = store.currentPath;
    final next = store.nextLesson(path);
    if (store.completedIn(path) == 0 || next == null) return const SizedBox.shrink();
    final family = artFamilyFor(path.id, path.categoryId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: softSurface(featured: true, radius: 20),
        child: LayoutBuilder(builder: (context, constraints) {
          final copy = Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF12324A),
                        border: Border.all(color: const Color(0xFF2F5873)),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Kicker('Continue where you left off')),
                const SizedBox(height: 12),
                Text(path.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(path.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(
                    'Course ${path.number} · ${store.completedIn(path)} of ${path.lessons.length} lessons complete · next: ${next.title}',
                    style: const TextStyle(color: SbdColors.ink, fontSize: 13, height: 1.5)),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => LessonScreen(store: store, lesson: next, path: path))),
                      child: const Text('Continue the course')),
                  OutlinedButton(
                      onPressed: () => openLearningPath(context, store, path),
                      child: const Text('Open the course overview')),
                ]),
              ]));
          final art = AspectRatio(aspectRatio: 16 / 9, child: TileArt(family: family, glowAlpha: 0.22, cell: 26));
          if (constraints.maxWidth < 620) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [art, copy]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 3, child: copy),
            Expanded(
                flex: 2,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: art))),
          ]);
        }),
      ),
    );
  }

  /// The website's Logging & monitoring row: the three logging courses.
  Widget _logging(BuildContext context) {
    const ids = ['logging-pipeline', 'audit-repository', 'splunk-analysis'];
    final courses = [for (final id in ids) ...publishedPaths.where((p) => p.id == id)];
    if (courses.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(bottom: 34),
        child: CourseShelf(
            title: 'Logging & monitoring',
            note: countLabel(courses.length, 0),
            store: widget.store,
            courses: courses));
  }
}

/// A group's opening in the library view (.th-group-head).
class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.group, required this.count});
  final TrainingCategory group;
  final String count;
  @override
  Widget build(BuildContext context) {
    final courses = publishedPaths.where(group.contains).toList();
    final family = group.id == 'network-authorization' ? 'authorize' : 'identity';
    final kicker = courses.length > 1
        ? 'Learning path · Courses ${courses.first.number}–${courses.last.number}'
        : courses.isEmpty
            ? 'Learning path'
            : 'Learning path · Course ${courses.first.number}';
    return Panel(
        radius: 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Kicker(kicker, color: SbdColors.family(family)),
          const SizedBox(height: 8),
          Text(group.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(group.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(count,
              style: const TextStyle(fontFamily: sbdMono, fontSize: 12, color: SbdColors.muted)),
        ]));
  }
}
