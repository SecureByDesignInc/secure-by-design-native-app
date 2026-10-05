import 'package:flutter/material.dart';
import '../data/learning_store.dart';
import '../data/membership.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/account_navigation.dart';

class MembershipInvitation extends StatelessWidget {
  const MembershipInvitation({super.key});
  @override
  Widget build(BuildContext context) => Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Kicker('Your next step'),
        const SizedBox(height: 12),
        Text('Keep learning with Community.',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
            'Your current lessons and learning tools are included. Explore what’s coming with Builder and Guided.',
            style: TextStyle(color: SbdColors.muted, height: 1.6)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () =>
                AccountNavigation.openAccount(context, memberships: true),
            icon: const Icon(Icons.layers_outlined),
            label: const Text('Explore plans in My Account')),
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

  bool _annual = false;
  String _selected = 'community';
  void _choose(String id) {
    widget.store.haptics.selectionChanged();
    setState(() => _selected = id);
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
                child: const Text('Continue with Community')),
          ]));
        }
        if (!snapshot.hasData) {
          return const Text('Loading membership options…');
        }
        final catalog = snapshot.data!;
        final plan = catalog.plans.firstWhere((p) => p.id == _selected);
        final yearly = _annual && plan.annualPrice != null;
        final amount = yearly ? plan.annualPrice! : plan.monthlyPrice;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Kicker('Learn it. Build it. Put it to work.'),
          const SizedBox(height: 12),
          Text('Membership options',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          const Text(
              'Start with Community. Add hands-on projects or personal guidance when you’re ready.',
              style: TextStyle(color: SbdColors.muted, height: 1.6)),
          const SizedBox(height: 14),
          OutlinedButton(
              onPressed: widget.onContinue,
              child: const Text('Continue with Community')),
          const SizedBox(height: 22),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ChoiceChip(
                label: const Text('Monthly'),
                selected: !_annual,
                showCheckmark: false,
                onSelected: (_) {
                  widget.store.haptics.selectionChanged();
                  setState(() => _annual = false);
                }),
            ChoiceChip(
                label: const Text('Annual · save 25%'),
                selected: _annual,
                showCheckmark: false,
                onSelected: (_) {
                  widget.store.haptics.selectionChanged();
                  setState(() => _annual = true);
                }),
          ]),
          const SizedBox(height: 10),
          const Text(
              'Annual savings apply to Builder. Guided is monthly. All prices are in USD.',
              style: TextStyle(color: SbdColors.muted, height: 1.6)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900 &&
                MediaQuery.textScalerOf(context).scale(16) <= 20;
            final width =
                wide ? (constraints.maxWidth - 28) / 3 : constraints.maxWidth;
            return Wrap(spacing: 14, runSpacing: 16, children: [
              for (final item in catalog.plans)
                SizedBox(width: width, child: _planCard(item))
            ]);
          }),
          const SizedBox(height: 20),
          Semantics(
              liveRegion: true,
              child: Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${plan.name} · \$$amount${plan.available ? '' : yearly ? '/year · coming soon' : '/month · coming soon'}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                        plan.available
                            ? 'Keep learning with the current courses and tools. Sharing is always optional. No subscription or automatic charges.'
                            : plan.id == 'builder'
                                ? '${yearly ? 'Pay \$180 for 12 months and save \$60 compared with 12 monthly payments.' : 'Planned price: \$20 for one month of Builder access.'} Your own lab hardware, software and hosting are separate.'
                                : 'Includes Builder, one 30-minute coaching call and one project review each month. Enrollment opens when coaching appointments are available.',
                        style: const TextStyle(
                            color: SbdColors.muted, height: 1.6)),
                    if (!plan.available) ...[
                      const SizedBox(height: 12),
                      Text(
                          'Planned billing: renews at \$$amount/${yearly ? 'year' : 'month'}. Cancel before renewal; access continues through the paid period. Community access and saved progress remain.',
                          style: const TextStyle(
                              color: SbdColors.muted, height: 1.6)),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                        'Builder and Guided are coming soon. Their benefits are being prepared; paid enrollment and checkout are not open.',
                        style: TextStyle(height: 1.6)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: widget.onContinue,
                        child: const Text('Continue with Community')),
                  ]))),
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

  Widget _planCard(MembershipPlan plan) {
    final yearly = _annual && plan.annualPrice != null;
    final amount = yearly ? plan.annualPrice! : plan.monthlyPrice;
    return Panel(
        gradient: _selected == plan.id,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              plan.available
                  ? 'Available now'
                  : 'Coming soon · planned benefits',
              style: const TextStyle(color: SbdColors.cyan, height: 1.5)),
          const SizedBox(height: 14),
          Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(plan.tagline,
              style: const TextStyle(color: SbdColors.muted, height: 1.5)),
          const SizedBox(height: 18),
          Text(
              '\$$amount${plan.available ? '' : yearly ? ' / year' : ' / month'}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              plan.available
                  ? 'No payment details required.'
                  : yearly
                      ? '\$180 billed yearly · \$15/month equivalent.'
                      : '\$${plan.monthlyPrice} billed monthly when available.',
              style: const TextStyle(color: SbdColors.muted, height: 1.5)),
          const SizedBox(height: 18),
          for (final feature in plan.features)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check,
                              color: SbdColors.cyan, size: 18)),
                      const SizedBox(width: 9),
                      Expanded(
                          child: Text(feature,
                              style: const TextStyle(height: 1.6))),
                    ])),
          const SizedBox(height: 8),
          if (plan.available)
            FilledButton(
                onPressed: widget.onContinue,
                child: const Text('Continue with Community'))
          else
            OutlinedButton(
                onPressed: () => _choose(plan.id),
                child: Text(_selected == plan.id
                    ? '${plan.name} details selected'
                    : 'Explore ${plan.name}')),
        ]));
  }
}
