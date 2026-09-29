import 'dart:io';

import 'package:image/image.dart' as img;

import 'icons/android_icon_generator.dart';
import 'icons/ios_icon_generator.dart';
import 'icons/linux_icon_generator.dart';
import 'icons/macos_icon_generator.dart';
import 'icons/notification_icon_generator.dart';
import 'icons/web_icon_generator.dart';
import 'icons/windows_icon_generator.dart';
import 'marketing/play_store_generator.dart';
import 'utils/image_utils.dart';

/// Orchestrator service for generating icons, notification silhouettes, and marketing graphics.
class ImageService {
  ImageService._();

  /// Decodes and validates the master icon image at [path].
  static img.Image loadAndValidateIcon(String path) {
    return ImageUtils.loadAndValidateIcon(path);
  }

  /// Generates launcher icons across all platforms.
  static void generateLauncherIcons({
    required String iconPath,
    required String bgColorHex,
    String? bgImagePath,
    String? monochromeIconPath,
  }) {
    final baseImage = ImageUtils.loadAndValidateIcon(iconPath);
    final bgRgb = ImageUtils.parseHexColor(bgColorHex);

    img.Image? bgImage;
    if (bgImagePath != null) {
      bgImage = ImageUtils.loadAndValidateIcon(bgImagePath);
    }

    img.Image? customMonochrome;
    if (monochromeIconPath != null) {
      customMonochrome = ImageUtils.loadAndValidateIcon(monochromeIconPath);
    }

    // 1. Android
    AndroidIconGenerator.generate(
      baseImage: baseImage,
      bgRgb: bgRgb,
      bgColorHex: bgColorHex,
      bgImage: bgImage,
      customMonochrome: customMonochrome,
    );

    // 2. iOS
    IosIconGenerator.generate(
      baseImage: baseImage,
      bgImage: bgImage,
      bgRgb: bgRgb,
    );

    // 3. macOS
    if (Directory('macos').existsSync()) {
      MacOsIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
    }

    // 4. Web
    if (Directory('web').existsSync()) {
      WebIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
    }

    // 5. Windows
    if (Directory('windows').existsSync()) {
      WindowsIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
    }

    // 6. Linux
    if (Directory('linux').existsSync()) {
      LinuxIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
    }
  }

  /// Generates Android status bar notification silhouettes with custom naming.
  static void generateNotificationIcons(
    String iconPath, {
    String iconName = 'ic_notification',
  }) {
    NotificationIconGenerator.generate(iconPath: iconPath, iconName: iconName);
  }

  /// Generates Google Play Store 512x512 icon and 1024x500 banner.
  static void generatePlayStoreAssets({
    required String iconPath,
    required String bgColorHex,
    String? appName,
    String? tagline,
  }) {
    PlayStoreGenerator.generate(
      iconPath: iconPath,
      bgColorHex: bgColorHex,
      appName: appName,
      tagline: tagline,
    );
  }
}
