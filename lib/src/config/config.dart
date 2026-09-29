import 'dart:io';
import 'package:yaml/yaml.dart';

/// Configuration options for Flutter Rebrand Kit.
class RebrandConfig {
  final String? appName;
  final String? packageId;
  final String? version;
  final String? launcherIcon;
  final String launcherIconBgColor;
  final String? launcherIconBgImage;
  final String? launcherIconMonochrome;
  final String? notificationIcon;
  final String notificationIconName;
  final String? splashImage;
  final String splashColor;
  final bool generatePlayStoreAssets;
  final String playStoreBannerBgColor;
  final String? playStoreTagline;

  RebrandConfig({
    this.appName,
    this.packageId,
    this.version,
    this.launcherIcon,
    this.launcherIconBgColor = '#FFFFFF',
    this.launcherIconBgImage,
    this.launcherIconMonochrome,
    this.notificationIcon,
    this.notificationIconName = 'ic_notification',
    this.splashImage,
    this.splashColor = '#FFFFFF',
    this.generatePlayStoreAssets = false,
    this.playStoreBannerBgColor = '#1E1E2E',
    this.playStoreTagline,
  });

  factory RebrandConfig.load() {
    File configFile = File('rebrand_kit.yaml');
    dynamic yamlMap;

    if (configFile.existsSync()) {
      yamlMap = loadYaml(configFile.readAsStringSync());
    } else {
      configFile = File('pubspec.yaml');
      if (!configFile.existsSync()) {
        throw Exception(
          'Neither "rebrand_kit.yaml" nor "pubspec.yaml" was found.',
        );
      }
      final pubspec = loadYaml(configFile.readAsStringSync());
      yamlMap = pubspec['rebrand_kit'] ?? pubspec['flutter_rebrand_kit'];
    }

    if (yamlMap == null) {
      throw Exception(
        'No configuration found in "rebrand_kit.yaml" or "pubspec.yaml".',
      );
    }

    final playStore = yamlMap['play_store'] as YamlMap?;

    return RebrandConfig(
      appName: yamlMap['app_name']?.toString(),
      packageId: yamlMap['package_id']?.toString(),
      version: yamlMap['version']?.toString(),
      launcherIcon: yamlMap['launcher_icon']?.toString(),
      launcherIconBgColor:
          yamlMap['launcher_icon_bg_color']?.toString() ?? '#FFFFFF',
      launcherIconBgImage: yamlMap['launcher_icon_bg_image']?.toString(),
      launcherIconMonochrome: yamlMap['launcher_icon_monochrome']?.toString(),
      notificationIcon: yamlMap['notification_icon']?.toString(),
      notificationIconName:
          yamlMap['notification_icon_name']?.toString() ?? 'ic_notification',
      splashImage: yamlMap['splash_image']?.toString(),
      splashColor: yamlMap['splash_color']?.toString() ?? '#FFFFFF',
      generatePlayStoreAssets: playStore?['generate'] == true,
      playStoreBannerBgColor:
          playStore?['background_color']?.toString() ?? '#1E1E2E',
      playStoreTagline: playStore?['tagline']?.toString(),
    );
  }
}
