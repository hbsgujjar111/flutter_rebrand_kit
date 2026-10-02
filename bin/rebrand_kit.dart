import 'dart:io';

import 'package:flutter_rebrand_kit/src/config/config.dart';
import 'package:flutter_rebrand_kit/src/config/init_service.dart';
import 'package:flutter_rebrand_kit/src/image_service.dart';
import 'package:flutter_rebrand_kit/src/metadata_service.dart';
import 'package:flutter_rebrand_kit/src/splash/splash_service.dart';
import 'package:flutter_rebrand_kit/src/utils/logger.dart';

Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args[0].toLowerCase() == 'init') {
    InitService.createTemplate();
    return;
  }

  Logger.banner();
  final stopwatch = Stopwatch()..start();

  try {
    final config = RebrandConfig.load();
    const totalSteps = 7;

    // 1. App Name
    if (config.appName != null) {
      Logger.step(
        1,
        totalSteps,
        'App Name',
        'Updating labels across platforms...',
      );
      MetadataService.updateAppName(config.appName!);
      Logger.subStep('Android: AndroidManifest.xml (android:label)');
      Logger.subStep('iOS: Info.plist (CFBundleDisplayName & CFBundleName)');
      Logger.subStep('macOS: AppInfo.xcconfig (PRODUCT_NAME)');
      Logger.subStep('Web: index.html (<title> & meta) and manifest.json');
      Logger.subStep('Windows & Linux: Runner.rc metadata & window titles');
    } else {
      Logger.step(1, totalSteps, 'App Name', 'Skipped');
    }

    // 2. Package ID
    if (config.packageId != null) {
      Logger.step(
        2,
        totalSteps,
        'Package ID',
        'Updating bundle IDs & refactoring source trees...',
      );
      MetadataService.updatePackageId(config.packageId!);
      Logger.subStep(
        'Android: build.gradle / .gradle.kts (applicationId & namespace)',
      );
      Logger.subStep(
        'Android: Full-tree Kotlin/Java directory migration & import rewrites',
      );
      Logger.subStep('iOS & macOS: project.pbxproj & AppInfo.xcconfig');
      Logger.subStep(
        'Linux & Windows: CMakeLists.txt (APPLICATION_ID & binary target)',
      );
    } else {
      Logger.step(2, totalSteps, 'Package ID', 'Skipped');
    }

    // 3. Version
    if (config.version != null) {
      Logger.step(
        3,
        totalSteps,
        'Version',
        'Updating pubspec.yaml to "${config.version}"',
      );
      MetadataService.updateVersion(config.version!);
    } else {
      Logger.step(3, totalSteps, 'Version', 'Skipped');
    }

    // 4. Launcher Icons
    if (config.launcherIcon != null) {
      Logger.step(
        4,
        totalSteps,
        'Launcher Icons',
        'Generating icon sets across all active platforms...',
      );
      ImageService.generateLauncherIcons(
        iconPath: config.launcherIcon!,
        bgColorHex: config.launcherIconBgColor,
        bgImagePath: config.launcherIconBgImage,
        monochromeIconPath: config.launcherIconMonochrome,
      );
      Logger.subStep(
        'Android: Legacy mipmaps, Adaptive (API 26), and Themed (API 33)',
      );
      Logger.subStep(
        'iOS: Universal & legacy 20-asset catalog with iOS 18 Dark & Tinted',
      );
      if (Directory('macos').existsSync()) {
        Logger.subStep('macOS: Desktop .appiconset catalog');
      }
      if (Directory('windows').existsSync()) {
        Logger.subStep('Windows: Pure-Dart multi-resolution app_icon.ico');
      }
      if (Directory('linux').existsSync()) {
        Logger.subStep('Linux: Desktop launcher app_icon.png');
      }
      if (Directory('web').existsSync()) {
        Logger.subStep('Web: Favicon and standard/maskable PWA icons');
      }
    } else {
      Logger.step(4, totalSteps, 'Launcher Icons', 'Skipped');
    }

    // 5. Notification Icons
    if (config.notificationIcon != null) {
      Logger.step(
        5,
        totalSteps,
        'Notification Icons',
        'Generating white status bar silhouettes...',
      );
      ImageService.generateNotificationIcons(
        config.notificationIcon!,
        iconName: config.notificationIconName,
      );
      Logger.subStep(
        'Generated full-canvas "${config.notificationIconName}.png" (mdpi to xxxhdpi)',
      );
    } else {
      Logger.step(5, totalSteps, 'Notification Icons', 'Skipped');
    }

    // 6. Native Splash
    if (config.splashImage != null) {
      Logger.step(
        6,
        totalSteps,
        'Native Splash',
        'Configuring native launch screens...',
      );
      await SplashService.generateNativeSplash(
        imagePath: config.splashImage!,
        hexColor: config.splashColor,
        darkImagePath: config.splashDarkImage,
        darkHexColor: config.splashDarkColor,
        brandingImagePath: config.splashBrandingImage,
      );
    } else {
      Logger.step(6, totalSteps, 'Native Splash', 'Skipped');
    }

    // 7. Play Store Assets
    if (config.generatePlayStoreAssets && config.launcherIcon != null) {
      Logger.step(
        7,
        totalSteps,
        'Play Store Assets',
        'Generating store submission graphics...',
      );
      ImageService.generatePlayStoreAssets(
        iconPath: config.launcherIcon!,
        bgColorHex: config.playStoreBannerBgColor,
        appName: config.appName,
        tagline: config.playStoreTagline,
      );
      Logger.subStep(
        'Generated 512x512 store icon & 1024x500 banner with tagline',
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
