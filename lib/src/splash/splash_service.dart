import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

/// Handles complete native splash screen configuration across Android and iOS.
class SplashService {
  SplashService._();

  /// Wires Android 12+ Splash API, legacy Android drawables, and iOS Storyboards.
  static void generateNativeSplash(String imagePath, String hexColor) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Splash image not found: $imagePath');
    }

    final bytes = file.readAsBytesSync();
    final source = img.decodeImage(bytes);
    if (source == null) {
      throw Exception('Unable to decode splash image: $imagePath');
    }

    // 1. Android Drawables & Values
    const safeSize = 440;
    final scaledLogo = img.copyResize(
      source,
      width: source.width >= source.height ? safeSize : null,
      height: source.height > source.width ? safeSize : null,
    );

    final resDir = Directory('android/app/src/main/res/drawable');
    if (!resDir.existsSync()) {
      resDir.createSync(recursive: true);
    }
    File(
      '${resDir.path}/splash_logo.png',
    ).writeAsBytesSync(img.encodePng(scaledLogo));

    final valuesDir = Directory('android/app/src/main/res/values');
    if (!valuesDir.existsSync()) {
      valuesDir.createSync(recursive: true);
    }

    final colorsFile = File('${valuesDir.path}/colors.xml');
    var colorsContent = colorsFile.existsSync()
        ? colorsFile.readAsStringSync(encoding: utf8)
        : '<resources></resources>';
    if (colorsContent.contains('splash_color')) {
      colorsContent = colorsContent.replaceAll(
        RegExp(r'<color name="splash_color">.*<\/color>'),
        '<color name="splash_color">$hexColor</color>',
      );
    } else {
      colorsContent = colorsContent.replaceFirst(
        '</resources>',
        '    <color name="splash_color">$hexColor</color>\n</resources>',
      );
    }
    colorsFile.writeAsStringSync(colorsContent, encoding: utf8);

    File('${resDir.path}/launch_background.xml').writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo" />
    </item>
</layer-list>''',
      encoding: utf8,
    );

    final v31Dir = Directory('android/app/src/main/res/values-v31');
    if (!v31Dir.existsSync()) {
      v31Dir.createSync(recursive: true);
    }
    File('${v31Dir.path}/styles.xml').writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_logo</item>
    </style>
</resources>''',
      encoding: utf8,
    );

    // 2. iOS LaunchImage Catalog
    final iosLaunchDir = Directory(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset',
    );
    if (!iosLaunchDir.existsSync()) {
      iosLaunchDir.createSync(recursive: true);
    }

    File(
      '${iosLaunchDir.path}/LaunchImage.png',
    ).writeAsBytesSync(img.encodePng(scaledLogo));
    File(
      '${iosLaunchDir.path}/LaunchImage@2x.png',
    ).writeAsBytesSync(img.encodePng(scaledLogo));
    File(
      '${iosLaunchDir.path}/LaunchImage@3x.png',
    ).writeAsBytesSync(img.encodePng(scaledLogo));

    File('${iosLaunchDir.path}/Contents.json').writeAsStringSync('''{
  "images": [
    { "idiom": "universal", "filename": "LaunchImage.png", "scale": "1x" },
    { "idiom": "universal", "filename": "LaunchImage@2x.png", "scale": "2x" },
    { "idiom": "universal", "filename": "LaunchImage@3x.png", "scale": "3x" }
  ],
  "info": { "version": 1, "author": "flutter_rebrand_kit" }
}''', encoding: utf8);
  }
}
