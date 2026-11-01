import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/learning_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_footer.dart';

/// The app's Home, the way the website's homepage is (owner direction,
/// 31 October 2026, and 1 November 2026 for the app): the hero over the blue
/// wave, the Cyber Range's one-round taster, then the footer. The support
/// panel is not in the app yet (owner's choice, 1 November 2026).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final LearningStore store;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _taster = GlobalKey();
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _scroll.removeListener(_check);
    _scroll.dispose();
    super.dispose();
  }

  /// The round's clock starts when the arena comes into view, as on the
  /// website: the taster loads once its top is inside the screen.
  void _check() {
    if (_armed || !mounted) return;
    final box = _taster.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height - 120) setState(() => _armed = true);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: _scroll,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HeroStage(children: [
            const HomeHero(),
            RangeTaster(key: _taster, load: _armed),
          ]),
          SiteFooter(analytics: widget.store.analytics),
        ]),
      );
}

/// One blue wave behind the hero and the taster (.sbd-hero-stage, .sbd-wave),
/// fading into the page below.
class HeroStage extends StatelessWidget {
  const HeroStage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: HeroWave(animate: !MediaQuery.disableAnimationsOf(context))),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ]);
}

/// The homepage's wave: blues drifting over the stage. The website renders
/// the purchased shader; the app draws its colors with the same motion, and
/// holds still when the device asks for reduced motion.
class HeroWave extends StatefulWidget {
  const HeroWave({super.key, this.animate = true});
  final bool animate;
  @override
  State<HeroWave> createState() => _HeroWaveState();
}

class _HeroWaveState extends State<HeroWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(HeroWave old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _WavePainter(_controller), child: const SizedBox.expand()),
      );
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = SbdColors.stage);
    final phase = t.value * 2 * math.pi;
    final w = size.width, h = math.min(size.height, 900.0);
    void blob(double cx, double cy, double r, Color color, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
    blob(w * (0.5 + 0.18 * math.sin(phase)), h * (0.42 + 0.06 * math.cos(phase * 0.7)), w * 0.62,
        const Color(0xFF0D4175), 0.75);
    blob(w * (0.22 + 0.12 * math.cos(phase * 0.8)), h * (0.62 + 0.08 * math.sin(phase * 0.6)), w * 0.42,
        const Color(0xFF1269B9), 0.42);
    blob(w * (0.78 + 0.1 * math.sin(phase * 1.1 + 1)), h * (0.3 + 0.07 * math.cos(phase)), w * 0.38,
        const Color(0xFF67CFF9), 0.22);
    blob(w * (0.6 + 0.2 * math.cos(phase * 0.5 + 2)), h * (0.86 + 0.05 * math.sin(phase * 0.9)), w * 0.5,
        const Color(0xFF378EFA), 0.18);
    // The wave fades into the page below, as the site masks it.
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.42, 0.72, 1],
            colors: [Color(0x00050B14), Color(0x00050B14), Color(0x99050B14), Color(0xFF050B14)],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

/// The hero (.sbd-hero): the website's heading, its line and its small print.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 700;
    final title = Theme.of(context).textTheme.headlineLarge!.copyWith(
          fontSize: narrow ? math.max(38.0, math.min(52.0, width * 0.1)) : 64,
          fontWeight: FontWeight.w700,
          letterSpacing: narrow ? -2.2 : -3.6,
          height: 1.05,
          color: Colors.white,
        );
    return Container(
      constraints: BoxConstraints(minHeight: narrow ? 420 : 520),
      padding: EdgeInsets.symmetric(horizontal: pageGutter(context), vertical: narrow ? 44 : 60),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            header: true,
            label: 'Cybersecurity starts with curiosity.',
            excludeSemantics: true,
            child: Column(children: [
              Text('Cybersecurity starts', textAlign: TextAlign.center, style: title),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('with ', style: title),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF378EFA), Color(0xFF7BE4F5)],
                  ).createShader(bounds),
                  child: Text('curiosity.', style: title),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 22),
          const Text(
            'Cybersecurity isn’t some exclusive club for geniuses. It really just takes a healthy dose of curiosity and a drive to figure out how things work under the hood.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD0DBEA), fontSize: 17, height: 1.7),
          ),
          const SizedBox(height: 20),
          const Text(
            'For the first question. The next challenge. And everything in between.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB6C4D6), fontSize: 12, height: 1.5),
          ),
        ]),
      ),
    );
  }
}

/// The Cyber Range's one-round taster: the website's own Range core in taster
/// mode (public/range-app/taster.html), sized to its page. Where a web view
/// can't run, the round is a tap away on the website.
class RangeTaster extends StatefulWidget {
  const RangeTaster({super.key, required this.load});
  final bool load;
  @override
  State<RangeTaster> createState() => _RangeTasterState();
}

class _RangeTasterState extends State<RangeTaster> {
  static final _url = Uri.parse('https://securebydesigninc.com/range-app/taster.html');
  WebViewController? _controller;
  bool _error = false, _tried = false, _ready = false;
  double _height = 560;

  @override
  void initState() {
    super.initState();
    if (widget.load) _start(notify: false);
  }

  @override
  void didUpdateWidget(RangeTaster old) {
    super.didUpdateWidget(old);
    if (widget.load && !_tried) _start();
  }

  void _start({bool notify = true}) {
    _tried = true;
    if (kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS]
            .contains(defaultTargetPlatform)) {
      return;
    }
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(SbdColors.stage)
        ..addJavaScriptChannel('SbdRange', onMessageReceived: (message) {
          final height = double.tryParse(message.message);
          if (height != null && height > 120 && mounted) {
            setState(() => _height = math.min(height, 2400.0));
          }
        })
        ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
          if (mounted) setState(() => _ready = true);
        }, onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) setState(() => _error = true);
        }, onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri?.scheme == 'https' &&
              uri?.host == 'securebydesigninc.com' &&
              uri!.path.startsWith('/range-app/')) {
            return NavigationDecision.navigate;
          }
          // A lesson link from a round opens on the website, in the browser.
          if (request.isMainFrame && mounted && uri?.scheme == 'https') {
            unawaited(openResource(context, request.url));
          }
          return NavigationDecision.prevent;
        }))
        ..loadRequest(_url);
      if (notify) {
        setState(() => _controller = controller);
      } else {
        _controller = controller;
      }
    } catch (_) {
      // No web view on this platform (or in a test): the round stays on the website.
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    if (_tried && (_controller == null || _error)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Kicker('Cyber Range'),
              const SizedBox(height: 10),
              Text('Try one round.', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                  _error
                      ? 'The round could not load. Check your connection, or play it on the website.'
                      : 'One question from the lab network, on the clock. Play it on the website.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => openResource(context, '$siteUrl/#try-the-range'),
                  child: const Text('Play a round on the website')),
            ])),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: _height,
          child: _controller == null
              ? Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
                  child: const Align(
                      alignment: Alignment.topLeft,
                      child: Text('Loading a round…',
                          style: TextStyle(color: Color(0xFFADC3D2), fontSize: 14))))
              : Stack(children: [
                  WebViewWidget(controller: _controller!),
                  if (!_ready)
                    Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
                        child: const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Loading a round…',
                                style: TextStyle(color: Color(0xFFADC3D2), fontSize: 14)))),
                ]),
        ),
      ),
    );
  }
}
