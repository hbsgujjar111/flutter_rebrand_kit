import 'dart:io';

import 'package:flutter_rebrand_kit/src/config/config.dart';
import 'package:flutter_rebrand_kit/src/config/init_service.dart';
import 'package:flutter_rebrand_kit/src/image_service.dart';
import 'package:flutter_rebrand_kit/src/metadata_service.dart';
import 'package:flutter_rebrand_kit/src/splash/splash_service.dart';
import 'package:flutter_rebrand_kit/src/utils/logger.dart';
import 'package:flutter_rebrand_kit/src/utils/validators.dart';

void main(List<String> args) {
  // `dart run flutter_rebrand_kit:rebrand_kit init`
  // (`dart run flutter_rebrand_kit:init` works as well.)
  if (args.isNotEmpty && args[0].toLowerCase() == 'init') {
    InitService.createTemplate();
    return;
  }

  Logger.banner();
  final stopwatch = Stopwatch()..start();

  try {
    final config = RebrandConfig.load();
    const totalSteps = 7;

    // Validate everything that can be validated before any file is modified.
    if (config.packageId != null) Validators.packageId(config.packageId!);
    if (config.version != null) Validators.version(config.version!);

    // 1. App Name
    if (config.appName != null) {
      MetadataService.updateAppName(config.appName!);
      Logger.step(1, totalSteps, 'App Name', 'Updated to "${config.appName}"');
    } else {
      Logger.step(1, totalSteps, 'App Name', 'Skipped');
    }

    // 2. Package ID
    if (config.packageId != null) {
      MetadataService.updatePackageId(config.packageId!);
      Logger.step(
        2,
        totalSteps,
        'Package ID',
        'Updated & refactored source tree to "${config.packageId}"',
      );
    } else {
      Logger.step(2, totalSteps, 'Package ID', 'Skipped');
    }

    // 3. Version
    if (config.version != null) {
      MetadataService.updateVersion(config.version!);
      Logger.step(3, totalSteps, 'Version', 'Updated to "${config.version}"');
    } else {
      Logger.step(3, totalSteps, 'Version', 'Skipped');
    }

    // 4. Launcher Icons
    if (config.launcherIcon != null) {
      final platforms = ImageService.generateLauncherIcons(
        iconPath: config.launcherIcon!,
        bgColorHex: config.launcherIconBgColor,
        bgImagePath: config.launcherIconBgImage,
        monochromeIconPath: config.launcherIconMonochrome,
      );
      if (platforms.isEmpty) {
        Logger.warn('No platform folders found; no launcher icons generated.');
        Logger.step(4, totalSteps, 'Launcher Icons', 'Skipped (no platforms)');
      } else {
        Logger.step(
          4,
          totalSteps,
          'Launcher Icons',
          'Generated for ${platforms.join(', ')}',
        );
      }
    } else {
      Logger.step(4, totalSteps, 'Launcher Icons', 'Skipped');
    }

    // 5. Notification Icons
    if (config.notificationIcon != null) {
      final generated = ImageService.generateNotificationIcons(
        config.notificationIcon!,
        iconName: config.notificationIconName,
      );
      Logger.step(
        5,
        totalSteps,
        'Notification Icons',
        generated
            ? 'Generated "${config.notificationIconName}.png"'
            : 'Skipped (no android/ folder)',
      );
    } else {
      Logger.step(5, totalSteps, 'Notification Icons', 'Skipped');
    }

    // 6. Native Splash
    if (config.splashImage != null) {
      final platforms = SplashService.generateNativeSplash(
        config.splashImage!,
        config.splashColor,
      );
      Logger.step(
        6,
        totalSteps,
        'Native Splash',
        platforms.isEmpty
            ? 'Skipped (no platforms)'
            : 'Generated for ${platforms.join(', ')} (${config.splashColor})',
      );
    } else {
      Logger.step(6, totalSteps, 'Native Splash', 'Skipped');
    }

    // 7. Play Store Assets
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
        'Saved 512x512 icon & 1024x500 banner',
      );
    } else if (config.generatePlayStoreAssets) {
      Logger.step(
        7,
        totalSteps,
        'Play Store Assets',
        'Skipped (requires "launcher_icon")',
      );
    } else {
      Logger.step(7, totalSteps, 'Play Store Assets', 'Skipped');
    }

    stopwatch.stop();
    final elapsed = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);
    Logger.success('All tasks finished in ${elapsed}s!');
  } catch (e) {
    Logger.error(e.toString());
    // A non-zero exit code lets scripts and CI notice the failure.
    exit(1);
  }
}
