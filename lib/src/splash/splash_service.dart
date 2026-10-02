import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/logger.dart';

/// Handles complete native splash screen configuration across Android, iOS, and Web.
class SplashService {
  SplashService._();

  /// Generates native splash resources with density scaling, dark mode, and branding footers.
  static Future<void> generateNativeSplash({
    required String imagePath,
    required String hexColor,
    String? darkImagePath,
    String? darkHexColor,
    String? brandingImagePath,
    String? darkBrandingImagePath,
  }) async {
    final lightImage = _decodeImage(imagePath);
    final darkImage = darkImagePath != null
        ? _decodeImage(darkImagePath)
        : null;
    final brandingImage = brandingImagePath != null
        ? _decodeImage(brandingImagePath)
        : null;
    final darkBrandingImage = darkBrandingImagePath != null
        ? _decodeImage(darkBrandingImagePath)
        : brandingImage;

    // 1. Android
    Logger.subStep(
      'Android: Creating density drawables (mdpi through xxxhdpi)',
    );
    await _generateAndroidSplash(
      lightImage: lightImage,
      lightHexColor: hexColor,
      darkImage: darkImage,
      darkHexColor: darkHexColor,
      brandingImage: brandingImage,
      darkBrandingImage: darkBrandingImage,
    );

    // 2. iOS
    Logger.subStep(
      'iOS: Creating LaunchImage.imageset (Light, Dark, Branding)',
    );
    _generateIosSplash(
      lightImage: lightImage,
      darkImage: darkImage,
      brandingImage: brandingImage,
      darkBrandingImage: darkBrandingImage,
    );

    // 3. Web
    if (Directory('web').existsSync()) {
      Logger.subStep(
        'Web: Injecting responsive CSS/HTML preloader with auto-dismiss',
      );
      _generateWebSplash(
        lightImagePath: imagePath,
        hexColor: hexColor,
        darkHexColor: darkHexColor,
        brandingImagePath: brandingImagePath,
      );
    }
  }

  // ==========================================
  // ANDROID
  // ==========================================
  static Future<void> _generateAndroidSplash({
    required img.Image lightImage,
    required String lightHexColor,
    img.Image? darkImage,
    String? darkHexColor,
    img.Image? brandingImage,
    img.Image? darkBrandingImage,
  }) async {
    final densities = {
      'drawable-mdpi': 1.0,
      'drawable-hdpi': 1.5,
      'drawable-xhdpi': 2.0,
      'drawable-xxhdpi': 3.0,
      'drawable-xxxhdpi': 4.0,
    };

    final writeTasks = <Future<void>>[];

    for (final entry in densities.entries) {
      final density = entry.value;
      final dir = Directory(
        p.join('android', 'app', 'src', 'main', 'res', entry.key),
      );
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      writeTasks.add(
        Future(() {
          // 1. Center Splash Logo: Fit inside a 150dp circle on a 288dp canvas to prevent circular clipping
          final splashCanvas = _createAndroid12SplashCanvas(
            lightImage,
            density,
          );
          File(
            p.join(dir.path, 'splash_logo.png'),
          ).writeAsBytesSync(img.encodePng(splashCanvas));

          if (darkImage != null) {
            final darkSplashCanvas = _createAndroid12SplashCanvas(
              darkImage,
              density,
            );
            File(
              p.join(dir.path, 'splash_logo_dark.png'),
            ).writeAsBytesSync(img.encodePng(darkSplashCanvas));
          }

          // 2. Branding Logo: Fit inside exact 200x80 dp (800x320 px @ xxxhdpi) canvas to prevent stretching
          if (brandingImage != null) {
            final brandingCanvas = _createAndroid12BrandingCanvas(
              brandingImage,
              density,
            );
            File(
              p.join(dir.path, 'splash_branding.png'),
            ).writeAsBytesSync(img.encodePng(brandingCanvas));

            if (darkBrandingImage != null) {
              final darkBrandingCanvas = _createAndroid12BrandingCanvas(
                darkBrandingImage,
                density,
              );
              File(
                p.join(dir.path, 'splash_branding_dark.png'),
              ).writeAsBytesSync(img.encodePng(darkBrandingCanvas));
            }
          }
        }),
      );
    }

    await Future.wait(writeTasks);

    // Colors
    _writeColorXml(
      'android/app/src/main/res/values',
      'splash_color',
      lightHexColor,
    );
    if (darkHexColor != null) {
      _writeColorXml(
        'android/app/src/main/res/values-night',
        'splash_color',
        darkHexColor,
      );
    }

    // Android <12 (launch_background.xml)
    final resDir = Directory(
      p.join('android', 'app', 'src', 'main', 'res', 'drawable'),
    );
    if (!resDir.existsSync()) {
      resDir.createSync(recursive: true);
    }

    // Clean up stale root splash_logo to force Android to load the high-density bucket
    final rootSplash = File(p.join(resDir.path, 'splash_logo.png'));
    if (rootSplash.existsSync()) {
      try {
        rootSplash.deleteSync();
      } catch (_) {}
    }

    final brandingItemXml = brandingImage != null
        ? '''
    <item android:bottom="32dp">
        <bitmap android:gravity="bottom|center_horizontal" android:src="@drawable/splash_branding" />
    </item>'''
        : '';

    File(p.join(resDir.path, 'launch_background.xml')).writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash_logo" />
    </item>$brandingItemXml
</layer-list>''',
      encoding: utf8,
    );

    if (darkImage != null || darkHexColor != null) {
      final nightDrawableDir = Directory(
        p.join('android', 'app', 'src', 'main', 'res', 'drawable-night'),
      );
      if (!nightDrawableDir.existsSync()) {
        nightDrawableDir.createSync(recursive: true);
      }
      final logoRef = darkImage != null
          ? '@drawable/splash_logo_dark'
          : '@drawable/splash_logo';
      final darkBrandingRef = darkBrandingImage != null
          ? '@drawable/splash_branding_dark'
          : '@drawable/splash_branding';
      final darkBrandingXml = brandingImage != null
          ? '''
    <item android:bottom="32dp">
        <bitmap android:gravity="bottom|center_horizontal" android:src="$darkBrandingRef" />
    </item>'''
          : '';

      File(
        p.join(nightDrawableDir.path, 'launch_background.xml'),
      ).writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
    <item>
        <bitmap android:gravity="center" android:src="$logoRef" />
    </item>$darkBrandingXml
</layer-list>''', encoding: utf8);
    }

    // Android 12+ API (values-v31/styles.xml)
    final v31Dir = Directory(
      p.join('android', 'app', 'src', 'main', 'res', 'values-v31'),
    );
    if (!v31Dir.existsSync()) {
      v31Dir.createSync(recursive: true);
    }

    final android12Branding = brandingImage != null
        ? '\n        <item name="android:windowSplashScreenBrandingImage">@drawable/splash_branding</item>'
        : '';

    File(p.join(v31Dir.path, 'styles.xml')).writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_logo</item>$android12Branding
    </style>
</resources>''',
      encoding: utf8,
    );

    if (darkImage != null || darkHexColor != null) {
      final nightV31Dir = Directory(
        p.join('android', 'app', 'src', 'main', 'res', 'values-night-v31'),
      );
      if (!nightV31Dir.existsSync()) {
        nightV31Dir.createSync(recursive: true);
      }
      final darkLogoRef = darkImage != null
          ? '@drawable/splash_logo_dark'
          : '@drawable/splash_logo';
      final darkBrandingItem = brandingImage != null
          ? '\n        <item name="android:windowSplashScreenBrandingImage">@drawable/splash_branding_dark</item>'
          : '';

      File(p.join(nightV31Dir.path, 'styles.xml')).writeAsStringSync(
        '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">$darkLogoRef</item>$darkBrandingItem
    </style>
</resources>''',
        encoding: utf8,
      );
    }
  }

  /// Centers the logo inside a 288dp canvas, scaling it to fill the allowed 192dp circular window without clipping.
  static img.Image _createAndroid12SplashCanvas(
    img.Image source,
    double density,
  ) {
    // 288dp standard Android 12 canvas (1152px at xxxhdpi)
    final canvasSize = (288 * density).round();
    final canvas = img.Image(
      width: canvasSize,
      height: canvasSize,
      numChannels: 4,
    );

    // Fill the 192dp safe circular boundary (768px at xxxhdpi) without touching the circular mask
    final maxAllowedSize = (180 * density).round();
    final scaleRatio = min(
      maxAllowedSize / source.width,
      maxAllowedSize / source.height,
    );

    final targetW = (source.width * scaleRatio).round();
    final targetH = (source.height * scaleRatio).round();

    // Use Bicubic interpolation for crisp edge contrast
    final scaled = img.copyResize(
      source,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.cubic,
    );

    img.compositeImage(
      canvas,
      scaled,
      dstX: ((canvasSize - targetW) / 2).round(),
      dstY: ((canvasSize - targetH) / 2).round(),
    );

    return canvas;
  }

  /// Centers the branding logo inside an exact 200x80 dp canvas (2.5:1 ratio required by Google) to prevent stretching.
  static img.Image _createAndroid12BrandingCanvas(
    img.Image source,
    double density,
  ) {
    final canvasW = (200 * density).round();
    final canvasH = (80 * density).round();
    final canvas = img.Image(width: canvasW, height: canvasH, numChannels: 4);

    final scaleRatio = min(canvasW / source.width, canvasH / source.height);
    final targetW = (source.width * scaleRatio).round();
    final targetH = (source.height * scaleRatio).round();

    final scaled = img.copyResize(
      source,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.average,
    );

    img.compositeImage(
      canvas,
      scaled,
      dstX: ((canvasW - targetW) / 2).round(),
      dstY: ((canvasH - targetH) / 2).round(),
    );

    return canvas;
  }

  // ==========================================
  // iOS
  // ==========================================
  static void _generateIosSplash({
    required img.Image lightImage,
    img.Image? darkImage,
    img.Image? brandingImage,
    img.Image? darkBrandingImage,
  }) {
    final iosLaunchDir = Directory(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset',
    );
    if (!iosLaunchDir.existsSync()) {
      iosLaunchDir.createSync(recursive: true);
    }

    const safeSize = 440;
    final scaledLightLogo = _scaleToFit(lightImage, safeSize);

    File(
      p.join(iosLaunchDir.path, 'LaunchImage.png'),
    ).writeAsBytesSync(img.encodePng(scaledLightLogo));
    File(
      p.join(iosLaunchDir.path, 'LaunchImage@2x.png'),
    ).writeAsBytesSync(img.encodePng(scaledLightLogo));
    File(
      p.join(iosLaunchDir.path, 'LaunchImage@3x.png'),
    ).writeAsBytesSync(img.encodePng(scaledLightLogo));

    final launchImagesList = <Map<String, dynamic>>[
      {'idiom': 'universal', 'filename': 'LaunchImage.png', 'scale': '1x'},
      {'idiom': 'universal', 'filename': 'LaunchImage@2x.png', 'scale': '2x'},
      {'idiom': 'universal', 'filename': 'LaunchImage@3x.png', 'scale': '3x'},
    ];

    if (darkImage != null) {
      final scaledDarkLogo = _scaleToFit(darkImage, safeSize);
      File(
        p.join(iosLaunchDir.path, 'LaunchImageDark.png'),
      ).writeAsBytesSync(img.encodePng(scaledDarkLogo));
      File(
        p.join(iosLaunchDir.path, 'LaunchImageDark@2x.png'),
      ).writeAsBytesSync(img.encodePng(scaledDarkLogo));
      File(
        p.join(iosLaunchDir.path, 'LaunchImageDark@3x.png'),
      ).writeAsBytesSync(img.encodePng(scaledDarkLogo));

      launchImagesList.addAll([
        {
          'idiom': 'universal',
          'filename': 'LaunchImageDark.png',
          'scale': '1x',
          'appearances': [
            {'appearance': 'luminosity', 'value': 'dark'},
          ],
        },
        {
          'idiom': 'universal',
          'filename': 'LaunchImageDark@2x.png',
          'scale': '2x',
          'appearances': [
            {'appearance': 'luminosity', 'value': 'dark'},
          ],
        },
        {
          'idiom': 'universal',
          'filename': 'LaunchImageDark@3x.png',
          'scale': '3x',
          'appearances': [
            {'appearance': 'luminosity', 'value': 'dark'},
          ],
        },
      ]);
    }

    File(p.join(iosLaunchDir.path, 'Contents.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'images': launchImagesList,
        'info': {'version': 1, 'author': 'flutter_rebrand_kit'},
      }),
      encoding: utf8,
    );

    // Branding Image
    if (brandingImage != null) {
      final iosBrandingDir = Directory(
        'ios/Runner/Assets.xcassets/BrandingImage.imageset',
      );
      if (!iosBrandingDir.existsSync()) {
        iosBrandingDir.createSync(recursive: true);
      }

      const brandingSize = 200;
      final scaledBranding = _scaleToFit(brandingImage, brandingSize);

      File(
        p.join(iosBrandingDir.path, 'BrandingImage.png'),
      ).writeAsBytesSync(img.encodePng(scaledBranding));
      File(
        p.join(iosBrandingDir.path, 'BrandingImage@2x.png'),
      ).writeAsBytesSync(img.encodePng(scaledBranding));
      File(
        p.join(iosBrandingDir.path, 'BrandingImage@3x.png'),
      ).writeAsBytesSync(img.encodePng(scaledBranding));

      final brandingImagesList = <Map<String, dynamic>>[
        {'idiom': 'universal', 'filename': 'BrandingImage.png', 'scale': '1x'},
        {
          'idiom': 'universal',
          'filename': 'BrandingImage@2x.png',
          'scale': '2x',
        },
        {
          'idiom': 'universal',
          'filename': 'BrandingImage@3x.png',
          'scale': '3x',
        },
      ];

      if (darkBrandingImage != null) {
        final scaledDarkBranding = _scaleToFit(darkBrandingImage, brandingSize);
        File(
          p.join(iosBrandingDir.path, 'BrandingImageDark.png'),
        ).writeAsBytesSync(img.encodePng(scaledDarkBranding));
        File(
          p.join(iosBrandingDir.path, 'BrandingImageDark@2x.png'),
        ).writeAsBytesSync(img.encodePng(scaledDarkBranding));
        File(
          p.join(iosBrandingDir.path, 'BrandingImageDark@3x.png'),
        ).writeAsBytesSync(img.encodePng(scaledDarkBranding));

        brandingImagesList.addAll([
          {
            'idiom': 'universal',
            'filename': 'BrandingImageDark.png',
            'scale': '1x',
            'appearances': [
              {'appearance': 'luminosity', 'value': 'dark'},
            ],
          },
          {
            'idiom': 'universal',
            'filename': 'BrandingImageDark@2x.png',
            'scale': '2x',
            'appearances': [
              {'appearance': 'luminosity', 'value': 'dark'},
            ],
          },
          {
            'idiom': 'universal',
            'filename': 'BrandingImageDark@3x.png',
            'scale': '3x',
            'appearances': [
              {'appearance': 'luminosity', 'value': 'dark'},
            ],
          },
        ]);
      }

      File(p.join(iosBrandingDir.path, 'Contents.json')).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'images': brandingImagesList,
          'info': {'version': 1, 'author': 'flutter_rebrand_kit'},
        }),
        encoding: utf8,
      );
    }
  }

  // ==========================================
  // WEB
  // ==========================================
  static void _generateWebSplash({
    required String lightImagePath,
    required String hexColor,
    String? darkHexColor,
    String? brandingImagePath,
  }) {
    final webDir = Directory('web');
    final splashImgDir = Directory(p.join('web', 'splash'));
    if (!splashImgDir.existsSync()) {
      splashImgDir.createSync(recursive: true);
    }

    final srcFile = File(lightImagePath);
    srcFile.copySync(p.join('web', 'splash', 'splash.png'));

    if (brandingImagePath != null) {
      File(brandingImagePath).copySync(p.join('web', 'splash', 'branding.png'));
    }

    final indexFile = File(p.join(webDir.path, 'index.html'));
    if (!indexFile.existsSync()) return;

    var content = indexFile.readAsStringSync(encoding: utf8);

    final darkCss = darkHexColor != null
        ? '''
    @media (prefers-color-scheme: dark) {
      body {
        background-color: $darkHexColor;
      }
    }'''
        : '';

    final styleTag =
        '''
  <style id="splash-screen-style">
    body {
      background-color: $hexColor;
      margin: 0;
      padding: 0;
    }
    .splash-container {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      z-index: 99999;
      pointer-events: none;
      user-select: none;
      -webkit-user-drag: none;
    }
    .splash-logo {
      max-width: 200px;
      max-height: 200px;
      object-fit: contain;
      pointer-events: none;
      user-select: none;
    }
    .splash-branding {
      position: absolute;
      bottom: 32px;
      max-width: 200px;
      max-height: 80px;
      object-fit: contain;
      pointer-events: none;
      user-select: none;
    }$darkCss
  </style>''';

    final brandingHtml = brandingImagePath != null
        ? '\n    <img class="splash-branding" src="splash/branding.png" alt="Branding" />'
        : '';

    final bodyTag =
        '''
  <div id="splash-screen" class="splash-container">
    <img class="splash-logo" src="splash/splash.png" alt="Splash" />$brandingHtml
  </div>
  <script id="splash-screen-script">
    window.addEventListener("flutter-first-frame", function () {
      var splash = document.getElementById("splash-screen");
      if (splash) splash.remove();
    });
  </script>''';

    if (content.contains('id="splash-screen-style"')) {
      content = content.replaceAll(
        RegExp(r'<style id="splash-screen-style">[\s\S]*?</style>'),
        styleTag,
      );
    } else {
      content = content.replaceFirst('</head>', '$styleTag\n</head>');
    }

    if (content.contains('id="splash-screen"')) {
      content = content.replaceAll(
        RegExp(r'<div id="splash-screen"[\s\S]*?</script>'),
        bodyTag.trim(),
      );
    } else {
      content = content.replaceFirst('<body>', '<body>\n$bodyTag');
    }

    indexFile.writeAsStringSync(content, encoding: utf8);
  }

  static img.Image _decodeImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Splash image not found: $path');
    }
    final image = img.decodeImage(file.readAsBytesSync());
    if (image == null) {
      throw Exception('Unable to decode splash image: $path');
    }
    return image;
  }

  static img.Image _scaleToFit(img.Image source, int maxSize) {
    return img.copyResize(
      source,
      width: source.width >= source.height ? maxSize : null,
      height: source.height > source.width ? maxSize : null,
      interpolation: img.Interpolation.average,
    );
  }

  static void _writeColorXml(
    String dirPath,
    String colorName,
    String hexColor,
  ) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File(p.join(dir.path, 'colors.xml'));
    var content = file.existsSync()
        ? file.readAsStringSync(encoding: utf8)
        : '<resources></resources>';
    if (content.contains(colorName)) {
      content = content.replaceAll(
        RegExp('<color name="$colorName">.*<\\/color>'),
        '<color name="$colorName">$hexColor</color>',
      );
    } else {
      content = content.replaceFirst(
        '</resources>',
        '    <color name="$colorName">$hexColor</color>\n</resources>',
      );
    }
    file.writeAsStringSync(content, encoding: utf8);
  }
}
