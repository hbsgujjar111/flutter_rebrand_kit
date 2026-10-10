import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/image_utils.dart';
import '../utils/logger.dart';

/// Generator for Google Play Store marketing assets (512x512 icon & 1024x500 banner).
class PlayStoreGenerator {
  PlayStoreGenerator._();

  /// The built-in bitmap fonts only contain basic ASCII glyphs.
  static bool _isRenderable(String? text) =>
      text == null || text.runes.every((r) => r >= 32 && r <= 126);

  /// Generates the store icon and feature graphic banner in `branding_assets/play_store/`.
  static void generate({
    required String iconPath,
    required String bgColorHex,
    String? appName,
    String? tagline,
  }) {
    final source = ImageUtils.loadAndValidateIcon(iconPath);
    final outputDir = Directory(p.join('branding_assets', 'play_store'));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final bgRgb = ImageUtils.parseHexColor(bgColorHex);

    var bannerName = appName;
    var bannerTagline = tagline;
    if (!_isRenderable(bannerName) || !_isRenderable(bannerTagline)) {
      Logger.warn(
        'The feature graphic text supports basic ASCII characters only. '
        'The banner was generated without the app name and tagline.',
      );
      bannerName = null;
      bannerTagline = null;
    }

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
      p.join(outputDir.path, 'play_store_512.png'),
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
    final int logoX = (bannerName != null) ? 120 : (1024 - bannerLogoSize) ~/ 2;
    final int logoY = (500 - bannerLogoSize) ~/ 2;

    img.compositeImage(banner, bannerLogo, dstX: logoX, dstY: logoY);

    if (bannerName != null) {
      img.drawString(
        banner,
        bannerName,
        font: bannerName.length <= 16 ? img.arial48 : img.arial24,
        x: logoX + bannerLogoSize + 45,
        y: logoY + 60,
        color: img.ColorRgb8(255, 255, 255),
      );

      if (bannerTagline != null && bannerTagline.isNotEmpty) {
        img.drawString(
          banner,
          bannerTagline,
          font: bannerTagline.length <= 36 ? img.arial24 : img.arial14,
          x: logoX + bannerLogoSize + 47,
          y: logoY + 125,
          color: img.ColorRgb8(200, 200, 200),
        );
      }
    }

    File(
      p.join(outputDir.path, 'feature_graphic_1024x500.png'),
    ).writeAsBytesSync(img.encodePng(banner));
  }
}
