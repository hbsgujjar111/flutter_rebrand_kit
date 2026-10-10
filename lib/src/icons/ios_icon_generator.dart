import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Generator for the iOS AppIcon catalog: the full iPhone/iPad icon set plus
/// the iOS 18 Dark and Tinted appearances.
class IosIconGenerator {
  IosIconGenerator._();

  /// Unique icon files of the standard catalog, keyed by `<points>@<scale>`.
  /// Values are pixel sizes.
  static const Map<String, int> _pixelSizes = {
    '20x20@1x': 20,
    '20x20@2x': 40,
    '20x20@3x': 60,
    '29x29@1x': 29,
    '29x29@2x': 58,
    '29x29@3x': 87,
    '40x40@1x': 40,
    '40x40@2x': 80,
    '40x40@3x': 120,
    '60x60@2x': 120,
    '60x60@3x': 180,
    '76x76@1x': 76,
    '76x76@2x': 152,
    '83.5x83.5@2x': 167,
    '1024x1024@1x': 1024,
  };

  static const String _darkFile = 'Icon-App-Dark-1024x1024@1x.png';
  static const String _tintedFile = 'Icon-App-Tinted-1024x1024@1x.png';

  /// Generates the light catalog, the 1024px Dark and Tinted icons, and
  /// `Contents.json`.
  static void generate({
    required img.Image baseImage,
    img.Image? bgImage,
    required img.ColorRgb8 bgRgb,
  }) {
    final iosDir = Directory(
      p.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset'),
    );
    if (!iosDir.existsSync()) {
      iosDir.createSync(recursive: true);
    }

    _removeStaleIcons(iosDir);

    // 1. Light icons. Opaque RGB canvases: the App Store rejects icons with
    // an alpha channel.
    img.Image? marketingIcon;
    for (final entry in _pixelSizes.entries) {
      final size = entry.value;
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

      File(
        p.join(iosDir.path, 'Icon-App-${entry.key}.png'),
      ).writeAsBytesSync(img.encodePng(canvas));

      if (size == 1024) marketingIcon = canvas;
    }

    // 2. iOS 18 Dark: the logo on a dark canvas (1024px, as Xcode expects).
    final darkCanvas = img.Image(width: 1024, height: 1024);
    img.fill(darkCanvas, color: img.ColorRgb8(26, 26, 26));
    img.compositeImage(
      darkCanvas,
      img.copyResize(
        baseImage,
        width: 1024,
        height: 1024,
        interpolation: img.Interpolation.average,
      ),
    );
    File(
      p.join(iosDir.path, _darkFile),
    ).writeAsBytesSync(img.encodePng(darkCanvas));

    // 3. iOS 18 Tinted: grayscale version of the light icon.
    final tintedCanvas = img.grayscale(img.Image.from(marketingIcon!));
    File(
      p.join(iosDir.path, _tintedFile),
    ).writeAsBytesSync(img.encodePng(tintedCanvas));

    File(
      p.join(iosDir.path, 'Contents.json'),
    ).writeAsStringSync(_buildContentsJson(), encoding: utf8);
  }

  /// Removes `Icon-App-*.png` files that are not part of the catalog written
  /// by this tool (default Flutter placeholders or leftovers of older runs).
  static void _removeStaleIcons(Directory dir) {
    final expected = <String>{
      for (final key in _pixelSizes.keys) 'Icon-App-$key.png',
      _darkFile,
      _tintedFile,
    };

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('Icon-App-') &&
          name.endsWith('.png') &&
          !expected.contains(name)) {
        try {
          entity.deleteSync();
        } catch (_) {}
      }
    }
  }

  static String _buildContentsJson() {
    Map<String, dynamic> slot(String idiom, String size, String scale) => {
      'size': size,
      'idiom': idiom,
      'filename': 'Icon-App-$size@$scale.png',
      'scale': scale,
    };

    final images = <Map<String, dynamic>>[
      slot('iphone', '20x20', '2x'),
      slot('iphone', '20x20', '3x'),
      slot('iphone', '29x29', '1x'),
      slot('iphone', '29x29', '2x'),
      slot('iphone', '29x29', '3x'),
      slot('iphone', '40x40', '2x'),
      slot('iphone', '40x40', '3x'),
      slot('iphone', '60x60', '2x'),
      slot('iphone', '60x60', '3x'),
      slot('ipad', '20x20', '1x'),
      slot('ipad', '20x20', '2x'),
      slot('ipad', '29x29', '1x'),
      slot('ipad', '29x29', '2x'),
      slot('ipad', '40x40', '1x'),
      slot('ipad', '40x40', '2x'),
      slot('ipad', '76x76', '1x'),
      slot('ipad', '76x76', '2x'),
      slot('ipad', '83.5x83.5', '2x'),
      slot('ios-marketing', '1024x1024', '1x'),
      {
        'appearances': [
          {'appearance': 'luminosity', 'value': 'dark'},
        ],
        'filename': _darkFile,
        'idiom': 'universal',
        'platform': 'ios',
        'size': '1024x1024',
      },
      {
        'appearances': [
          {'appearance': 'luminosity', 'value': 'tinted'},
        ],
        'filename': _tintedFile,
        'idiom': 'universal',
        'platform': 'ios',
        'size': '1024x1024',
      },
    ];

    return const JsonEncoder.withIndent('  ').convert({
      'images': images,
      'info': {'version': 1, 'author': 'flutter_rebrand_kit'},
    });
  }
}
