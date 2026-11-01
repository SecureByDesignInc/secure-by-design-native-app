import 'dart:async';
import 'package:flutter/material.dart';

import 'app_tabs.dart';
import 'data/learning_store.dart';
import 'data/account.dart';
import 'screens/home_screen.dart';
import 'screens/hub_screens.dart';
import 'screens/training_screens.dart';
import 'widgets/account_navigation.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/app_support.dart';

class SecureByDesignApp extends StatefulWidget {
  const SecureByDesignApp({super.key, required this.store});
  final LearningStore store;
  @override
  State<SecureByDesignApp> createState() => _SecureByDesignAppState();
}

class _SecureByDesignAppState extends State<SecureByDesignApp> {
  final _shellKey = GlobalKey<_AppShellState>();

  @override
  Widget build(BuildContext context) => AccountNavigation(
      onAccount: () => _shellKey.currentState?._openAccount(),
      onTraining: () =>
          _shellKey.currentState?._select(AppTab.training.index),
      child: MaterialApp(
        title: 'Secure By Design',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: AppShell(key: _shellKey, store: widget.store),
      ));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final LearningStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final _account = AccountStore();
  Timer? _dayRefresh;
  @override
  void dispose() {
    _dayRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _account.removeListener(_accountChanged);
    _account.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayRefresh = Timer.periodic(
        const Duration(minutes: 1), (_) => widget.store.refreshDay());
    widget.store.analytics.appOpened();
    _account.addListener(_accountChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      widget.store.sync();
    }
  }

  void _accountChanged() {
    if (widget.store.cloudConnected &&
        (!_account.signedIn ||
            widget.store.accountScope != _account.accountId)) {
      widget.store.disconnectAccount();
    }
  }

  int _tab = 0;
  int _accountVisit = 0;
  void _select(int index) {
    if (index == _tab) return;
    widget.store.haptics.selectionChanged();
    setState(() {
      _tab = index;
    });
  }

  void _openAccount() {
    widget.store.haptics.selectionChanged();
    setState(() {
      _tab = AppTab.account.index;
      _accountVisit++;
    });
  }

  void _about() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Brand(),
                const SizedBox(height: 24),
                Text('Room to grow.',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Build your skills with the courses in the Training Hub. Explore the network, save useful materials, and continue your learning across devices.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  'Lessons and the system reference are available offline. Connect account progress in My Account to sync. Downloadable materials, the 3D view and the Cyber Range round need a connection.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  'Sign-in and progress sync are optional. Device-only records remain separate until you choose to add them.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                const CreatorNote(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('My Account'),
                  onPressed: () => AccountNavigation.openAccount(context),
                ),
                const SizedBox(height: 22),
                if (widget.store.haptics.supported) ...[
                  HapticsSetting(haptics: widget.store.haptics),
                  const SizedBox(height: 22),
                ],
                FeedbackPanel(store: widget.store),
                const SizedBox(height: 22),
                AnalyticsSetting(analytics: widget.store.analytics),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep exploring'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final wide = MediaQuery.sizeOf(context).width >= 860;
          final tab = AppTab.values[_tab];
          final page = switch (tab) {
            AppTab.home => HomeScreen(store: widget.store),
            AppTab.systemHub => SystemHubScreen(store: widget.store),
            AppTab.training => TrainingLibraryScreen(
                store: widget.store,
                onSystemHub: () => _select(AppTab.systemHub.index),
                onAccount: _openAccount),
            AppTab.community => CommunityHubScreen(store: widget.store),
            AppTab.account => MyLearningScreen(
                key: ValueKey(_accountVisit),
                store: widget.store,
                account: _account),
          };
          // The site header: the branding on the dark stage, ruled off beneath.
          final header = Container(
            padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 10, wide ? 20 : 8, 10),
            decoration: const BoxDecoration(
              color: SbdColors.stage,
              border: Border(bottom: BorderSide(color: SbdColors.borderHeader)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: wide
                      ? Text(tab.title,
                          style: Theme.of(context).textTheme.titleMedium)
                      : const Brand(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _about,
                  tooltip: 'About this preview',
                  icon: const Icon(Icons.info_outline,
                      color: SbdColors.muted, size: 23),
                ),
              ],
            ),
          );
          final content = Column(children: [header, Expanded(child: page)]);
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: wide
                  ? Row(
                      children: [
                        Container(
                          width: 240,
                          decoration: const BoxDecoration(
                            color: SbdColors.stage,
                            border: Border(
                              right: BorderSide(color: SbdColors.borderHeader),
                            ),
                          ),
                          // Hub names wrap at large text sizes, so the sidebar
                          // scrolls instead of running off the screen.
                          child: CustomScrollView(slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(20, 22, 12, 26),
                                    child: Brand(logoSize: 52),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: SbdColors.navSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: SbdColors.navBorder),
                                      ),
                                      child: Column(children: [
                                        for (final item in AppTab.values)
                                          _SideLink(
                                              tab: item,
                                              selected: item.index == _tab,
                                              onTap: () => _select(item.index)),
                                      ]),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: Text(
                                      'Educate. Empower.\nSecure the future.',
                                      style: TextStyle(
                                        color: SbdColors.muted,
                                        fontSize: 13,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
            bottomNavigationBar: wide
                ? null
                : Container(
                    decoration: const BoxDecoration(
                      color: SbdColors.stage,
                      border: Border(
                          top: BorderSide(color: SbdColors.borderHeader)),
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: AppTabBar(
                          selected: _tab,
                          onSelected: _select,
                        ),
                      ),
                    ),
                  ),
          );
        },
      );
}

/// A navigation item in the wide-screen sidebar, on the site's current-item
/// gradient when selected.
class _SideLink extends StatelessWidget {
  const _SideLink({required this.tab, required this.selected, required this.onTap});
  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('tab-${tab.name}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? SbdColors.navCurrent : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? SbdColors.navCurrentBorder : Colors.transparent),
              ),
              child: Row(children: [
                Icon(selected ? tab.selectedIcon : tab.icon,
                    size: 20, color: selected ? Colors.white : SbdColors.navInk),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(tab.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? Colors.white : SbdColors.navInk))),
              ]),
            ),
          ),
        ),
      );
}
