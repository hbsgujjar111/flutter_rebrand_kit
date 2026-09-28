import 'package:flutter_rebrand_kit/src/config.dart';
import 'package:flutter_rebrand_kit/src/image_service.dart';
import 'package:flutter_rebrand_kit/src/logger.dart';
import 'package:flutter_rebrand_kit/src/metadata_service.dart';
import 'package:flutter_rebrand_kit/src/splash_service.dart';

void main() {
  Logger.banner();
  final stopwatch = Stopwatch()..start();

  try {
    final config = RebrandConfig.load();
    const totalSteps = 7;

    // 1. App Name
    if (config.appName != null) {
      MetadataService.updateAppName(config.appName!);
      Logger.step(1, totalSteps, 'App Name', 'Updated to "${config.appName}"');
    } else {
      Logger.step(1, totalSteps, 'App Name', 'Skipped');
    }

    // 2. Package ID & Directory Restructuring
    if (config.packageId != null) {
      MetadataService.updatePackageId(config.packageId!);
      Logger.step(
        2,
        totalSteps,
        'Package ID',
        'Updated & refactored MainActivity tree to "${config.packageId}"',
      );
    } else {
      Logger.step(2, totalSteps, 'Package ID', 'Skipped');
    }

    // 3. Version Bump
    if (config.version != null) {
      MetadataService.updateVersion(config.version!);
      Logger.step(3, totalSteps, 'Version', 'Bumped to "${config.version}"');
    } else {
      Logger.step(3, totalSteps, 'Version', 'Skipped');
    }

    // 4. Launcher Icons (Legacy + API 26 Adaptive + API 33 Monochrome + iOS)
    if (config.launcherIcon != null) {
      ImageService.generateLauncherIcons(
        iconPath: config.launcherIcon!,
        bgColorHex: config.launcherIconBgColor,
        bgImagePath: config.launcherIconBgImage,
        monochromeIconPath: config.launcherIconMonochrome,
      );
      Logger.step(
        4,
        totalSteps,
        'Launcher Icons',
        'Generated Android Adaptive/Themed & iOS universal icons',
      );
    } else {
      Logger.step(4, totalSteps, 'Launcher Icons', 'Skipped');
    }

    if (config.notificationIcon != null) {
      ImageService.generateNotificationIcons(
        config.notificationIcon!,
        iconName: config.notificationIconName,
      );
      Logger.step(
        5,
        totalSteps,
        'Notification Icons',
        'Generated "${config.notificationIconName}.png" across all densities',
      );
    } else {
      Logger.step(5, totalSteps, 'Notification Icons', 'Skipped');
    }

    // 6. Native Splash (Android 12+ / Pre-12 / iOS Storyboard Asset)
    if (config.splashImage != null) {
      SplashService.generateNativeSplash(
        config.splashImage!,
        config.splashColor,
      );
      Logger.step(
        6,
        totalSteps,
        'Native Splash',
        'Wired Android 12 API, launch_background, and iOS LaunchImage',
      );
    } else {
      Logger.step(6, totalSteps, 'Native Splash', 'Skipped');
    }

    // 7. Store Marketing Assets
    if (config.generatePlayStoreAssets && config.launcherIcon != null) {
      ImageService.generatePlayStoreAssets(
        iconPath: config.launcherIcon!,
        bgColorHex: config.playStoreBannerBgColor,
        appName: config.appName,
        tagline: config.playStoreTagline,
      );
      Logger.step(
        7,
        totalSteps,
        'Play Store Assets',
        'Saved 512x512 icon & 1024x500 banner to branding_assets/',
      );
    } else {
      Logger.step(7, totalSteps, 'Play Store Assets', 'Skipped');
    }

    stopwatch.stop();
    final elapsed = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);
    Logger.success(
      'All tasks finished in ${elapsed}s! App is fully rebranded.',
    );
  } catch (e) {
    Logger.error(e.toString());
  }
}
