import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Opens the live map in-app where a web view is available, or in the
/// browser on Windows and Linux.
void openThreatMap(BuildContext context) {
  if (!ThreatMapScreen.canEmbed) {
    unawaited(openResource(context, ThreatMapScreen.url));
    return;
  }
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (_) => const ThreatMapScreen()));
}

/// Check Point's live cyber threat map, the same map as the website's
/// Threat Map page. It opens in-app on iOS, Android, and macOS (where a web
/// view is available) and in the browser elsewhere. Only Check Point's map
/// loads in the view; any other page it links to opens in the browser.
class ThreatMapScreen extends StatefulWidget {
  const ThreatMapScreen({super.key, this.embedded});

  /// Overrides whether the map opens in-app; tests pass false.
  final bool? embedded;

  static const url = 'https://threatmap.checkpoint.com/';
  static const host = 'threatmap.checkpoint.com';

  /// Whether this platform can show the map in-app.
  static bool get canEmbed =>
      !kIsWeb &&
      [TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS]
          .contains(defaultTargetPlatform);

  @override
  State<ThreatMapScreen> createState() => _ThreatMapScreenState();
}

class _ThreatMapScreenState extends State<ThreatMapScreen> {
  WebViewController? _controller;
  bool _error = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.embedded ?? ThreatMapScreen.canEmbed) {
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
          // The map's own frames may load; the view itself stays on the map.
          if (!request.isMainFrame) return NavigationDecision.navigate;
          if (uri?.scheme == 'https' && uri?.host == ThreatMapScreen.host) {
            return NavigationDecision.navigate;
          }
          if (mounted && uri?.scheme == 'https') {
            unawaited(openResource(context, request.url));
          }
          return NavigationDecision.prevent;
        }))
        ..loadRequest(Uri.parse(ThreatMapScreen.url));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Live Threat Map'), actions: [
        if (_controller != null)
          IconButton(
              tooltip: 'Reload the map',
              onPressed: () {
                setState(() {
                  _error = false;
                  _progress = 0;
                });
                _controller!.reload();
              },
              icon: const Icon(Icons.refresh)),
        IconButton(
            tooltip: 'Open on Check Point',
            onPressed: () => openResource(context, ThreatMapScreen.url),
            icon: const Icon(Icons.open_in_new)),
      ]),
      body: SafeArea(
          child: Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
                color: SbdColors.surface,
                border: Border(bottom: BorderSide(color: SbdColors.border))),
            child: const Text(
                'Live attacks detected by Check Point’s ThreatCloud network. '
                'The map is provided by Check Point Software Technologies; '
                'Secure By Design is not affiliated with Check Point.',
                style: TextStyle(
                    color: SbdColors.muted, fontSize: 12.5, height: 1.5))),
        if (_controller != null && !_error && _progress < 100)
          LinearProgressIndicator(value: _progress / 100),
        Expanded(
            child: _controller == null || _error
                ? _Fallback(error: _error)
                : WebViewWidget(controller: _controller!)),
      ])));
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.error});
  final bool error;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.public, color: SbdColors.cyan, size: 40),
            const SizedBox(height: 16),
            Text(
                error
                    ? 'The live map could not load. Check your connection, or open it on Check Point’s website.'
                    : 'Open Check Point’s live threat map in your browser.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.6)),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: () => openResource(context, ThreatMapScreen.url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open the live map')),
          ])));
}
