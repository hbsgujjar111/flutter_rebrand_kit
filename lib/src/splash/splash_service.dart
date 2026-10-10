import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/android_resources.dart';
import '../utils/image_utils.dart';
import '../utils/logger.dart';

/// Handles native splash screen configuration across Android and iOS.
class SplashService {
  SplashService._();

  /// Android density buckets and their scale factors.
  static const Map<String, double> _densities = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };

  /// The Android 12 splash icon is a 288dp canvas whose visible area is a
  /// 192dp circle, so the logo is kept at 132dp (inside the circle even for a
  /// square logo) and centered. The same asset is used for the pre-Android-12
  /// `launch_background`, where the transparent padding is invisible.
  static const int _canvasDp = 288;
  static const int _logoDp = 132;

  /// iOS launch logo size in points.
  static const int _iosLogoPoints = 150;

  static const String _launchBackgroundXml =
      '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
</layer-list>
''';

  static const String _freshV31Styles =
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_logo</item>
    </style>
</resources>
''';

  /// Generates the native splash for every platform folder that exists and
  /// returns the platforms that were updated.
  static List<String> generateNativeSplash(String imagePath, String hexColor) {
    final colorHex = ImageUtils.normalizeHex(hexColor);
    final logo = ImageUtils.loadAndValidateIcon(imagePath);

    final platforms = <String>[];
    if (Directory('android').existsSync()) {
      _generateAndroid(logo, colorHex);
      platforms.add('Android');
    }
    if (Directory('ios').existsSync()) {
      _generateIos(logo, colorHex);
      platforms.add('iOS');
    }
    if (platforms.isEmpty) {
      Logger.warn('No android/ or ios/ folder found; native splash skipped.');
    }
    return platforms;
  }

  // ---------------------------------------------------------------------------
  // Android
  // ---------------------------------------------------------------------------

  static void _generateAndroid(img.Image logo, String colorHex) {
    final resDir = p.join('android', 'app', 'src', 'main', 'res');

    // Older versions wrote a single, density-less splash_logo.png that was
    // displayed far too large. Remove it so it can never shadow the new ones.
    final staleLogo = File(p.join(resDir, 'drawable', 'splash_logo.png'));
    if (staleLogo.existsSync()) {
      try {
        staleLogo.deleteSync();
      } catch (_) {}
    }

    for (final entry in _densities.entries) {
      final canvasPx = (_canvasDp * entry.value).round();
      final logoPx = (_logoDp * entry.value).round();

      final canvas = img.Image(
        width: canvasPx,
        height: canvasPx,
        numChannels: 4,
      );
      final scaled = img.copyResize(
        logo,
        width: logoPx,
        height: logoPx,
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(
        canvas,
        scaled,
        dstX: ((canvasPx - logoPx) / 2).round(),
        dstY: ((canvasPx - logoPx) / 2).round(),
      );

      final dir = Directory(p.join(resDir, 'drawable-${entry.key}'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File(
        p.join(dir.path, 'splash_logo.png'),
      ).writeAsBytesSync(img.encodePng(canvas));
    }

    AndroidResources.setColor('splash_color', colorHex);

    // `drawable-v21` overrides `drawable` on every modern device, and the
    // default Flutter template ships its own file there, so both are written.
    for (final folder in ['drawable', 'drawable-v21']) {
      final dir = Directory(p.join(resDir, folder));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File(
        p.join(dir.path, 'launch_background.xml'),
      ).writeAsStringSync(_launchBackgroundXml, encoding: utf8);
    }

    _writeAndroid12Styles(resDir);
  }

  /// Creates `values-v31/styles.xml`, or merges the splash items into an
  /// existing `LaunchTheme` without discarding the rest of the file.
  static void _writeAndroid12Styles(String resDir) {
    final file = File(p.join(resDir, 'values-v31', 'styles.xml'));
    file.parent.createSync(recursive: true);

    if (!file.existsSync()) {
      file.writeAsStringSync(_freshV31Styles, encoding: utf8);
      return;
    }

    var content = file.readAsStringSync(encoding: utf8);
    final launchTheme = RegExp(
      r'(<style\s+name="LaunchTheme"[^>]*>)([\s\S]*?)(</style>)',
    );
    final match = launchTheme.firstMatch(content);

    if (match != null) {
      var body = match.group(2)!;
      body = _setStyleItem(
        body,
        'android:windowSplashScreenBackground',
        '@color/splash_color',
        overwrite: true,
      );
      body = _setStyleItem(
        body,
        'android:windowSplashScreenAnimatedIcon',
        '@drawable/splash_logo',
        overwrite: true,
      );
      body = _setStyleItem(
        body,
        'android:windowBackground',
        '@drawable/launch_background',
        overwrite: false,
      );
      content = content.replaceRange(
        match.start,
        match.end,
        '${match.group(1)}$body${match.group(3)}',
      );
    } else if (content.contains('</resources>')) {
      const style =
          '''    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_logo</item>
    </style>
''';
      content = content.replaceFirst('</resources>', '$style</resources>');
    } else {
      content = _freshV31Styles;
    }

    file.writeAsStringSync(content, encoding: utf8);
  }

  static String _setStyleItem(
    String body,
    String name,
    String value, {
    required bool overwrite,
  }) {
    final item = '<item name="$name">$value</item>';
    final existing = RegExp(
      '<item\\s+name="${RegExp.escape(name)}"[^>]*>[^<]*</item>',
    );
    if (existing.hasMatch(body)) {
      return overwrite ? body.replaceFirstMapped(existing, (_) => item) : body;
    }
    return '${body.trimRight()}\n        $item\n    ';
  }

  // ---------------------------------------------------------------------------
  // iOS
  // ---------------------------------------------------------------------------

  static void _generateIos(img.Image logo, String colorHex) {
    final imageSet = Directory(
      p.join('ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset'),
    );
    if (!imageSet.existsSync()) {
      imageSet.createSync(recursive: true);
    }

    for (final scale in [1, 2, 3]) {
      final px = _iosLogoPoints * scale;
      final scaled = img.copyResize(
        logo,
        width: px,
        height: px,
        interpolation: img.Interpolation.average,
      );
      final name = scale == 1 ? 'LaunchImage.png' : 'LaunchImage@${scale}x.png';
      File(p.join(imageSet.path, name)).writeAsBytesSync(img.encodePng(scaled));
    }

    File(p.join(imageSet.path, 'Contents.json')).writeAsStringSync('''{
  "images": [
    { "idiom": "universal", "filename": "LaunchImage.png", "scale": "1x" },
    { "idiom": "universal", "filename": "LaunchImage@2x.png", "scale": "2x" },
    { "idiom": "universal", "filename": "LaunchImage@3x.png", "scale": "3x" }
  ],
  "info": { "version": 1, "author": "flutter_rebrand_kit" }
}''', encoding: utf8);

    _setStoryboardBackground(colorHex);
  }

  /// Applies [hex] as the background color of `LaunchScreen.storyboard`.
  static void _setStoryboardBackground(String hex) {
    final storyboard = File(
      p.join('ios', 'Runner', 'Base.lproj', 'LaunchScreen.storyboard'),
    );
    if (!storyboard.existsSync()) {
      Logger.warn(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard not found. Set the '
        'launch screen background color manually.',
      );
      return;
    }

    final content = storyboard.readAsStringSync(encoding: utf8);
    if (!content.contains('LaunchImage')) {
      Logger.warn(
        'LaunchScreen.storyboard does not reference the "LaunchImage" asset, '
        'so the generated splash logo will not be displayed.',
      );
    }

    final rgb = ImageUtils.parseHexColor(hex);
    String component(num value) => (value / 255).toStringAsFixed(5);
    final color =
        '<color key="backgroundColor" red="${component(rgb.r)}" '
        'green="${component(rgb.g)}" blue="${component(rgb.b)}" alpha="1" '
        'colorSpace="custom" customColorSpace="sRGB"/>';

    final background = RegExp(
      r'(</subviews>\s*)<color key="backgroundColor"[^>]*/>',
    );
    if (!background.hasMatch(content)) {
      Logger.warn(
        'Could not find the background color in LaunchScreen.storyboard. '
        'Set the launch screen background color manually.',
      );
      return;
    }

    storyboard.writeAsStringSync(
      content.replaceFirstMapped(background, (m) => '${m[1]}$color'),
      encoding: utf8,
    );
  }
}
