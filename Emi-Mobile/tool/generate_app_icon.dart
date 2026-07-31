// Generates the EMI app-icon PNGs consumed by `flutter_launcher_icons`
// (see pubspec.yaml). Run with: dart run tool/generate_app_icon.dart
//
// Produces two files under assets/icon/:
// - emi_icon.png: 1024x1024 square icon (opaque background, no
//   transparency) for the standard Play Store / legacy launcher icon.
// - emi_icon_foreground.png: 1024x1024 transparent-background foreground
//   layer for the Android adaptive icon, using the same silhouette but
//   fitted to the adaptive icon's smaller "safe zone" so it doesn't get
//   clipped by the OS mask.
//
// Design: a simplified Mekongga traditional stilted house (rumah adat)
// silhouette on the EMI brand orange background, matching the app's
// primary color (EmiColors.primary = 0xFFFF8A3D) and ink outline
// (EmiColors.textPrimary = 0xFF1D1B17) used throughout lib/app/theme.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _orange = 0xFFFF8A3D; // EmiColors.primary
const _ink = 0xFF1D1B17; // EmiColors.textPrimary
const _cream = 0xFFFFF8EE; // roof/wall highlight, warm off-white
const _green = 0xFF2F6B58; // house body, matches teacher/culture accents

img.Color _c(int argb) => img.ColorRgba8(
  (argb >> 16) & 0xFF,
  (argb >> 8) & 0xFF,
  argb & 0xFF,
  (argb >> 24) & 0xFF,
);

/// Draws the house silhouette centered in a [size]x[size] canvas, scaled by
/// [scale] (1.0 = fills most of the canvas, <1.0 = shrinks toward center,
/// used for the adaptive-icon foreground so nothing is clipped by the mask).
void _drawHouse(img.Image image, {required double scale}) {
  final size = image.width.toDouble();
  final cx = size / 2;
  final cy = size / 2;

  img.Point p(double x, double y) {
    // Design coordinates are authored on a 0..100 grid centered at (50,52);
    // apply scale then recenter on the actual canvas.
    final dx = (x - 50) * scale;
    final dy = (y - 52) * scale;
    return img.Point(cx + dx / 100 * size, cy + dy / 100 * size);
  }

  int lenPx(double v) => (v * scale / 100 * size).round();

  // Ground band.
  img.fillRect(
    image,
    x1: 0,
    y1: p(0, 88).yi,
    x2: image.width,
    y2: image.height,
    color: _c(_green),
  );

  // Stilts (4 legs).
  for (final sx in [30.0, 40.0, 60.0, 70.0]) {
    final top = p(sx, 62);
    final bottom = p(sx, 88);
    img.fillRect(
      image,
      x1: top.xi - lenPx(2),
      y1: top.yi,
      x2: top.xi + lenPx(2),
      y2: bottom.yi,
      color: _c(_ink),
    );
  }

  // House body (walls).
  img.fillRect(
    image,
    x1: p(22, 40).xi,
    y1: p(22, 40).yi,
    x2: p(78, 62).xi,
    y2: p(78, 62).yi,
    color: _c(_cream),
  );
  img.drawRect(
    image,
    x1: p(22, 40).xi,
    y1: p(22, 40).yi,
    x2: p(78, 62).xi,
    y2: p(78, 62).yi,
    color: _c(_ink),
    thickness: math.max(1, lenPx(2.2)),
  );

  // Door.
  img.fillRect(
    image,
    x1: p(46, 48).xi,
    y1: p(46, 48).yi,
    x2: p(54, 62).xi,
    y2: p(54, 62).yi,
    color: _c(_ink),
  );

  // Windows.
  for (final wx in [28.0, 66.0]) {
    img.fillRect(
      image,
      x1: p(wx, 46).xi,
      y1: p(wx, 46).yi,
      x2: p(wx + 8, 54).xi,
      y2: p(wx + 8, 54).yi,
      color: _c(_orange),
    );
  }

  // Tiered roof (three stacked triangles tapering to a peak) — the
  // signature silhouette of a Mekongga stilted house's layered roofline.
  // Each tier alternates cream/ink so the layers stay readable even at
  // small icon sizes (48x48 launcher), with an ink outline stroked around
  // every tier so tiers never blend into the orange background.
  void roofTier(double baseY, double baseHalfWidth, double peakY, int fill) {
    final vertices = [
      p(50 - baseHalfWidth, baseY),
      p(50, peakY),
      p(50 + baseHalfWidth, baseY),
    ];
    img.fillPolygon(image, vertices: vertices, color: _c(fill));
    img.drawPolygon(
      image,
      vertices: vertices,
      color: _c(_ink),
      thickness: math.max(1, lenPx(1.8)),
    );
  }

  roofTier(40, 40, 18, _ink);
  roofTier(30, 30, 12, _cream);
  roofTier(22, 18, 6, _ink);

  // Roof finial ornament.
  img.fillCircle(
    image,
    x: p(50, 4).xi,
    y: p(50, 4).yi,
    radius: math.max(1, lenPx(3.5)),
    color: _c(_cream),
  );
  img.drawCircle(
    image,
    x: p(50, 4).xi,
    y: p(50, 4).yi,
    radius: math.max(1, lenPx(3.5)),
    color: _c(_ink),
  );
}

void main() {
  const size = 1024;

  // Main icon: opaque orange background, no transparency (Play Store
  // requirement for the primary icon asset).
  final main = img.Image(width: size, height: size, numChannels: 3);
  img.fill(main, color: _c(_orange));
  _drawHouse(main, scale: 1.0);

  // Adaptive icon foreground: transparent background, house silhouette
  // shrunk toward the center so Android's adaptive-icon mask (which can
  // crop up to ~33% of the edges depending on device shape) never clips
  // it.
  final foreground = img.Image(
    width: size,
    height: size,
    numChannels: 4,
  );
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0));
  _drawHouse(foreground, scale: 0.62);

  final dir = Directory('assets/icon');
  dir.createSync(recursive: true);

  File('${dir.path}/emi_icon.png').writeAsBytesSync(img.encodePng(main));
  File(
    '${dir.path}/emi_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  stdout.writeln('Generated assets/icon/emi_icon.png (${size}x$size, opaque)');
  stdout.writeln(
    'Generated assets/icon/emi_icon_foreground.png (${size}x$size, transparent)',
  );
}
