import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});
  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  late final Future<Map<String, dynamic>> _data;
  Timer? _timer;
  int _flow = 0, _step = 0;
  String _selected = 'dc1';
  bool _playing = false;
  @override
  void initState() {
    super.initState();
    _data = rootBundle
        .loadString('assets/training/network.json')
        .then((s) => Map<String, dynamic>.from(jsonDecode(s) as Map));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play(int steps) {
    _timer?.cancel();
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (mounted) setState(() => _step = (_step + 1) % steps);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Inside the Network'), actions: [
        IconButton(
            tooltip: 'Open the 3D explorer',
            icon: const Icon(Icons.view_in_ar_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const Network3dScreen())))
      ]),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('The network reference could not be loaded.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!,
                nodes = (data['nodes'] as List).cast<Map<String, dynamic>>(),
                flows =
                    (data['scenarios'] as List).cast<Map<String, dynamic>>();
            final flow = flows[_flow],
                steps = (flow['steps'] as List).cast<Map<String, dynamic>>(),
                step = steps[_step];
            final selected = nodes.firstWhere((n) => n['id'] == _selected,
                orElse: () => nodes.first);
            return PageContent(children: [
              const PageTitle('Follow the connections.',
                  'Explore the systems and services behind the training.',
                  kicker: 'Inside the Network'),
              FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const Network3dScreen())),
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Open the interactive 3D view')),
              const SizedBox(height: 12),
              const Text(
                  'The 3D view uses an internet connection. Systems and flow explanations below are available offline.',
                  style: TextStyle(color: SbdColors.muted, height: 1.6)),
              const SizedBox(height: 24),
              const Kicker('Traffic processes'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < flows.length; i++)
                  ChoiceChip(
                      label: Text(flows[i]['label'] as String),
                      selected: _flow == i,
                      onSelected: (_) {
                        _timer?.cancel();
                        setState(() {
                          _flow = i;
                          _step = 0;
                          _playing = false;
                        });
                      })
              ]),
              const SizedBox(height: 18),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(flow['title'] as String,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(flow['caption'] as String),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, children: [
                      IconButton(
                          tooltip: 'Previous step',
                          onPressed:
                              _step > 0 ? () => setState(() => _step--) : null,
                          icon: const Icon(Icons.skip_previous)),
                      IconButton(
                          tooltip: _playing ? 'Pause playback' : 'Play steps',
                          onPressed: () => _play(steps.length),
                          icon:
                              Icon(_playing ? Icons.pause : Icons.play_arrow)),
                      IconButton(
                          tooltip: 'Next step',
                          onPressed: _step < steps.length - 1
                              ? () => setState(() => _step++)
                              : null,
                          icon: const Icon(Icons.skip_next))
                    ]),
                    Text(
                        'Step ${_step + 1} of ${steps.length} · ${step['title']}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(step['protocol'] as String,
                        style: const TextStyle(color: SbdColors.cyan)),
                    const SizedBox(height: 12),
                    Text(step['description'] as String,
                        style: const TextStyle(height: 1.7)),
                    const SizedBox(height: 12),
                    Text(step['note'] as String,
                        style: const TextStyle(
                            color: SbdColors.muted, height: 1.6)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final id in [step['from'], step['to']])
                        if (nodes.any((n) => n['id'] == id))
                          OutlinedButton(
                              onPressed: () =>
                                  setState(() => _selected = id as String),
                              child: Text(
                                  nodes.firstWhere((n) => n['id'] == id)['name']
                                      as String))
                    ]),
                  ])),
              const SizedBox(height: 26),
              const Kicker('Inspect a system'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: _selected,
                  isExpanded: true,
                  items: nodes
                      .map((n) => DropdownMenuItem(
                          value: n['id'] as String,
                          child: Text(n['name'] as String,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selected = value);
                  },
                  key: ValueKey(_selected)),
              const SizedBox(height: 18),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(selected['name'] as String,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                        '${selected['role']}\n${selected['address'] ?? 'Offline · no network connection'}',
                        style: const TextStyle(
                            color: SbdColors.cyan, height: 1.7)),
                    const SizedBox(height: 14),
                    Text(selected['known'] as String,
                        style: const TextStyle(height: 1.7)),
                    const SizedBox(height: 20),
                    const Kicker('Design considerations'),
                    const SizedBox(height: 10),
                    for (final item in selected['design'] as List)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(item as String)),
                    const SizedBox(height: 12),
                    const Kicker('Verification & evidence'),
                    const SizedBox(height: 10),
                    for (final item in selected['evidence'] as List)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(item as String)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final control in selected['controls'] as List)
                        Chip(label: Text(control as String))
                    ])
                  ])),
            ]);
          }));
}

class Network3dScreen extends StatefulWidget {
  const Network3dScreen({super.key});
  @override
  State<Network3dScreen> createState() => _Network3dScreenState();
}

class _Network3dScreenState extends State<Network3dScreen> {
  static final _url = Uri.parse(
      'https://securebydesigninc.com/inside-network-model/model.html');
  WebViewController? _controller;
  bool _error = false;
  int _progress = 0;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        [TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS]
            .contains(defaultTargetPlatform)) {
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
              uri!.path.startsWith('/inside-network-model/')) {
            return NavigationDecision.navigate;
          }
          if (request.isMainFrame && mounted && uri?.scheme == 'https') {
            unawaited(openResource(context, request.url));
          }
          return NavigationDecision.prevent;
        }))
        ..loadRequest(_url);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Network · 3D view'), actions: [
        IconButton(
            tooltip: 'Reload 3D view',
            onPressed: _controller == null
                ? null
                : () {
                    setState(() => _error = false);
                    _controller!.reload();
                  },
            icon: const Icon(Icons.refresh))
      ]),
      body: SafeArea(
          child: _controller == null || _error
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error
                            ? 'The 3D view could not load. Check your connection or return to the offline system reference.'
                            : 'Open the full 3D explorer in your browser. The system reference remains available in the app.'),
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: () =>
                                openResource(context, _url.toString()),
                            child: const Text('Open 3D explorer'))
                      ])))
              : Column(children: [
                  if (_progress < 100)
                    LinearProgressIndicator(value: _progress / 100),
                  Expanded(child: WebViewWidget(controller: _controller!))
                ])));
}
