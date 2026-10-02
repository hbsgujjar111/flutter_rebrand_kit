import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../utils/image_utils.dart';

/// Generator for Android legacy mipmaps, adaptive icons, and Android 13+ monochrome icons.
class AndroidIconGenerator {
  AndroidIconGenerator._();

  /// Generates all Android icon layers and XML definitions.
  static void generate({
    required img.Image baseImage,
    required img.ColorRgb8 bgRgb,
    required String bgColorHex,
    img.Image? bgImage,
    img.Image? customMonochrome,
  }) {
    // 1. Legacy Mipmaps
    final androidDensities = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in androidDensities.entries) {
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

      final iconSize = (entry.value * 0.75).round();
      final resizedLogo = img.copyResize(
        baseImage,
        width: iconSize,
        height: iconSize,
        interpolation: img.Interpolation.average,
      );

      img.compositeImage(
        canvas,
        resizedLogo,
        dstX: ((entry.value - iconSize) / 2).round(),
        dstY: ((entry.value - iconSize) / 2).round(),
      );

      final dir = Directory('android/app/src/main/res/${entry.key}');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File(
        '${dir.path}/ic_launcher.png',
      ).writeAsBytesSync(img.encodePng(canvas));
      File(
        '${dir.path}/ic_launcher_round.png',
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    // 2. Adaptive and Themed Icons
    final adaptiveDensities = {
      'mipmap-mdpi': 108,
      'mipmap-hdpi': 162,
      'mipmap-xhdpi': 216,
      'mipmap-xxhdpi': 324,
      'mipmap-xxxhdpi': 432,
    };

    for (final entry in adaptiveDensities.entries) {
      final canvasSize = entry.value;
      final safeSize = (canvasSize * 0.60).round();
      final dir = Directory('android/app/src/main/res/${entry.key}');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final fgCanvas = img.Image(
        width: canvasSize,
        height: canvasSize,
        numChannels: 4,
      );
      final scaledLogo = img.copyResize(
        baseImage,
        width: safeSize,
        height: safeSize,
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(
        fgCanvas,
        scaledLogo,
        dstX: ((canvasSize - safeSize) / 2).round(),
        dstY: ((canvasSize - safeSize) / 2).round(),
      );
      File(
        '${dir.path}/ic_launcher_foreground.png',
      ).writeAsBytesSync(img.encodePng(fgCanvas));

      if (bgImage != null) {
        final resizedBg = img.copyResize(
          bgImage,
          width: canvasSize,
          height: canvasSize,
        );
        File(
          '${dir.path}/ic_launcher_background.png',
        ).writeAsBytesSync(img.encodePng(resizedBg));
      }

      final monoCanvas = img.Image(
        width: canvasSize,
        height: canvasSize,
        numChannels: 4,
      );
      final monoSource = customMonochrome != null
          ? img.copyResize(
              customMonochrome,
              width: safeSize,
              height: safeSize,
              interpolation: img.Interpolation.average,
            )
          : ImageUtils.createMonochromeSilhouette(scaledLogo);

      img.compositeImage(
        monoCanvas,
        monoSource,
        dstX: ((canvasSize - safeSize) / 2).round(),
        dstY: ((canvasSize - safeSize) / 2).round(),
      );
      File(
        '${dir.path}/ic_launcher_monochrome.png',
      ).writeAsBytesSync(img.encodePng(monoCanvas));
    }

    if (bgImage == null) {
      final valuesDir = Directory('android/app/src/main/res/values');
      if (!valuesDir.existsSync()) {
        valuesDir.createSync(recursive: true);
      }

      final colorsFile = File('${valuesDir.path}/colors.xml');
      var colorsContent = colorsFile.existsSync()
          ? colorsFile.readAsStringSync(encoding: utf8)
          : '<resources></resources>';
      if (!colorsContent.contains('ic_launcher_background')) {
        colorsContent = colorsContent.replaceFirst(
          '</resources>',
          '    <color name="ic_launcher_background">$bgColorHex</color>\n</resources>',
        );
        colorsFile.writeAsStringSync(colorsContent, encoding: utf8);
      }
    }

    final anyDpiDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
    if (!anyDpiDir.existsSync()) {
      anyDpiDir.createSync(recursive: true);
    }

    final bgDrawableRef = bgImage != null
        ? '@mipmap/ic_launcher_background'
        : '@color/ic_launcher_background';
    final adaptiveXmlContent =
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="$bgDrawableRef"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>''';

    File(
      '${anyDpiDir.path}/ic_launcher.xml',
    ).writeAsStringSync(adaptiveXmlContent, encoding: utf8);
    File(
      '${anyDpiDir.path}/ic_launcher_round.xml',
    ).writeAsStringSync(adaptiveXmlContent, encoding: utf8);
  }
}
