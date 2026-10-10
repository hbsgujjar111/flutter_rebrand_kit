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

  /// Generates launcher icons for every platform folder present in the
  /// project and returns the names of the platforms that were updated.
  ///
  /// Platforms whose root folder (`android/`, `ios/`, `macos/`, `web/`,
  /// `windows/`, `linux/`) does not exist are skipped, so no stray folders are
  /// created.
  static List<String> generateLauncherIcons({
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

    final generated = <String>[];

    if (Directory('android').existsSync()) {
      AndroidIconGenerator.generate(
        baseImage: baseImage,
        bgRgb: bgRgb,
        bgColorHex: bgColorHex,
        bgImage: bgImage,
        customMonochrome: customMonochrome,
      );
      generated.add('Android');
    }

    if (Directory('ios').existsSync()) {
      IosIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
      generated.add('iOS');
    }

    if (Directory('macos').existsSync()) {
      MacOsIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
      generated.add('macOS');
    }

    if (Directory('web').existsSync()) {
      WebIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
      generated.add('Web');
    }

    if (Directory('windows').existsSync()) {
      WindowsIconGenerator.generate(baseImage: baseImage);
      generated.add('Windows');
    }

    if (Directory('linux').existsSync()) {
      LinuxIconGenerator.generate(
        baseImage: baseImage,
        bgImage: bgImage,
        bgRgb: bgRgb,
      );
      generated.add('Linux');
    }

    return generated;
  }

  /// Generates Android status bar notification silhouettes with custom naming.
  ///
  /// Returns false when the project has no `android/` folder.
  static bool generateNotificationIcons(
    String iconPath, {
    String iconName = 'ic_notification',
  }) {
    return NotificationIconGenerator.generate(
      iconPath: iconPath,
      iconName: iconName,
    );
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
