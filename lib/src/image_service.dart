import 'dart:io';

import 'package:image/image.dart' as img;

import 'logger.dart';

class ImageService {
  static img.Image loadAndValidateIcon(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File not found at: $path');
    }

    final image = img.decodeImage(file.readAsBytesSync());
    if (image == null) {
      throw Exception('Unable to decode image at: $path');
    }

    if (image.width != 1024 || image.height != 1024) {
      Logger.warn(
        'Image ($path) is ${image.width}x${image.height}. '
        'For sharp downscaling and store compliance, use a 1024x1024 source PNG.',
      );
    }
    return image;
  }

  /// Generates Android Legacy + Adaptive Icons and ALL 20 standard iOS icons.
  static void generateLauncherIcons(String iconPath, String bgColorHex) {
    final baseImage = loadAndValidateIcon(iconPath);
    final bgRgb = _parseHexColor(bgColorHex);

    // 1. Android Legacy Mipmaps (Composited over background color to prevent black borders)
    final androidDensities = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in androidDensities.entries) {
      final canvas = img.Image(width: entry.value, height: entry.value);
      img.fill(canvas, color: bgRgb);

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
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File(
        '${dir.path}/ic_launcher.png',
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    // 2. Android Adaptive Icons (Foreground in safe zone, Background color in XML)
    final foregroundDensities = {
      'mipmap-mdpi': 108,
      'mipmap-hdpi': 162,
      'mipmap-xhdpi': 216,
      'mipmap-xxhdpi': 324,
      'mipmap-xxxhdpi': 432,
    };

    for (final entry in foregroundDensities.entries) {
      final canvas = img.Image(
        width: entry.value,
        height: entry.value,
        numChannels: 4,
      );
      final safeSize = (entry.value * 0.60).round();
      final scaledLogo = img.copyResize(
        baseImage,
        width: safeSize,
        height: safeSize,
        interpolation: img.Interpolation.average,
      );

      img.compositeImage(
        canvas,
        scaledLogo,
        dstX: ((entry.value - safeSize) / 2).round(),
        dstY: ((entry.value - safeSize) / 2).round(),
      );

      final dir = Directory('android/app/src/main/res/${entry.key}');
      File(
        '${dir.path}/ic_launcher_foreground.png',
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    // Write background color in colors.xml
    final valuesDir = Directory('android/app/src/main/res/values');
    if (!valuesDir.existsSync()) valuesDir.createSync(recursive: true);

    final colorsFile = File('${valuesDir.path}/colors.xml');
    var colorsContent = colorsFile.existsSync()
        ? colorsFile.readAsStringSync()
        : '<resources></resources>';
    if (!colorsContent.contains('ic_launcher_background')) {
      colorsContent = colorsContent.replaceFirst(
        '</resources>',
        '    <color name="ic_launcher_background">$bgColorHex</color>\n</resources>',
      );
      colorsFile.writeAsStringSync(colorsContent);
    }

    final anyDpiDir = Directory('android/app/src/main/res/mipmap-anydpi-v26');
    if (!anyDpiDir.existsSync()) anyDpiDir.createSync(recursive: true);

    File('${anyDpiDir.path}/ic_launcher.xml').writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>''',
    );

    // 3. Complete 20-Asset iOS Catalog (Fixes flutter_launcher_icons bug #661)
    final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (!iosDir.existsSync()) iosDir.createSync(recursive: true);

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

    for (final entry in iosSizes.entries) {
      final canvas = img.Image(width: entry.value, height: entry.value);
      img.fill(canvas, color: bgRgb);

      final resized = img.copyResize(
        baseImage,
        width: entry.value,
        height: entry.value,
        interpolation: img.Interpolation.average,
      );

      img.compositeImage(canvas, resized);
      File(
        '${iosDir.path}/${entry.key}',
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    File('${iosDir.path}/Contents.json').writeAsStringSync('''{
  "images": [
    { "size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@2x.png", "scale": "2x" },
    { "size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@3x.png", "scale": "3x" },
    { "size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@1x.png", "scale": "1x" },
    { "size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@3x.png", "scale": "3x" },
    { "size": "38x38", "idiom": "iphone", "filename": "Icon-App-38x38@2x.png", "scale": "2x" },
    { "size": "38x38", "idiom": "iphone", "filename": "Icon-App-38x38@3x.png", "scale": "3x" },
    { "size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@3x.png", "scale": "3x" },
    { "size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@2x.png", "scale": "2x" },
    { "size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@3x.png", "scale": "3x" },
    { "size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@1x.png", "scale": "1x" },
    { "size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@2x.png", "scale": "2x" },
    { "size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@1x.png", "scale": "1x" },
    { "size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@2x.png", "scale": "2x" },
    { "size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@1x.png", "scale": "1x" },
    { "size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@2x.png", "scale": "2x" },
    { "size": "68x68", "idiom": "ipad", "filename": "Icon-App-68x68@2x.png", "scale": "2x" },
    { "size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@1x.png", "scale": "1x" },
    { "size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@2x.png", "scale": "2x" },
    { "size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-App-83.5x83.5@2x.png", "scale": "2x" },
    { "size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-App-1024x1024@1x.png", "scale": "1x" }
  ],
  "info": { "version": 1, "author": "flutter_rebrand_kit" }
}''');
  }

  /// High-resolution, anti-aliased white silhouettes with Material safe-padding.
  static void generateNotificationIcons(String iconPath) {
    var image = loadAndValidateIcon(iconPath);

    if (image.numChannels < 4) {
      image = image.convert(numChannels: 4);
    }

    bool hasTransparency = false;
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        if (image.getPixel(x, y).a < 200) {
          hasTransparency = true;
          break;
        }
      }
      if (hasTransparency) break;
    }

    final densities = {
      'drawable-mdpi': 24,
      'drawable-hdpi': 36,
      'drawable-xhdpi': 48,
      'drawable-xxhdpi': 72,
      'drawable-xxxhdpi': 96,
    };

    for (final entry in densities.entries) {
      final canvasSize = entry.value;
      // Android standard: inner 80% safe-padding prevents edge stretching
      final innerSize = (canvasSize * 0.80).round();

      final scaled = img.copyResize(
        image,
        width: innerSize,
        height: innerSize,
        interpolation: img.Interpolation.average,
      );

      final iconCanvas = img.Image(
        width: canvasSize,
        height: canvasSize,
        numChannels: 4,
      );

      for (int y = 0; y < scaled.height; y++) {
        for (int x = 0; x < scaled.width; x++) {
          final p = scaled.getPixel(x, y);

          if (hasTransparency) {
            if (p.a > 15) {
              scaled.setPixelRgba(x, y, 255, 255, 255, p.a);
            } else {
              scaled.setPixelRgba(x, y, 0, 0, 0, 0);
            }
          } else {
            final luminance = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
            final alpha = (255 - luminance).clamp(0, 255);
            if (alpha > 30) {
              scaled.setPixelRgba(x, y, 255, 255, 255, alpha);
            } else {
              scaled.setPixelRgba(x, y, 0, 0, 0, 0);
            }
          }
        }
      }

      img.compositeImage(
        iconCanvas,
        scaled,
        dstX: ((canvasSize - innerSize) / 2).round(),
        dstY: ((canvasSize - innerSize) / 2).round(),
      );

      final dir = Directory('android/app/src/main/res/${entry.key}');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File(
        '${dir.path}/ic_notification.png',
      ).writeAsBytesSync(img.encodePng(iconCanvas));
    }
  }

  /// Generates Play Store 512x512 icon (solid background) and 1024x500 banner.
  static void generatePlayStoreAssets({
    required String iconPath,
    required String bgColorHex,
    String? appName,
    String? tagline,
  }) {
    final source = loadAndValidateIcon(iconPath);
    final outputDir = Directory('branding_assets/play_store');
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

    final bgRgb = _parseHexColor(bgColorHex);

    // 1. Google Play Store 512x512 Icon
    final storeCanvas = img.Image(width: 512, height: 512);
    img.fill(storeCanvas, color: bgRgb);

    const logoTargetSize = 380;
    final storeLogo = img.copyResize(
      source,
      width: logoTargetSize,
      height: logoTargetSize,
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      storeCanvas,
      storeLogo,
      dstX: ((512 - logoTargetSize) / 2).round(),
      dstY: ((512 - logoTargetSize) / 2).round(),
    );
    File(
      '${outputDir.path}/play_store_512.png',
    ).writeAsBytesSync(img.encodePng(storeCanvas));

    // 2. Feature Graphic Banner (1024x500)
    final banner = img.Image(width: 1024, height: 500);
    img.fill(banner, color: bgRgb);

    const bannerLogoSize = 220;
    final bannerLogo = img.copyResize(
      source,
      width: bannerLogoSize,
      height: bannerLogoSize,
      interpolation: img.Interpolation.average,
    );
    final int logoX = (appName != null) ? 120 : (1024 - bannerLogoSize) ~/ 2;
    final int logoY = (500 - bannerLogoSize) ~/ 2;

    img.compositeImage(banner, bannerLogo, dstX: logoX, dstY: logoY);

    if (appName != null) {
      img.drawString(
        banner,
        appName,
        font: img.arial48,
        x: logoX + bannerLogoSize + 45,
        y: logoY + 60,
        color: img.ColorRgb8(255, 255, 255),
      );

      if (tagline != null && tagline.isNotEmpty) {
        img.drawString(
          banner,
          tagline,
          font: img.arial24,
          x: logoX + bannerLogoSize + 47,
          y: logoY + 125,
          color: img.ColorRgb8(200, 200, 200),
        );
      }
    }

    File(
      '${outputDir.path}/feature_graphic_1024x500.png',
    ).writeAsBytesSync(img.encodePng(banner));
  }

  static img.ColorRgb8 _parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final val = int.parse(clean, radix: 16);
    return img.ColorRgb8((val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF);
  }
}
