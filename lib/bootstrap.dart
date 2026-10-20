import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/content_feed.dart';
import 'data/learning_store.dart';
import 'theme.dart';
import 'widgets/common.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<LearningStore> _store;
  final _feed = ContentFeed();
  @override
  void initState() {
    super.initState();
    _store = _open();
  }

  /// The catalog is settled before any progress loads, so every saved lesson
  /// is matched against the courses this session will show.
  Future<LearningStore> _open() async {
    await _feed.applyCached();
    final store = await LearningStore.load();
    // Training published on the website since this build: checked in the
    // background, verified, and used from the next launch.
    unawaited(_feed.refresh());
    return store;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LearningStore>(
        future: _store,
        builder: (context, snapshot) {
          if (snapshot.hasData) return SecureByDesignApp(store: snapshot.data!);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Brand(),
                          const SizedBox(height: 30),
                          if (!snapshot.hasError)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            const Text(
                              'Your learning space couldn’t open.',
                              style:
                                  TextStyle(fontSize: 23, color: SbdColors.ink),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'We couldn’t read the saved progress on this device. Try opening it again.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: SbdColors.muted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () =>
                                  setState(() => _store = _open()),
                              child: const Text('Try again'),
                            ),
                          ],
                        ],
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
