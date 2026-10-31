import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// The Cyber Range tab (owner direction, 26 October 2026; the battle, 30
/// October 2026): the website's Range, opened in a WebView the way the System
/// Hub's 3D view is. One build serves the site and the app, so the battle is
/// identical: you against the computer, seven multiple-choice rounds. Inside
/// the app the Range plays as a guest, with a random operator and callsign
/// kept on this device; its sign-in link opens the website in the browser,
/// where a Community account keeps them. Handing the app's own session into
/// the Range is a later change.
const rangeUrl = 'https://securebydesigninc.com/range-app/?app=1';
const rangePageUrl = 'https://securebydesigninc.com/cyber-range';

class RangeScreen extends StatefulWidget {
  const RangeScreen({super.key});
  @override
  State<RangeScreen> createState() => _RangeScreenState();
}

class _RangeScreenState extends State<RangeScreen>
    with AutomaticKeepAliveClientMixin {
  static final _url = Uri.parse(rangeUrl);
  WebViewController? _controller;
  bool _error = false;
  int _progress = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS]
            .contains(defaultTargetPlatform)) {
      return;
    }
    // Widget tests and desktop builds have no WebView platform; they show the
    // open-in-browser card instead of failing.
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(SbdColors.background)
        ..setNavigationDelegate(NavigationDelegate(onProgress: (v) {
          if (mounted) setState(() => _progress = v);
        }, onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) {
            setState(() => _error = true);
          }
        }, onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri?.scheme == 'https' &&
              uri?.host == 'securebydesigninc.com' &&
              uri!.path.startsWith('/range-app/')) {
            return NavigationDecision.navigate;
          }
          // Sign-in, lessons and the site itself leave the arena: open them
          // in the browser rather than inside this frame.
          if (request.isMainFrame && mounted && uri?.scheme == 'https') {
            unawaited(openResource(context, request.url));
          }
          return NavigationDecision.prevent;
        }))
        ..loadRequest(_url);
    } catch (_) {
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cyber Range'), actions: [
        IconButton(
            tooltip: 'Reload the Range',
            onPressed: _controller == null
                ? null
                : () {
                    setState(() => _error = false);
                    _controller!.reload();
                  },
            icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(
        child: _controller == null || _error
            // Scrolls so the card fits narrow screens at large text sizes.
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child:
                        Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.sports_esports_outlined,
                          size: 40, color: SbdColors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        _error
                            ? 'The Cyber Range could not load. Check your connection, or open it in your browser.'
                            : 'The Cyber Range runs on the website: battle the computer in seven rounds of multiple choice from the lab network, open to everyone.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: () =>
                              openResource(context, rangePageUrl),
                          child: const Text('Open the Cyber Range')),
                    ]),
                  ),
                ),
              )
            : Column(children: [
                if (_progress < 100)
                  LinearProgressIndicator(value: _progress / 100),
                Expanded(child: WebViewWidget(controller: _controller!)),
              ]),
      ),
    );
  }
}
