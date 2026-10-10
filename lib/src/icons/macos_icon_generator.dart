import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Generator for macOS desktop AppIcon catalog.
class MacOsIconGenerator {
  MacOsIconGenerator._();

  /// Generates the multi-resolution desktop icon catalog for macOS.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    final macDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
    if (!macDir.existsSync()) {
      macDir.createSync(recursive: true);
    }

    final macSizes = {
      'app_icon_16.png': 16,
      'app_icon_32.png': 32,
      'app_icon_64.png': 64,
      'app_icon_128.png': 128,
      'app_icon_256.png': 256,
      'app_icon_512.png': 512,
      'app_icon_1024.png': 1024,
    };

    for (final entry in macSizes.entries) {
      final canvas = img.Image(width: entry.value, height: entry.value);
      if (bgImage != null) {
        final resizedBg = img.copyResize(
          bgImage,
          width: entry.value,
          height: entry.value,
        );
        img.compositeImage(canvas, resizedBg);
      } else {
        img.fill(canvas, color: bgRgb);
      }

      final resized = img.copyResize(
        baseImage,
        width: entry.value,
        height: entry.value,
        interpolation: img.Interpolation.average,
      );

      img.compositeImage(canvas, resized);
      File(
        '${macDir.path}/${entry.key}',
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    File('${macDir.path}/Contents.json').writeAsStringSync('''{
  "images": [
    { "size": "16x16", "idiom": "mac", "filename": "app_icon_16.png", "scale": "1x" },
    { "size": "16x16", "idiom": "mac", "filename": "app_icon_32.png", "scale": "2x" },
    { "size": "32x32", "idiom": "mac", "filename": "app_icon_32.png", "scale": "1x" },
    { "size": "32x32", "idiom": "mac", "filename": "app_icon_64.png", "scale": "2x" },
    { "size": "128x128", "idiom": "mac", "filename": "app_icon_128.png", "scale": "1x" },
    { "size": "128x128", "idiom": "mac", "filename": "app_icon_256.png", "scale": "2x" },
    { "size": "256x256", "idiom": "mac", "filename": "app_icon_256.png", "scale": "1x" },
    { "size": "256x256", "idiom": "mac", "filename": "app_icon_512.png", "scale": "2x" },
    { "size": "512x512", "idiom": "mac", "filename": "app_icon_512.png", "scale": "1x" },
    { "size": "512x512", "idiom": "mac", "filename": "app_icon_1024.png", "scale": "2x" }
  ],
  "info": { "version": 1, "author": "flutter_rebrand_kit" }
}''', encoding: utf8);
  }
}
