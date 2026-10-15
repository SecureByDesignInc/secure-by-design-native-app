import 'package:flutter/material.dart';
import '../data/learning_store.dart';
import '../data/membership.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/account_navigation.dart';

// Owner request, 13 October 2026: memberships show one "Coming soon"
// statement and no specifics (see lib/data/membership.dart).
class MembershipInvitation extends StatelessWidget {
  const MembershipInvitation({super.key});
  @override
  Widget build(BuildContext context) => Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Kicker('Your next step'),
        const SizedBox(height: 12),
        Text('Memberships are coming soon.',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
            'Keep learning with the current lessons and tools in the meantime.',
            style: TextStyle(color: SbdColors.muted, height: 1.6)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () =>
                AccountNavigation.openAccount(context, memberships: true),
            icon: const Icon(Icons.layers_outlined),
            label: const Text('View membership options')),
      ]));
}

class MembershipSection extends StatefulWidget {
  const MembershipSection(
      {super.key, required this.store, required this.onContinue, this.onReady});
  final LearningStore store;
  final VoidCallback onContinue;
  final VoidCallback? onReady;
  @override
  State<MembershipSection> createState() => _MembershipSectionState();
}

class _MembershipSectionState extends State<MembershipSection> {
  late Future<MembershipCatalog> _catalog = _loadCatalog();
  Future<MembershipCatalog> _loadCatalog() async {
    final catalog = await MembershipCatalog.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady?.call();
    });
    return catalog;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MembershipCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Membership details could not be loaded.'),
            TextButton(
                onPressed: () => setState(() => _catalog = _loadCatalog()),
                child: const Text('Try again')),
            TextButton(
                onPressed: widget.onContinue,
                child: const Text('Keep learning in the Training Library')),
          ]));
        }
        if (!snapshot.hasData) {
          return const Text('Loading membership options…');
        }
        final catalog = snapshot.data!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Kicker('Learn it. Build it. Put it to work.'),
          const SizedBox(height: 12),
          Text('Membership options',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: SbdColors.surface,
                  border: Border.all(color: SbdColors.cyan),
                  borderRadius: BorderRadius.circular(999)),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.schedule, size: 18, color: SbdColors.cyan),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(catalog.comingSoon,
                            style: const TextStyle(
                                color: SbdColors.cyan,
                                fontWeight: FontWeight.w600))),
                  ]))),
          const SizedBox(height: 14),
          Text(catalog.comingSoonDetail,
              style: const TextStyle(color: SbdColors.muted, height: 1.6)),
          const SizedBox(height: 14),
          OutlinedButton(
              onPressed: widget.onContinue,
              child: const Text('Keep learning in the Training Library')),
          const SizedBox(height: 24),
          Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Kicker('A note from Secure By Design'),
                const SizedBox(height: 12),
                Text(catalog.creatorNote, style: const TextStyle(height: 1.7)),
                const SizedBox(height: 14),
                const Text('Secure By Design',
                    style: TextStyle(color: SbdColors.muted)),
              ])),
        ]);
      });
}
