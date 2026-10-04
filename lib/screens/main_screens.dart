import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/app_support.dart';
import '../widgets/getting_started.dart';
import 'path_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onTab});
  final LearningStore store;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final path = store.currentPath;
    final completed = store.completedIn(path);
    return PageContent(
      children: [
        const Kicker('Your next chapter'),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Follow your\n'),
              const TextSpan(
                text: 'curiosity.',
                style: TextStyle(color: SbdColors.cyan),
              ),
            ],
          ),
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 38),
        ),
        const SizedBox(height: 15),
        const Text(
          'One idea at a time. Build your understanding\nof technology and why security matters.',
          style: TextStyle(color: SbdColors.muted, fontSize: 16, height: 1.65),
        ),
        const SizedBox(height: 28),
        GettingStartedCard(store: store, onTab: onTab),
        Panel(
          gradient: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TopicBadge(path.icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kicker(
                          completed > 0 && completed < path.lessons.length
                              ? 'Pick up where you left off'
                              : completed == path.lessons.length
                                  ? 'Path completed'
                                  : 'A good place to start',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          path.category,
                          style: const TextStyle(
                            color: SbdColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Text(
                path.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 27),
              ),
              const SizedBox(height: 12),
              Text(
                path.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 16,
                        color: SbdColors.cyan,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${path.lessons.length} lessons',
                        style: const TextStyle(
                          color: SbdColors.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: SbdColors.cyan,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'About ${path.minutes} min',
                        style: const TextStyle(
                          color: SbdColors.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 23),
              if (completed > 0) ...[
                ProgressLine(value: store.progressIn(path)),
                const SizedBox(height: 8),
                Text(
                  '$completed of ${path.lessons.length} completed',
                  style: const TextStyle(color: SbdColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => openLearningPath(context, store, path),
                  icon: Icon(
                    completed == path.lessons.length
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    size: 21,
                  ),
                  label: Text(
                    completed == 0
                        ? 'Start learning'
                        : completed == path.lessons.length
                            ? 'Revisit this path'
                            : 'Continue learning',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 29),
        Row(
          children: [
            Expanded(
              child: Text(
                'More to explore',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => onTab(1),
              child: const Text('All paths'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ResponsiveCards(
          children: learningPaths
              .where((p) => p.id != path.id)
              .map((p) => PathCard(path: p, store: store))
              .toList(),
        ),
        const SizedBox(height: 28),
        Panel(
          onTap: () => onTab(2),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                color: SbdColors.cyan,
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep something useful',
                      style: TextStyle(
                        color: SbdColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Official guides. Your next question.',
                      style: TextStyle(
                        color: SbdColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SbdColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Educate. Empower. Secure the future.',
          style: TextStyle(
            color: SbdColors.muted,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class PathCard extends StatelessWidget {
  const PathCard({super.key, required this.path, required this.store});
  final LearningPath path;
  final LearningStore store;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${path.title}, ${path.lessons.length} lessons',
        child: Panel(
          onTap: () => openLearningPath(context, store, path),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TopicBadge(path.icon),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: SbdColors.muted),
                ],
              ),
              const SizedBox(height: 20),
              Kicker(path.category),
              const SizedBox(height: 10),
              Text(path.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                path.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const Divider(color: SbdColors.border, height: 1),
              const SizedBox(height: 15),
              Text(
                '${path.lessons.length} lessons · About ${path.minutes} min',
                style: const TextStyle(color: SbdColors.muted, fontSize: 13),
              ),
              if (store.completedIn(path) > 0) ...[
                const SizedBox(height: 12),
                ProgressLine(value: store.progressIn(path)),
              ],
            ],
          ),
        ),
      );
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.store});
  final LearningStore store;
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _category = 'All paths';
  @override
  Widget build(BuildContext context) => PageContent(
        children: [
          const PageTitle(
            'Build your foundation.',
            'Choose a question. Follow a short path.\nPut the idea into practice.',
            kicker: 'Learn your way',
          ),
          Wrap(
            spacing: 9,
            runSpacing: 8,
            children: ['All paths', 'Technology', 'Risk & compliance']
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: SbdColors.cyan.withValues(alpha: 0.13),
                    backgroundColor: SbdColors.surfaceLow,
                    side: BorderSide(
                      color: _category == category
                          ? SbdColors.cyan.withValues(alpha: 0.5)
                          : SbdColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: _category == category
                          ? SbdColors.cyan
                          : SbdColors.muted,
                      fontSize: 14,
                    ),
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          ResponsiveCards(
            children: learningPaths
                .where(
                    (p) => _category == 'All paths' || p.category == _category)
                .map((p) => PathCard(path: p, store: widget.store))
                .toList(),
          ),
          const SizedBox(height: 30),
          const Text(
            'Three sample paths to explore the app. More lessons and hands-on learning can grow from here.',
            style: TextStyle(color: SbdColors.muted, fontSize: 14, height: 1.6),
          ),
        ],
      );
}

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, required this.store});
  final LearningStore store;
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  bool _savedOnly = false;
  @override
  Widget build(BuildContext context) {
    final visible = resources
        .where((r) => !_savedOnly || widget.store.isSaved(r.id))
        .toList();
    return PageContent(
      children: [
        const PageTitle(
          'Good questions.\nUseful resources.',
          'Go deeper with official guides and\nSecure By Design resources.',
          kicker: 'Keep exploring',
        ),
        SegmentedButton<bool>(
          segments: [
            const ButtonSegment(
              value: false,
              label: Text('All resources'),
              icon: Icon(Icons.menu_book_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Saved (${widget.store.saved.length})'),
              icon: const Icon(Icons.bookmark_border),
            ),
          ],
          selected: {_savedOnly},
          onSelectionChanged: (value) =>
              setState(() => _savedOnly = value.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
        ),
        const SizedBox(height: 24),
        if (visible.isEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bookmark_border_rounded,
                  color: SbdColors.cyan,
                  size: 34,
                ),
                const SizedBox(height: 18),
                Text(
                  'Make this your collection.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Save a resource with the bookmark button. You’ll find it here when you need it.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => setState(() => _savedOnly = false),
                  child: const Text('Explore resources'),
                ),
              ],
            ),
          )
        else
          ResponsiveCards(
            children: visible
                .map((r) => _ResourceCard(resource: r, store: widget.store))
                .toList(),
          ),
        const SizedBox(height: 24),
        const Text(
          'Saved links stay on this device. External resources open in your browser and need an internet connection.',
          style: TextStyle(color: SbdColors.muted, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 24),
        FeedbackPanel(store: widget.store),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.store});
  final LearningResource resource;
  final LearningStore store;
  @override
  Widget build(BuildContext context) {
    final saved = store.isSaved(resource.id);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TopicBadge(resource.icon),
              const Spacer(),
              IconButton(
                tooltip: saved
                    ? 'Remove ${resource.title} from saved'
                    : 'Save ${resource.title}',
                onPressed: () async {
                  try {
                    await store.toggleSaved(resource.id);
                  } catch (_) {
                    if (context.mounted) {
                      showNotice(
                        context,
                        'This resource could not be saved. Please try again.',
                      );
                    }
                  }
                },
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: saved ? SbdColors.cyan : SbdColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Kicker(resource.publisher),
          const SizedBox(height: 10),
          Text(resource.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 11),
          Text(
            resource.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => openResource(context, resource.url,
                onOpened: () => store.analytics.resourceOpened(resource.id)),
            icon: const Icon(Icons.open_in_new, size: 17),
            label: const Text('Open resource'),
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.store, required this.onLearn});
  final LearningStore store;
  final VoidCallback onLearn;
  @override
  Widget build(BuildContext context) => PageContent(
        children: [
          const PageTitle(
            'Every step counts.',
            'See what you’ve learned and\nwhere your curiosity can take you next.',
            kicker: 'Your progress',
          ),
          Panel(
            gradient: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('Your foundation'),
                const SizedBox(height: 15),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${store.completed.length}',
                        style: const TextStyle(
                          color: SbdColors.cyan,
                          fontSize: 46,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${store.totalLessons}',
                        style: const TextStyle(
                          color: SbdColors.muted,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'lessons completed',
                  style: TextStyle(color: SbdColors.ink, fontSize: 16),
                ),
                const SizedBox(height: 23),
                ProgressLine(
                    value: store.completed.length / store.totalLessons),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Text(
                      '${learningPaths.where((p) => store.completedIn(p) == p.lessons.length).length} paths completed',
                      style:
                          const TextStyle(color: SbdColors.muted, fontSize: 14),
                    ),
                    Text(
                      '${store.saved.length} saved resources',
                      style:
                          const TextStyle(color: SbdColors.muted, fontSize: 14),
                    ),
                  ],
                ),
                if (store.completed.isEmpty) ...[
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: onLearn,
                    child: const Text('Choose your first path'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Your learning paths',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final path in learningPaths) ...[
            Panel(
              onTap: () => openLearningPath(context, store, path),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopicBadge(path.icon, size: 42),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          path.title,
                          style: const TextStyle(
                            color: SbdColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chevron_right,
                        color: SbdColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProgressLine(value: store.progressIn(path)),
                  const SizedBox(height: 10),
                  Text(
                    '${store.completedIn(path)} of ${path.lessons.length} lessons completed',
                    style: const TextStyle(
                      color: SbdColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smartphone_outlined, size: 18, color: SbdColors.cyan),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your progress is saved on this device. Optional account sign-in does not sync progress across devices yet.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
