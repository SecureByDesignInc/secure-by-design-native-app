import 'dart:async';
import 'package:flutter/material.dart';

import 'data/learning_store.dart';
import 'data/account.dart';
import 'screens/onboarding_screen.dart';
import 'screens/training_screens.dart';
import 'widgets/account_navigation.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/app_support.dart';
import 'widgets/getting_started.dart';

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
      onTraining: () => _shellKey.currentState?._select(1),
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
    if (widget.store.gettingStarted.shouldPresentWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openOnboarding(context, widget.store, firstRun: true);
      });
    }
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
  static const labels = ['Home', 'Training', 'Explore', 'My Account'];
  static const icons = [
    Icons.home_outlined,
    Icons.auto_stories_outlined,
    Icons.explore_outlined,
    Icons.person_outline,
  ];
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
      _tab = 3;
      _accountVisit++;
    });
  }

  void _about() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: SbdColors.surfaceLow,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 10, 26, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Brand(),
                const SizedBox(height: 26),
                Text(
                  'Room to grow.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Build your skills with the published Training Library. Explore the network, save useful materials, and continue your learning across devices.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Lessons and the system reference are available offline. Connect account progress in My Account to sync. Downloadable materials and the 3D view require a connection.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sign-in and progress sync are optional. Device-only records remain separate until you choose to add them. Cyber Range remains a request-access preview.',
                  style: TextStyle(
                    color: SbdColors.muted,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                const CreatorNote(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline),
                  label: const Text('My Account'),
                  onPressed: () => AccountNavigation.openAccount(context),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Personalize my learning'),
                  onPressed: () {
                    Navigator.pop(context);
                    openOnboarding(this.context, widget.store);
                  },
                ),
                const SizedBox(height: 24),
                if (widget.store.haptics.supported) ...[
                  HapticsSetting(haptics: widget.store.haptics),
                  const SizedBox(height: 24),
                ],
                GettingStartedSetting(store: widget.store.gettingStarted),
                const SizedBox(height: 24),
                FeedbackPanel(store: widget.store),
                const SizedBox(height: 24),
                AnalyticsSetting(analytics: widget.store.analytics),
                const SizedBox(height: 24),
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
          final page = switch (_tab) {
            0 => TrainingHome(store: widget.store, onTab: _select),
            1 => TrainingLibraryScreen(store: widget.store),
            2 => ExploreScreen(store: widget.store),
            _ => MyLearningScreen(
                key: ValueKey(_accountVisit),
                store: widget.store,
                account: _account),
          };
          final content = Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 36 : 22,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: wide
                          ? Text(
                              labels[_tab],
                              style: Theme.of(context).textTheme.titleMedium,
                            )
                          : const Brand(),
                    ),
                    if (widget.store.stats.streak > 0) ...[
                      const SizedBox(width: 8),
                      Semantics(
                        label: '${widget.store.stats.streak}-day streak',
                        child: ExcludeSemantics(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: SbdColors.surfaceLow,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: SbdColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    size: 16, color: Color(0xFFFFB15C)),
                                const SizedBox(width: 5),
                                Text('${widget.store.stats.streak}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _about,
                      tooltip: 'About this preview',
                      icon: const Icon(
                        Icons.info_outline,
                        color: SbdColors.muted,
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: page),
            ],
          );
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: wide
                  ? Row(
                      children: [
                        Container(
                          width: 240,
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: SbdColors.border),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(22, 25, 12, 30),
                                child: Brand(),
                              ),
                              for (var i = 0; i < labels.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () => _select(i),
                                      icon: Icon(icons[i], size: 23),
                                      label: Text(labels[i]),
                                      style: TextButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        minimumSize: const Size(0, 52),
                                        foregroundColor: i == _tab
                                            ? SbdColors.cyan
                                            : SbdColors.muted,
                                        backgroundColor: i == _tab
                                            ? SbdColors.cyan
                                                .withValues(alpha: 0.08)
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.all(24),
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
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
            bottomNavigationBar: wide
                ? null
                : SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: DecoratedBox(
                      decoration: softSurface(radius: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeBottom: true,
                          child: NavigationBar(
                            selectedIndex: _tab,
                            onDestinationSelected: _select,
                            destinations: List.generate(
                              labels.length,
                              (i) => NavigationDestination(
                                icon: Icon(icons[i]),
                                label: labels[i],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      );
}

