import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The Training Hub's tile artwork, drawn the way the website draws it
/// (app/videos/hub-art.tsx, 19 October 2026): line art in the site's colors,
/// one family per topic group, no hardware makes or models. The path data is
/// the website's own SVG, so the two stay the same picture.
///
/// Families: identity (the default), harden, logging, endpoint, ops,
/// authorize and reference. training-hub.css gives each its accent and glow;
/// [SbdColors.family] holds those colors.

/// The art family of a course, as the website's catalog collections group them
/// (content/videos.json `collections`), with the website's fallback: the
/// category decides between authorize and identity.
String artFamilyFor(String courseId, String categoryId) =>
    switch (courseId) {
      'identity-foundation' => 'identity',
      'logging-pipeline' || 'audit-repository' || 'splunk-analysis' => 'logging',
      'linux-repository' ||
      'workstation-fleet' ||
      'patch-protect' ||
      'endpoint-protection' =>
        'endpoint',
      'management-server' ||
      'vulnerability-scanning' ||
      'business-services' ||
      'prove-recovery' =>
        'ops',
      _ => categoryId == 'network-authorization' ? 'authorize' : 'identity',
    };

/// The topic the website prints in a tile's chip (content/videos.json
/// `topic`); the course's category when the catalog has no topic for it.
String topicFor(String courseId, String fallback) => switch (courseId) {
      'identity-foundation' => 'Identity',
      'linux-repository' => 'Linux',
      'logging-pipeline' || 'audit-repository' => 'Logging',
      'splunk-analysis' => 'Splunk',
      'workstation-fleet' => 'Endpoints',
      'patch-protect' => 'Patching',
      'management-server' => 'Inventory',
      'endpoint-protection' => 'Endpoint protection',
      'vulnerability-scanning' => 'Scanning',
      'business-services' => 'Services',
      'prove-recovery' => 'Recovery',
      'rmf-boe-ato' => 'RMF',
      _ => fallback,
    };

sealed class _Shape {
  const _Shape({this.opacity = 1});
  final double opacity;
}

class _P extends _Shape {
  const _P(this.d, {super.opacity, this.dash});
  final String d;
  final List<double>? dash;
}

class _R extends _Shape {
  const _R(this.x, this.y, this.w, this.h, this.rx);
  final double x, y, w, h, rx;
}

class _E extends _Shape {
  const _E(this.cx, this.cy, this.rx, this.ry);
  final double cx, cy, rx, ry;
}

class _Dot extends _Shape {
  const _Dot(this.cx, this.cy, this.r, {this.filled = false});
  final double cx, cy, r;
  final bool filled;
}

/// The website's SVG (viewBox 0 0 320 200), family by family.
const _art = <String, List<_Shape>>{
  'harden': [
    _P('M160 22l38 14v28c0 26-17 40-38 48c-21-8-38-22-38-48V36z'),
    _P('M144 66l11 11l22-24'),
    _P('M88 46h20M88 58h12M212 46h20M220 58h12', opacity: 0.7),
  ],
  'logging': [
    _P('M70 44h86M70 68h86M70 92h86', dash: [2, 7]),
    _P('M156 44c20 0 20 24 38 24M156 92c20 0 20-24 38-24M156 68h38'),
    _E(226, 46, 26, 8),
    _P('M200 46v46c0 4 12 8 26 8s26-4 26-8V46M200 69c0 4 12 8 26 8s26-4 26-8'),
  ],
  'endpoint': [
    _R(92, 26, 36, 24, 3),
    _R(138, 26, 36, 24, 3),
    _R(184, 26, 36, 24, 3),
    _R(92, 68, 36, 24, 3),
    _R(138, 68, 36, 24, 3),
    _R(184, 68, 36, 24, 3),
    _P('M104 56h12M150 56h12M196 56h12M104 98h12M150 98h12M196 98h12'),
    _P('M246 26v52M236 68l10 10l10-10'),
  ],
  'ops': [
    _E(160, 44, 22, 7),
    _P('M138 44v38c0 4 10 7 22 7s22-3 22-7V44M138 63c0 4 10 7 22 7s22-3 22-7'),
    _P('M112 64a48 48 0 0 1 80-36'),
    _P('M186 20l7 8l-10 3'),
    _P('M208 64a48 48 0 0 1-80 36'),
    _P('M134 108l-7-8l10-3'),
  ],
  'authorize': [
    _P('M116 20h52l16 16v76h-68z'),
    _P('M168 20v16h16'),
    _P('M128 48h40M128 60h40M128 72h28'),
    _Dot(200, 92, 22),
    _P('M190 92l7 7l13-14'),
  ],
  'reference': [
    _R(132, 18, 64, 84, 5),
    _P('M124 26v84h64', opacity: 0.7),
    _P('M116 34v84h64', opacity: 0.45),
    _P('M144 38h40M144 50h40M144 62h28M144 74h36'),
  ],
  'identity': [
    _R(104, 30, 40, 70, 6),
    _R(176, 30, 40, 70, 6),
    _P('M114 46h20M114 56h20M114 66h20M186 46h20M186 56h20M186 66h20'),
    _P('M144 66h32', dash: [3, 5]),
    _P('M124 100v12h72v-12M160 112v10'),
    _Dot(124, 86, 3, filled: true),
    _Dot(196, 86, 3, filled: true),
    _Dot(160, 126, 4, filled: true),
  ],
};

/// Reads SVG path data (M L H V C S A Z, absolute or relative) into a [Path].
Path svgPath(String data) {
  final tokens = RegExp(r'[MmLlHhVvCcSsAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
      .allMatches(data)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var index = 0;
  var command = '';
  double x = 0, y = 0, startX = 0, startY = 0, cx = 0, cy = 0;
  var lastCubic = false;
  double number() => double.parse(tokens[index++]);
  bool numberNext() =>
      index < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[index]);
  while (index < tokens.length) {
    final token = tokens[index];
    if (RegExp(r'^[A-Za-z]$').hasMatch(token)) {
      command = token;
      index++;
    } else if (command == 'M') {
      command = 'L';
    } else if (command == 'm') {
      command = 'l';
    }
    final relative = command.toLowerCase() == command;
    switch (command.toUpperCase()) {
      case 'M':
        x = (relative ? x : 0) + number();
        y = (relative ? y : 0) + number();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        lastCubic = false;
      case 'L':
        x = (relative ? x : 0) + number();
        y = (relative ? y : 0) + number();
        path.lineTo(x, y);
        lastCubic = false;
      case 'H':
        x = (relative ? x : 0) + number();
        path.lineTo(x, y);
        lastCubic = false;
      case 'V':
        y = (relative ? y : 0) + number();
        path.lineTo(x, y);
        lastCubic = false;
      case 'C':
        final x1 = (relative ? x : 0) + number(), y1 = (relative ? y : 0) + number();
        final x2 = (relative ? x : 0) + number(), y2 = (relative ? y : 0) + number();
        final nx = (relative ? x : 0) + number(), ny = (relative ? y : 0) + number();
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        lastCubic = true;
      case 'S':
        final x1 = lastCubic ? 2 * x - cx : x, y1 = lastCubic ? 2 * y - cy : y;
        final x2 = (relative ? x : 0) + number(), y2 = (relative ? y : 0) + number();
        final nx = (relative ? x : 0) + number(), ny = (relative ? y : 0) + number();
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        lastCubic = true;
      case 'A':
        final rx = number(), ry = number(), rotation = number();
        final largeArc = number() != 0, sweep = number() != 0;
        final nx = (relative ? x : 0) + number(), ny = (relative ? y : 0) + number();
        path.arcToPoint(Offset(nx, ny),
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep);
        x = nx;
        y = ny;
        lastCubic = false;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCubic = false;
      default:
        // Unknown data: skip the token so the loop always advances.
        if (!numberNext()) index++;
        return path;
    }
    if (command.toUpperCase() == 'Z' && numberNext()) {
      // Numbers after Z continue as a line in SVG; the site's art never does.
      command = relative ? 'l' : 'L';
    }
  }
  return path;
}

/// [path] drawn with the dash pattern [pattern] (on, off, on, off…).
Path dashPath(Path path, List<double> pattern) {
  final dashed = Path();
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    var draw = true;
    var i = 0;
    while (distance < metric.length) {
      final length = pattern[i % pattern.length];
      final end = math.min(distance + length, metric.length);
      if (draw) dashed.addPath(metric.extractPath(distance, end), Offset.zero);
      distance = end;
      draw = !draw;
      i++;
    }
  }
  return dashed;
}

/// The line art of one family, in [color], scaled to fit the box the way an
/// SVG with a 320×200 viewBox fits.
class TileArtPainter extends CustomPainter {
  const TileArtPainter(this.family, this.color);
  final String family;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shapes = _art[family] ?? _art['identity']!;
    final scale = math.min(size.width / 320, size.height / 200);
    canvas.save();
    canvas.translate((size.width - 320 * scale) / 2, (size.height - 200 * scale) / 2);
    canvas.scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..style = PaintingStyle.fill;
    for (final shape in shapes) {
      stroke.color = color.withValues(alpha: shape.opacity);
      fill.color = stroke.color;
      switch (shape) {
        case _P(:final d, :final dash):
          final path = svgPath(d);
          canvas.drawPath(dash == null ? path : dashPath(path, dash), stroke);
        case _R(:final x, :final y, :final w, :final h, :final rx):
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rx)),
              stroke);
        case _E(:final cx, :final cy, :final rx, :final ry):
          canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), stroke);
        case _Dot(:final cx, :final cy, :final r, :final filled):
          canvas.drawCircle(Offset(cx, cy), r, filled ? fill : stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TileArtPainter old) => old.family != family || old.color != color;
}

/// A tile's ground (.th-thumb): the site's blue gradient, a faint 22px grid
/// and the family's glow behind the art.
class ThumbPainter extends CustomPainter {
  const ThumbPainter(this.accent, {this.glowAlpha = 0.3, this.cell = 22});
  final Color accent;
  final double glowAlpha;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = SbdColors.thumb.createShader(rect));
    final glow = Paint()
      ..shader = ui.Gradient.radial(
          Offset(size.width * 0.58, size.height * 0.36),
          math.max(size.width, size.height) * 0.62,
          [accent.withValues(alpha: glowAlpha), accent.withValues(alpha: 0)]);
    canvas.drawRect(rect, glow);
    final line = Paint()
      ..color = SbdColors.cyan.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(ThumbPainter old) =>
      old.accent != accent || old.glowAlpha != glowAlpha || old.cell != cell;
}

/// The art on its ground, as one box: the tile's thumbnail or the featured
/// course's preview.
class TileArt extends StatelessWidget {
  const TileArt({super.key, required this.family, this.glowAlpha = 0.3, this.cell = 22});
  final String family;
  final double glowAlpha;
  final double cell;
  @override
  Widget build(BuildContext context) {
    final accent = SbdColors.family(family);
    return CustomPaint(
      painter: ThumbPainter(accent, glowAlpha: glowAlpha, cell: cell),
      foregroundPainter: TileArtPainter(family, accent),
      child: const SizedBox.expand(),
    );
  }
}
