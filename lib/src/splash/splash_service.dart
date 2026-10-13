import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/android_resources.dart';
import '../utils/image_utils.dart';
import '../utils/logger.dart';

/// Everything the platform generators need, loaded and validated once.
class _Splash {
  _Splash({
    required this.logo,
    required this.colorHex,
    this.darkLogo,
    this.darkHex,
    this.branding,
    this.darkBranding,
  });

  final img.Image logo;
  final String colorHex;
  final img.Image? darkLogo;
  final String? darkHex;
  final img.Image? branding;
  final img.Image? darkBranding;

  bool get hasDark => darkLogo != null || darkHex != null;
}

/// Handles native splash screen configuration across Android, iOS and Web.
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
  /// 192dp circle. The visible artwork (transparent margins trimmed) is sized
  /// so its diagonal is [_logoDiagonalDp], which keeps even the corners of a
  /// rectangular logo inside the circle. The same asset is used for the
  /// pre-Android-12 `launch_background`, where the padding is invisible.
  static const int _canvasDp = 288;
  static const double _logoDiagonalDp = 188;

  /// Android 12 branding image canvas (dp), as required by the platform.
  static const int _brandingWidthDp = 200;
  static const int _brandingHeightDp = 80;

  /// iOS launch logo box and branding box, in points.
  static const int _iosLogoPoints = 150;
  static const int _iosBrandingWidth = 200;
  static const int _iosBrandingHeight = 80;
  static const int _iosBrandingBottom = 48;

  static const String _lightParent = '@android:style/Theme.Light.NoTitleBar';
  static const String _nightParent = '@android:style/Theme.Black.NoTitleBar';

  /// Generates the native splash for every platform folder that exists and
  /// returns the platforms that were updated.
  ///
  /// [darkImagePath] / [darkHexColor] add a dark-mode variant, and
  /// [brandingImagePath] (with an optional [brandingDarkImagePath]) adds a
  /// footer image.
  static List<String> generateNativeSplash(
    String imagePath,
    String hexColor, {
    String? darkImagePath,
    String? darkHexColor,
    String? brandingImagePath,
    String? brandingDarkImagePath,
  }) {
    final colorHex = ImageUtils.normalizeHex(hexColor);
    final darkHex = darkHexColor == null
        ? null
        : ImageUtils.normalizeHex(darkHexColor);

    final logo = ImageUtils.loadAndValidateIcon(imagePath);
    final darkLogo = darkImagePath == null
        ? null
        : ImageUtils.loadAndValidateIcon(darkImagePath);

    img.Image? branding;
    img.Image? darkBranding;
    if (brandingImagePath != null) {
      branding = ImageUtils.loadImage(brandingImagePath);
      if (brandingDarkImagePath != null) {
        darkBranding = ImageUtils.loadImage(brandingDarkImagePath);
      }
    } else if (brandingDarkImagePath != null) {
      Logger.warn(
        '"splash_branding_dark_image" is ignored because '
        '"splash_branding_image" is not set.',
      );
    }

    final splash = _Splash(
      logo: logo,
      colorHex: colorHex,
      darkLogo: darkLogo,
      darkHex: darkHex,
      branding: branding,
      darkBranding: darkBranding,
    );

    final platforms = <String>[];
    if (Directory('android').existsSync()) {
      _generateAndroid(splash);
      platforms.add('Android');
    }
    if (Directory('ios').existsSync()) {
      _generateIos(splash);
      platforms.add('iOS');
    }
    if (Directory('web').existsSync() && _generateWeb(splash)) {
      platforms.add('Web');
    }
    if (platforms.isEmpty) {
      Logger.warn(
        'No android/, ios/ or web/ folder found; native splash skipped.',
      );
    }
    return platforms;
  }

  // ---------------------------------------------------------------------------
  // Android
  // ---------------------------------------------------------------------------

  static void _generateAndroid(_Splash s) {
    final resDir = p.join('android', 'app', 'src', 'main', 'res');

    // Older versions wrote a single, density-less splash_logo.png that was
    // displayed far too large. Remove it so it can never shadow the new ones.
    _deleteIfExists(p.join(resDir, 'drawable', 'splash_logo.png'));

    final logo = ImageUtils.trimTransparent(s.logo);
    final darkLogo = s.darkLogo == null
        ? null
        : ImageUtils.trimTransparent(s.darkLogo!);

    for (final entry in _densities.entries) {
      final dir = Directory(p.join(resDir, 'drawable-${entry.key}'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final density = entry.value;

      _writePng(
        p.join(dir.path, 'splash_logo.png'),
        _androidLogoCanvas(logo, density),
      );

      final darkLogoPath = p.join(dir.path, 'splash_logo_dark.png');
      if (darkLogo != null) {
        _writePng(darkLogoPath, _androidLogoCanvas(darkLogo, density));
      } else {
        _deleteIfExists(darkLogoPath);
      }

      final brandingPath = p.join(dir.path, 'splash_branding.png');
      final darkBrandingPath = p.join(dir.path, 'splash_branding_dark.png');
      if (s.branding != null) {
        _writePng(brandingPath, _androidBrandingCanvas(s.branding!, density));
        if (s.darkBranding != null) {
          _writePng(
            darkBrandingPath,
            _androidBrandingCanvas(s.darkBranding!, density),
          );
        } else {
          _deleteIfExists(darkBrandingPath);
        }
      } else {
        _deleteIfExists(brandingPath);
        _deleteIfExists(darkBrandingPath);
      }
    }

    // Drawable references for light and dark.
    const lightLogoRef = '@drawable/splash_logo';
    final darkLogoRef = darkLogo != null
        ? '@drawable/splash_logo_dark'
        : lightLogoRef;
    final lightBrandingRef = s.branding != null
        ? '@drawable/splash_branding'
        : null;
    final darkBrandingRef = s.branding == null
        ? null
        : (s.darkBranding != null
              ? '@drawable/splash_branding_dark'
              : lightBrandingRef);

    // Colors: values/ for light, values-night/ for dark.
    AndroidResources.setColor('splash_color', s.colorHex);
    if (s.darkHex != null) {
      AndroidResources.setColor(
        'splash_color',
        s.darkHex!,
        valuesFolder: 'values-night',
      );
    } else {
      // A dark color from an earlier run would otherwise keep winning.
      AndroidResources.removeColor(
        'splash_color',
        valuesFolder: 'values-night',
      );
    }

    // `drawable-v21` overrides `drawable` on every modern device, and the
    // default Flutter template ships its own file there, so both are written.
    final lightBackground = _launchBackgroundXml(
      logoRef: lightLogoRef,
      brandingRef: lightBrandingRef,
    );
    for (final folder in ['drawable', 'drawable-v21']) {
      _writeText(
        p.join(resDir, folder, 'launch_background.xml'),
        lightBackground,
      );
    }

    // `night` outranks the API level in Android's resource selection, so a
    // dark variant goes into drawable-night (and drawable-night-v21 when the
    // project already has one).
    if (s.hasDark) {
      final darkBackground = _launchBackgroundXml(
        logoRef: darkLogoRef,
        brandingRef: darkBrandingRef,
      );
      _writeText(
        p.join(resDir, 'drawable-night', 'launch_background.xml'),
        darkBackground,
      );
      final nightV21 = File(
        p.join(resDir, 'drawable-night-v21', 'launch_background.xml'),
      );
      if (nightV21.existsSync()) {
        nightV21.writeAsStringSync(darkBackground, encoding: utf8);
      }
    } else {
      // Dark assets from an earlier run were just deleted; a night drawable
      // that still points at them would break the build.
      for (final folder in ['drawable-night', 'drawable-night-v21']) {
        final file = File(p.join(resDir, folder, 'launch_background.xml'));
        if (file.existsSync() &&
            file
                .readAsStringSync(encoding: utf8)
                .contains('splash_logo_dark')) {
          file.deleteSync();
        }
      }
    }

    // Android 12+ splash theme.
    _writeAndroid12Styles(
      resDir,
      folder: 'values-v31',
      parent: _lightParent,
      logoRef: lightLogoRef,
      brandingRef: lightBrandingRef,
    );

    // The Flutter template ships values-night/styles.xml, and `night`
    // outranks `v31`. Without a values-night-v31 file, Android 12+ devices in
    // dark mode would not use the splash theme above.
    final nightStyles = File(p.join(resDir, 'values-night', 'styles.xml'));
    final nightV31 = File(p.join(resDir, 'values-night-v31', 'styles.xml'));
    if (s.hasDark || nightStyles.existsSync() || nightV31.existsSync()) {
      _writeAndroid12Styles(
        resDir,
        folder: 'values-night-v31',
        parent: _nightParent,
        logoRef: darkLogoRef,
        brandingRef: darkBrandingRef,
      );
    }
  }

  static img.Image _androidLogoCanvas(img.Image trimmedLogo, double density) {
    final canvasPx = (_canvasDp * density).round();
    final canvas = img.Image(width: canvasPx, height: canvasPx, numChannels: 4);
    final scaled = ImageUtils.fitDiagonal(
      trimmedLogo,
      _logoDiagonalDp * density,
    );
    img.compositeImage(
      canvas,
      scaled,
      dstX: ((canvasPx - scaled.width) / 2).round(),
      dstY: ((canvasPx - scaled.height) / 2).round(),
    );
    return canvas;
  }

  static img.Image _androidBrandingCanvas(img.Image branding, double density) {
    final width = (_brandingWidthDp * density).round();
    final height = (_brandingHeightDp * density).round();
    final canvas = img.Image(width: width, height: height, numChannels: 4);
    final scaled = ImageUtils.fitInside(branding, width, height);
    img.compositeImage(
      canvas,
      scaled,
      dstX: ((width - scaled.width) / 2).round(),
      dstY: ((height - scaled.height) / 2).round(),
    );
    return canvas;
  }

  static String _launchBackgroundXml({
    required String logoRef,
    String? brandingRef,
  }) {
    final branding = brandingRef == null
        ? ''
        : '''
    <item android:bottom="32dp">
        <bitmap
            android:gravity="bottom|center_horizontal"
            android:src="$brandingRef" />
    </item>
''';
    return '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="$logoRef" />
    </item>
$branding</layer-list>
''';
  }

  static String _freshStyles({
    required String parent,
    required String logoRef,
    String? brandingRef,
  }) {
    final branding = brandingRef == null
        ? ''
        : '''
        <item name="android:windowSplashScreenBrandingImage">$brandingRef</item>''';
    return '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="$parent">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_color</item>
        <item name="android:windowSplashScreenAnimatedIcon">$logoRef</item>$branding
    </style>
</resources>
''';
  }

  /// Creates `[folder]/styles.xml`, or merges the splash items into an
  /// existing `LaunchTheme` without discarding the rest of the file.
  static void _writeAndroid12Styles(
    String resDir, {
    required String folder,
    required String parent,
    required String logoRef,
    String? brandingRef,
  }) {
    final file = File(p.join(resDir, folder, 'styles.xml'));
    file.parent.createSync(recursive: true);

    final fresh = _freshStyles(
      parent: parent,
      logoRef: logoRef,
      brandingRef: brandingRef,
    );

    if (!file.existsSync()) {
      file.writeAsStringSync(fresh, encoding: utf8);
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
        logoRef,
        overwrite: true,
      );
      if (brandingRef != null) {
        body = _setStyleItem(
          body,
          'android:windowSplashScreenBrandingImage',
          brandingRef,
          overwrite: true,
        );
      } else {
        // Branding was removed from the config; its drawables are deleted, so
        // the reference must go as well.
        body = body.replaceAll(
          RegExp(
            r'\s*<item\s+name="android:windowSplashScreenBrandingImage"[^>]*>'
            r'@drawable/splash_branding(?:_dark)?</item>',
          ),
          '',
        );
      }
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
      final style = fresh.substring(
        fresh.indexOf('    <style'),
        fresh.indexOf('</resources>'),
      );
      content = content.replaceFirst('</resources>', '$style</resources>');
    } else {
      content = fresh;
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

  static void _generateIos(_Splash s) {
    final assets = p.join('ios', 'Runner', 'Assets.xcassets');

    final logo = ImageUtils.trimTransparent(s.logo);
    final darkLogo = s.darkLogo == null
        ? null
        : ImageUtils.trimTransparent(s.darkLogo!);

    _writeIosImageSet(
      Directory(p.join(assets, 'LaunchImage.imageset')),
      'LaunchImage',
      light: logo,
      dark: darkLogo,
      render: (image, scale) => ImageUtils.fitInside(
        image,
        _iosLogoPoints * scale,
        _iosLogoPoints * scale,
      ),
    );

    if (s.branding != null) {
      _writeIosImageSet(
        Directory(p.join(assets, 'BrandingImage.imageset')),
        'BrandingImage',
        light: s.branding!,
        dark: s.darkBranding,
        render: (image, scale) => ImageUtils.fitInside(
          image,
          _iosBrandingWidth * scale,
          _iosBrandingHeight * scale,
        ),
      );
    }

    if (s.darkHex != null) {
      _writeLaunchBackgroundColorSet(
        Directory(p.join(assets, 'LaunchBackground.colorset')),
        s.colorHex,
        s.darkHex!,
      );
    }

    _updateStoryboard(s);
  }

  /// Writes `<base>.png`, `<base>@2x.png`, `<base>@3x.png` (and the `Dark`
  /// variants) plus `Contents.json` into [dir].
  static void _writeIosImageSet(
    Directory dir,
    String base, {
    required img.Image light,
    required img.Image? dark,
    required img.Image Function(img.Image image, int scale) render,
  }) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    String fileName(String prefix, int scale) =>
        scale == 1 ? '$prefix.png' : '$prefix@${scale}x.png';

    final entries = <Map<String, Object>>[];
    for (final scale in [1, 2, 3]) {
      final name = fileName(base, scale);
      _writePng(p.join(dir.path, name), render(light, scale));
      entries.add({
        'idiom': 'universal',
        'filename': name,
        'scale': '${scale}x',
      });
    }

    for (final scale in [1, 2, 3]) {
      final name = fileName('${base}Dark', scale);
      final path = p.join(dir.path, name);
      if (dark == null) {
        _deleteIfExists(path);
        continue;
      }
      _writePng(path, render(dark, scale));
      entries.add({
        'idiom': 'universal',
        'filename': name,
        'scale': '${scale}x',
        'appearances': [
          {'appearance': 'luminosity', 'value': 'dark'},
        ],
      });
    }

    File(p.join(dir.path, 'Contents.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'images': entries,
        'info': {'version': 1, 'author': 'flutter_rebrand_kit'},
      }),
      encoding: utf8,
    );
  }

  /// Color asset with a light and a dark value, referenced by name from the
  /// launch storyboard.
  static void _writeLaunchBackgroundColorSet(
    Directory dir,
    String lightHex,
    String darkHex,
  ) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    Map<String, Object> color(String hex) {
      final rgb = ImageUtils.parseHexColor(hex);
      String component(num value) => (value / 255).toStringAsFixed(3);
      return {
        'color-space': 'srgb',
        'components': {
          'alpha': '1.000',
          'blue': component(rgb.b),
          'green': component(rgb.g),
          'red': component(rgb.r),
        },
      };
    }

    File(p.join(dir.path, 'Contents.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'colors': [
          {'color': color(lightHex), 'idiom': 'universal'},
          {
            'appearances': [
              {'appearance': 'luminosity', 'value': 'dark'},
            ],
            'color': color(darkHex),
            'idiom': 'universal',
          },
        ],
        'info': {'author': 'xcode', 'version': 1},
      }),
      encoding: utf8,
    );
  }

  /// Applies the background color and, when configured, the branding image
  /// to `LaunchScreen.storyboard`.
  static void _updateStoryboard(_Splash s) {
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

    var content = storyboard.readAsStringSync(encoding: utf8);
    if (!content.contains('LaunchImage')) {
      Logger.warn(
        'LaunchScreen.storyboard does not reference the "LaunchImage" asset, '
        'so the generated splash logo will not be displayed.',
      );
    }

    // 1. Background color.
    final rgb = ImageUtils.parseHexColor(s.colorHex);
    final background = RegExp(
      r'(</subviews>\s*)<color key="backgroundColor"[^>]*/>',
    );
    if (!background.hasMatch(content)) {
      Logger.warn(
        'Could not find the background color in LaunchScreen.storyboard. '
        'Set the launch screen background color manually.',
      );
    } else if (s.darkHex != null) {
      content = content.replaceFirstMapped(
        background,
        (m) => '${m[1]}<color key="backgroundColor" name="LaunchBackground"/>',
      );
      content = _setNamedColor(content, 'LaunchBackground', _colorTag(rgb));
    } else {
      content = content.replaceFirstMapped(
        background,
        (m) => '${m[1]}${_colorTag(rgb, key: 'backgroundColor')}',
      );
    }

    // 2. Branding image.
    if (s.branding != null) {
      content = _injectBranding(content);
    }

    storyboard.writeAsStringSync(content, encoding: utf8);
  }

  static String _colorTag(img.ColorRgb8 rgb, {String? key}) {
    String component(num value) => (value / 255).toStringAsFixed(5);
    final keyAttribute = key == null ? '' : 'key="$key" ';
    return '<color $keyAttribute'
        'red="${component(rgb.r)}" green="${component(rgb.g)}" '
        'blue="${component(rgb.b)}" alpha="1" '
        'colorSpace="custom" customColorSpace="sRGB"/>';
  }

  /// Adds or replaces `<namedColor name="[name]">` in the storyboard's
  /// `<resources>` section.
  static String _setNamedColor(String content, String name, String colorTag) {
    final element = '<namedColor name="$name">$colorTag</namedColor>';
    final existing = RegExp(
      '<namedColor\\s+name="${RegExp.escape(name)}">[\\s\\S]*?</namedColor>',
    );
    if (existing.hasMatch(content)) {
      return content.replaceFirstMapped(existing, (_) => element);
    }
    if (content.contains('</resources>')) {
      return content.replaceFirst('</resources>', '    $element\n</resources>');
    }
    return content.replaceFirst(
      '</document>',
      '    <resources>\n        $element\n    </resources>\n</document>',
    );
  }

  /// Adds the `BrandingImage` image view and its Auto Layout constraints
  /// (centered horizontally, [_iosBrandingBottom] points above the bottom
  /// edge). Safe to run repeatedly.
  static String _injectBranding(String content) {
    final resourceImage =
        '<image name="BrandingImage" width="$_iosBrandingWidth" '
        'height="$_iosBrandingHeight"/>';

    if (content.contains('image="BrandingImage"')) {
      // Already injected: only refresh the declared size.
      final existing = RegExp(r'<image name="BrandingImage"[^>]*/>');
      return content.replaceFirstMapped(existing, (_) => resourceImage);
    }

    final rootId = RegExp(
      r'<view\s+key="view"[^>]*?\bid="([^"]+)"',
    ).firstMatch(content)?.group(1);
    final subviewsEnd = RegExp(
      r'</subviews>(?=\s*<color key="backgroundColor")',
    );
    final constraintsStart = RegExp(
      r'(</subviews>\s*<color key="backgroundColor"[^>]*/>\s*<constraints>)',
    );

    if (rootId == null ||
        !subviewsEnd.hasMatch(content) ||
        !constraintsStart.hasMatch(content)) {
      Logger.warn(
        'LaunchScreen.storyboard has an unexpected structure, so the branding '
        'image was added to the asset catalog but not to the storyboard. Add an '
        'image view for "BrandingImage" manually.',
      );
      return content;
    }

    const viewId = 'Brn-dI-mg1';
    final imageView =
        '        <imageView opaque="NO" clipsSubviews="YES" '
        'multipleTouchEnabled="YES" contentMode="center" image="BrandingImage" '
        'translatesAutoresizingMaskIntoConstraints="NO" id="$viewId"/>\n    ';
    final constraints =
        '\n            <constraint firstItem="$viewId" firstAttribute="centerX" '
        'secondItem="$rootId" secondAttribute="centerX" id="Brn-cX-001"/>'
        '\n            <constraint firstItem="$rootId" firstAttribute="bottom" '
        'secondItem="$viewId" secondAttribute="bottom" '
        'constant="$_iosBrandingBottom" id="Brn-bT-002"/>';

    content = content.replaceFirstMapped(
      subviewsEnd,
      (_) => '$imageView</subviews>',
    );
    content = content.replaceFirstMapped(
      constraintsStart,
      (m) => '${m[1]}$constraints',
    );

    if (content.contains('</resources>')) {
      content = content.replaceFirst(
        '</resources>',
        '    $resourceImage\n</resources>',
      );
    } else {
      content = content.replaceFirst(
        '</document>',
        '    <resources>\n        $resourceImage\n    </resources>\n</document>',
      );
    }
    return content;
  }

  // ---------------------------------------------------------------------------
  // Web
  // ---------------------------------------------------------------------------

  static const String _webStyleStart =
      '<!-- rebrand_kit:splash-style:start -->';
  static const String _webStyleEnd = '<!-- rebrand_kit:splash-style:end -->';
  static const String _webBodyStart = '<!-- rebrand_kit:splash-body:start -->';
  static const String _webBodyEnd = '<!-- rebrand_kit:splash-body:end -->';

  /// Injects a CSS/HTML splash overlay into `web/index.html`. It follows the
  /// system dark mode, never blocks pointer events and removes itself on the
  /// `flutter-first-frame` event. Returns false when the page cannot be
  /// updated.
  static bool _generateWeb(_Splash s) {
    final index = File(p.join('web', 'index.html'));
    if (!index.existsSync()) {
      Logger.warn('web/index.html not found; web splash skipped.');
      return false;
    }

    final headEnd = RegExp(r'</head\s*>', caseSensitive: false);
    final bodyStart = RegExp(r'<body\b[^>]*>', caseSensitive: false);
    var content = index.readAsStringSync(encoding: utf8);
    if (!headEnd.hasMatch(content) || !bodyStart.hasMatch(content)) {
      Logger.warn(
        'web/index.html has no <head> or <body> tag; web splash skipped.',
      );
      return false;
    }

    // Images.
    final dir = p.join('web', 'splash');
    Directory(dir).createSync(recursive: true);
    _writePng(
      p.join(dir, 'splash.png'),
      ImageUtils.fitInside(ImageUtils.trimTransparent(s.logo), 288, 288),
    );
    final darkLogoPath = p.join(dir, 'splash-dark.png');
    if (s.darkLogo != null) {
      _writePng(
        darkLogoPath,
        ImageUtils.fitInside(ImageUtils.trimTransparent(s.darkLogo!), 288, 288),
      );
    } else {
      _deleteIfExists(darkLogoPath);
    }
    final brandingPath = p.join(dir, 'branding.png');
    final darkBrandingPath = p.join(dir, 'branding-dark.png');
    if (s.branding != null) {
      _writePng(brandingPath, ImageUtils.fitInside(s.branding!, 400, 160));
      if (s.darkBranding != null) {
        _writePng(
          darkBrandingPath,
          ImageUtils.fitInside(s.darkBranding!, 400, 160),
        );
      } else {
        _deleteIfExists(darkBrandingPath);
      }
    } else {
      _deleteIfExists(brandingPath);
      _deleteIfExists(darkBrandingPath);
    }

    // Remove the blocks written by a previous run.
    content = content
        .replaceAll(
          RegExp(
            '[ \\t]*${RegExp.escape(_webStyleStart)}[\\s\\S]*?'
            '${RegExp.escape(_webStyleEnd)}[ \\t]*\\r?\\n?',
          ),
          '',
        )
        .replaceAll(
          RegExp(
            '[ \\t]*${RegExp.escape(_webBodyStart)}[\\s\\S]*?'
            '${RegExp.escape(_webBodyEnd)}[ \\t]*\\r?\\n?',
          ),
          '',
        );

    final darkCss = s.darkHex == null
        ? ''
        : '''

    @media (prefers-color-scheme: dark) {
      #splash-screen { background-color: ${s.darkHex}; }
    }''';

    final style =
        '''
  $_webStyleStart
  <style id="splash-screen-style">
    #splash-screen {
      position: fixed;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      background-color: ${s.colorHex};
      z-index: 99999;
      pointer-events: none;
      user-select: none;
      -webkit-user-select: none;
      transition: opacity 0.3s ease-out;
    }
    #splash-screen.splash-hidden { opacity: 0; }
    #splash-screen img {
      pointer-events: none;
      user-select: none;
      -webkit-user-select: none;
      -webkit-user-drag: none;
    }
    #splash-screen .splash-logo { width: 144px; max-width: 50vw; height: auto; }
    #splash-screen .splash-branding {
      position: absolute;
      bottom: 32px;
      left: 50%;
      transform: translateX(-50%);
      width: 200px;
      max-width: 60vw;
      height: auto;
    }$darkCss
  </style>
  $_webStyleEnd
''';

    String picture(String cssClass, String light, String? dark) {
      final source = dark == null
          ? ''
          : '<source media="(prefers-color-scheme: dark)" srcset="$dark">';
      return '<picture>$source<img class="$cssClass" src="$light" alt=""></picture>';
    }

    final logoHtml = picture(
      'splash-logo',
      'splash/splash.png',
      s.darkLogo != null ? 'splash/splash-dark.png' : null,
    );
    final brandingHtml = s.branding == null
        ? ''
        : '\n    ${picture('splash-branding', 'splash/branding.png', s.darkBranding != null ? 'splash/branding-dark.png' : null)}';

    final body =
        '''
  $_webBodyStart
  <div id="splash-screen">
    $logoHtml$brandingHtml
  </div>
  <script id="splash-screen-script">
    window.addEventListener("flutter-first-frame", function () {
      var splash = document.getElementById("splash-screen");
      if (!splash) return;
      splash.classList.add("splash-hidden");
      setTimeout(function () { splash.remove(); }, 350);
    });
  </script>
  $_webBodyEnd''';

    content = content.replaceFirstMapped(headEnd, (m) => '$style${m[0]}');
    content = content.replaceFirstMapped(bodyStart, (m) => '${m[0]}\n$body');

    index.writeAsStringSync(content, encoding: utf8);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static void _writePng(String path, img.Image image) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(image));
  }

  static void _writeText(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content, encoding: utf8);
  }

  static void _deleteIfExists(String path) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }
}
