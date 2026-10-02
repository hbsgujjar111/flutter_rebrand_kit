import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Generator for Linux desktop launcher icons.
class LinuxIconGenerator {
  LinuxIconGenerator._();

  /// Exports standard 256x256 desktop icon with background fill.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    final linuxTargetDir = Directory('linux/runner/assets');
    final fallbackDir = Directory('linux/assets');

    final dir = linuxTargetDir.existsSync()
        ? linuxTargetDir
        : (fallbackDir.existsSync() ? fallbackDir : linuxTargetDir);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    const size = 256;
    final canvas = img.Image(width: size, height: size);

    if (bgImage != null) {
      final resizedBg = img.copyResize(bgImage, width: size, height: size);
      img.compositeImage(canvas, resizedBg);
    } else {
      img.fill(canvas, color: bgRgb);
    }

    final iconSize = (size * 0.80).round();
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

    File(
      p.join(dir.path, 'app_icon.png'),
    ).writeAsBytesSync(img.encodePng(canvas));
  }
}
