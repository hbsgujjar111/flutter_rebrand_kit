import 'dart:io';
import 'package:image/image.dart' as img;

/// Generator for Web favicons and standard PWA icon sets.
class WebIconGenerator {
  WebIconGenerator._();

  /// Generates `favicon.png` and solid/maskable PWA icons in `web/icons/`.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    // 1. Favicon (32x32)
    final favicon = img.copyResize(
      baseImage,
      width: 32,
      height: 32,
      interpolation: img.Interpolation.average,
    );
    File('web/favicon.png').writeAsBytesSync(img.encodePng(favicon));

    final iconsDir = Directory('web/icons');
    if (!iconsDir.existsSync()) {
      iconsDir.createSync(recursive: true);
    }

    // 2. Standard PWA Icons (192, 512)
    for (final size in [192, 512]) {
      final canvas = img.Image(width: size, height: size);
      if (bgImage != null) {
        final resizedBg = img.copyResize(bgImage, width: size, height: size);
        img.compositeImage(canvas, resizedBg);
      } else {
        img.fill(canvas, color: bgRgb);
      }

      final iconSize = (size * 0.75).round();
      final scaled = img.copyResize(
        baseImage,
        width: iconSize,
        height: iconSize,
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(
        canvas,
        scaled,
        dstX: ((size - iconSize) / 2).round(),
        dstY: ((size - iconSize) / 2).round(),
      );

      File('web/icons/Icon-$size.png').writeAsBytesSync(img.encodePng(canvas));
    }

    // 3. Maskable PWA Icons (Full bleed background required by Google PWA spec)
    for (final size in [192, 512]) {
      final canvas = img.Image(width: size, height: size);
      if (bgImage != null) {
        final resizedBg = img.copyResize(bgImage, width: size, height: size);
        img.compositeImage(canvas, resizedBg);
      } else {
        img.fill(canvas, color: bgRgb);
      }

      final safeSize = (size * 0.60).round();
      final scaled = img.copyResize(
        baseImage,
        width: safeSize,
        height: safeSize,
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(
        canvas,
        scaled,
        dstX: ((size - safeSize) / 2).round(),
        dstY: ((size - safeSize) / 2).round(),
      );

      File(
        'web/icons/Icon-maskable-$size.png',
      ).writeAsBytesSync(img.encodePng(canvas));
    }
  }
}
