import 'dart:io';

import 'package:image/image.dart' as img;

import '../utils/image_utils.dart';

/// Generator for Google Play Store marketing assets (512x512 icon & 1024x500 banner).
class PlayStoreGenerator {
  PlayStoreGenerator._();

  /// Generates the store icon and feature graphic banner in `branding_assets/play_store/`.
  static void generate({
    required String iconPath,
    required String bgColorHex,
    String? appName,
    String? tagline,
  }) {
    final source = ImageUtils.loadAndValidateIcon(iconPath);
    final outputDir = Directory('branding_assets/play_store');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final bgRgb = ImageUtils.parseHexColor(bgColorHex);

    // 1. 512x512 Play Store Icon
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

    // 2. 1024x500 Feature Graphic Banner
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
}
