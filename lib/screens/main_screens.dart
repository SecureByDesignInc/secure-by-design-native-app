import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/learning_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/app_support.dart';

/// References to read and save, from My Account.
Future<void> openResources(BuildContext context, LearningStore store) =>
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Resources & references')),
                body: AnimatedBuilder(
                    animation: store,
                    builder: (context, child) => ResourcesScreen(store: store)))));

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, required this.store});
  final LearningStore store;
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  bool _savedOnly = false;

  void _selectFilter(bool savedOnly) {
    if (_savedOnly == savedOnly) return;
    widget.store.haptics.selectionChanged();
    setState(() => _savedOnly = savedOnly);
  }

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
              label: Text(
                  'Saved (${resources.where((r) => widget.store.isSaved(r.id)).length})'),
              icon: const Icon(Icons.bookmark_border),
            ),
          ],
          selected: {_savedOnly},
          onSelectionChanged: (value) => _selectFilter(value.first),
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
                  onPressed: () => _selectFilter(false),
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
                  final wasSaved = store.isSaved(resource.id);
                  final scope = store.accountScope;
                  try {
                    await store.toggleSaved(resource.id);
                    if (context.mounted &&
                        scope == store.accountScope &&
                        wasSaved != store.isSaved(resource.id)) {
                      store.haptics.bookmarkChanged();
                    }
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
