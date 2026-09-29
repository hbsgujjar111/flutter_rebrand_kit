import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Generator for iOS AppIcon catalog covering all 20 scale variants + iOS 18 Dark & Tinted icons.
class IosIconGenerator {
  IosIconGenerator._();

  /// Generates the full 20-asset iOS catalog (Light, Dark, and Tinted) and `Contents.json`.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (!iosDir.existsSync()) {
      iosDir.createSync(recursive: true);
    }

    final iosSizes = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-38x38@2x.png': 76,
      'Icon-App-38x38@3x.png': 114,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-64x64@2x.png': 128,
      'Icon-App-64x64@3x.png': 192,
      'Icon-App-68x68@2x.png': 136,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };

    final darkBgColor = img.ColorRgb8(
      26,
      26,
      26,
    ); // Clean #1A1A1A dark mode canvas

    for (final entry in iosSizes.entries) {
      final size = entry.value;

      // 1. Standard Light Icon
      final lightCanvas = img.Image(width: size, height: size);
      if (bgImage != null) {
        final resizedBg = img.copyResize(bgImage, width: size, height: size);
        img.compositeImage(lightCanvas, resizedBg);
      } else {
        img.fill(lightCanvas, color: bgRgb);
      }

      final resized = img.copyResize(
        baseImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(lightCanvas, resized);
      File(
        '${iosDir.path}/${entry.key}',
      ).writeAsBytesSync(img.encodePng(lightCanvas));

      // 2. iOS 18 Dark Mode Icon
      final darkCanvas = img.Image(width: size, height: size);
      img.fill(darkCanvas, color: darkBgColor);
      img.compositeImage(darkCanvas, resized);
      final darkFileName = entry.key.replaceFirst(
        'Icon-App-',
        'Icon-App-Dark-',
      );
      File(
        '${iosDir.path}/$darkFileName',
      ).writeAsBytesSync(img.encodePng(darkCanvas));

      // 3. iOS 18 Tinted Icon (Desaturated Grayscale)
      final tintedCanvas = img.grayscale(img.Image.from(lightCanvas));
      final tintedFileName = entry.key.replaceFirst(
        'Icon-App-',
        'Icon-App-Tinted-',
      );
      File(
        '${iosDir.path}/$tintedFileName',
      ).writeAsBytesSync(img.encodePng(tintedCanvas));
    }

    // Build complete Contents.json including iOS 18 appearances
    final contentsJson = _buildIosContentsJson(iosSizes.keys.toList());
    File(
      '${iosDir.path}/Contents.json',
    ).writeAsStringSync(contentsJson, encoding: utf8);
  }

  static String _buildIosContentsJson(List<String> fileNames) {
    final images = <Map<String, dynamic>>[];

    for (final fileName in fileNames) {
      final sizeStr = fileName.split('-')[2].split('@')[0];
      final scaleStr = fileName.split('@')[1].replaceAll('.png', '');

      // Light variant
      images.add({
        'size': sizeStr,
        'idiom': sizeStr == '1024x1024' ? 'ios-marketing' : 'universal',
        'platform': sizeStr == '1024x1024' ? null : 'ios',
        'filename': fileName,
        'scale': scaleStr,
      });

      // Dark variant (iOS 18)
      if (sizeStr != '1024x1024') {
        images.add({
          'size': sizeStr,
          'idiom': 'universal',
          'platform': 'ios',
          'filename': fileName.replaceFirst('Icon-App-', 'Icon-App-Dark-'),
          'scale': scaleStr,
          'appearances': [
            {'appearance': 'luminosity', 'value': 'dark'},
          ],
        });

        // Tinted variant (iOS 18)
        images.add({
          'size': sizeStr,
          'idiom': 'universal',
          'platform': 'ios',
          'filename': fileName.replaceFirst('Icon-App-', 'Icon-App-Tinted-'),
          'scale': scaleStr,
          'appearances': [
            {'appearance': 'luminosity', 'value': 'tinted'},
          ],
        });
      }
    }

    // Remove null keys
    for (final imgMap in images) {
      imgMap.removeWhere((key, value) => value == null);
    }

    final data = {
      'images': images,
      'info': {'version': 1, 'author': 'flutter_rebrand_kit'},
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
