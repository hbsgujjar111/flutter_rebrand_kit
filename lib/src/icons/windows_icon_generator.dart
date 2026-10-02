import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../utils/ico_encoder.dart';

/// Generator for multi-resolution Windows binary `.ico` application icons.
class WindowsIconGenerator {
  WindowsIconGenerator._();

  /// Encodes 16, 32, 48, and 256px resolutions into `windows/runner/resources/app_icon.ico`.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    final winResDir = Directory('windows/runner/resources');
    if (!winResDir.existsSync()) {
      winResDir.createSync(recursive: true);
    }

    final icoSizes = [16, 32, 48, 256];
    final pngFrames = <Uint8List>[];

    for (final size in icoSizes) {
      final canvas = img.Image(width: size, height: size);
      if (bgImage != null) {
        final resizedBg = img.copyResize(bgImage, width: size, height: size);
        img.compositeImage(canvas, resizedBg);
      } else {
        img.fill(canvas, color: bgRgb);
      }

      final resized = img.copyResize(
        baseImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      );

      img.compositeImage(canvas, resized);
      pngFrames.add(Uint8List.fromList(img.encodePng(canvas)));
    }

    final icoBytes = IcoEncoder.encode(pngFrames, icoSizes);
    File('${winResDir.path}/app_icon.ico').writeAsBytesSync(icoBytes);
  }
}
