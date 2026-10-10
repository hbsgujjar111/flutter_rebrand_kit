// Fixture-based tests for flutter_rebrand_kit 1.2.0.
//
// Every test builds a tiny Flutter-like project inside a temporary directory,
// switches the working directory to it (the tool works on paths relative to
// the project root) and asserts on the files the tool produced.
//
// Run with:  flutter test        (or: dart test, if `test` is a dev dependency)
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_rebrand_kit/src/image_service.dart';
import 'package:flutter_rebrand_kit/src/metadata_service.dart';
import 'package:flutter_rebrand_kit/src/splash/splash_service.dart';
import 'package:flutter_rebrand_kit/src/utils/escapers.dart';
import 'package:flutter_rebrand_kit/src/utils/image_utils.dart';
import 'package:flutter_rebrand_kit/src/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

late Directory _originalDirectory;
late Directory _project;

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

void write(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String read(String path) => File(path).readAsStringSync();

bool fileExists(String path) => File(path).existsSync();

bool dirExists(String path) => Directory(path).existsSync();

Map<String, String> snapshot(String directory) {
  final result = <String, String>{};
  final root = Directory(directory);
  if (!root.existsSync()) return result;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File) result[entity.path] = entity.readAsStringSync();
  }
  return result;
}

img.Image decode(String path) {
  final image = img.decodePng(File(path).readAsBytesSync());
  expect(image, isNotNull, reason: '$path should be a valid PNG');
  return image!;
}

/// Writes a transparent PNG with a red disc to `logo.png`.
void writeLogo({int width = 256, int height = 256}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  final radius = math.min(width, height) / 3;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final dx = x - width / 2;
      final dy = y - height / 2;
      if (math.sqrt(dx * dx + dy * dy) < radius) {
        image.setPixelRgba(x, y, 220, 20, 60, 255);
      }
    }
  }
  File('logo.png').writeAsBytesSync(img.encodePng(image));
}

/// Writes a fully opaque PNG (no transparency) to `opaque.png`.
void writeOpaqueLogo() {
  final image = img.Image(width: 128, height: 128);
  img.fill(image, color: img.ColorRgb8(10, 120, 200));
  File('opaque.png').writeAsBytesSync(img.encodePng(image));
}

// -----------------------------------------------------------------------------
// Fixtures
// -----------------------------------------------------------------------------

const String _manifest = r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">
    <application
        android:label="app"
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity" android:label="Main Screen" />
    </application>
</manifest>
''';

void androidProject({String package = 'com.example.app'}) {
  write('android/app/src/main/AndroidManifest.xml', _manifest);
  final packagePath = package.replaceAll('.', '/');
  write(
    'android/app/src/main/kotlin/$packagePath/MainActivity.kt',
    'package $package\n\n'
        'import $package.utils.Helper\n'
        'import io.flutter.embedding.android.FlutterActivity\n\n'
        'class MainActivity : FlutterActivity()\n',
  );
  write(
    'android/app/src/main/kotlin/$packagePath/utils/Helper.kt',
    'package $package.utils\n\nclass Helper\n',
  );
  write(
    'android/app/src/main/kotlin/org/other/Other.kt',
    'package org.other\n\nclass Other\n',
  );
  write(
    'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
    'package io.flutter.plugins;\n\npublic class GeneratedPluginRegistrant {}\n',
  );
}

void groovyGradle({String package = 'com.example.app'}) {
  write('android/app/build.gradle', '''
android {
    namespace "$package"
    defaultConfig {
        // applicationId "com.commented.out"
        applicationId "$package"
        minSdkVersion 21
    }
    flavorDimensions "env"
    productFlavors {
        dev {
            dimension "env"
            applicationId "$package.dev"
        }
    }
}
''');
}

void iosProject() {
  write('ios/Runner/Info.plist', '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>CFBundleDisplayName</key>
\t<string>Runner</string>
\t<key>CFBundleName</key>
\t<string>runner</string>
</dict>
</plist>
''');
  write('ios/Runner.xcodeproj/project.pbxproj', r'''
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app.RunnerTests;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app.ShareExtension;
				PRODUCT_BUNDLE_IDENTIFIER = "$(PRODUCT_BUNDLE_IDENTIFIER).Variable";
''');
}

void macosProject() {
  write(
    'macos/Runner/Configs/AppInfo.xcconfig',
    'PRODUCT_NAME = app\n'
        'PRODUCT_BUNDLE_IDENTIFIER = com.example.app\n'
        'PRODUCT_COPYRIGHT = Copyright\n',
  );
  write(
    'macos/Runner.xcodeproj/project.pbxproj',
    '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.app.RunnerTests;\n'
        '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.app.RunnerTests;\n',
  );
}

void webProject() {
  write(
    'web/index.html',
    '<html><head><title>app</title>\n'
        '<meta name="apple-mobile-web-app-title" content="app">\n'
        '</head></html>\n',
  );
  write(
    'web/manifest.json',
    '{"name": "app", "short_name": "app", "icons": []}',
  );
}

void windowsProject() {
  write(
    'windows/runner/main.cpp',
    'if (!window.CreateAndShow(L"app", origin, size)) {\n  return 1;\n}\n',
  );
  write('windows/runner/Runner.rc', r'''
      VALUE "FileDescription", "app" "\0"
      VALUE "InternalName", "app" "\0"
      VALUE "OriginalFilename", "app.exe" "\0"
      VALUE "ProductName", "app" "\0"
''');
  write('windows/CMakeLists.txt', 'set(BINARY_NAME "app")\n');
}

void linuxProject() {
  write(
    'linux/runner/my_application.cc',
    'gtk_header_bar_set_title(header_bar, "app");\n'
        'gtk_window_set_title(window, "app");\n',
  );
  write('linux/CMakeLists.txt', 'set(APPLICATION_ID "com.example.app")\n');
}

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

void main() {
  setUp(() {
    _originalDirectory = Directory.current;
    _project = Directory.systemTemp.createTempSync('rebrand_kit_test_');
    Directory.current = _project;
  });

  tearDown(() {
    Directory.current = _originalDirectory;
    _project.deleteSync(recursive: true);
  });

  group('Validators and parsing', () {
    test('package IDs', () {
      Validators.packageId('com.company.app');
      Validators.packageId('com.company.my_app2');
      for (final bad in [
        'myapp',
        'com..app',
        'com.1abc.app',
        'com.my-company.app',
        'com.company.',
      ]) {
        expect(() => Validators.packageId(bad), throwsException, reason: bad);
      }
    });

    test('versions', () {
      Validators.version('1.0.0');
      Validators.version('1.2.0+15');
      for (final bad in ['1.0', 'abc', '1.0.0+', 'v1.0.0']) {
        expect(() => Validators.version(bad), throwsException, reason: bad);
      }
    });

    test('notification icon names', () {
      expect(
        Validators.resourceName('ic_stat_notification'),
        'ic_stat_notification',
      );
      expect(Validators.resourceName('ic_stat.png'), 'ic_stat');
      expect(() => Validators.resourceName('IC-Bad'), throwsException);
    });

    test('hex colors', () {
      expect(ImageUtils.normalizeHex('#fff'), '#FFFFFF');
      expect(ImageUtils.normalizeHex('abcdef'), '#ABCDEF');
      expect(ImageUtils.parseHexColor('#1E1E2E').r, 30);
      expect(() => ImageUtils.normalizeHex('#12345'), throwsException);
      expect(() => ImageUtils.normalizeHex('blue'), throwsException);
    });

    test('escapers', () {
      expect(
        Escapers.xml('Tom & "Jerry" <3'),
        'Tom &amp; &quot;Jerry&quot; &lt;3',
      );
      expect(Escapers.cString('say "hi"'), r'say \"hi\"');
      expect(Escapers.rcString('say "hi"'), 'say ""hi""');
      expect(Escapers.cppWideString('Café 日本'), r'Caf\u00e9 \u65e5\u672c');
      expect(Escapers.cppWideString('😀'), r'\U0001f600');
      expect(jsonDecode('"${Escapers.json('a"b\\c')}"'), 'a"b\\c');
    });

    test('non-square master images are padded, not stretched', () {
      writeLogo(width: 300, height: 200);
      final image = ImageUtils.loadAndValidateIcon('logo.png');
      expect(image.width, 300);
      expect(image.height, 300);
      expect(image.numChannels, 4);
    });

    test('transparency detection', () {
      writeLogo();
      writeOpaqueLogo();
      expect(
        ImageUtils.hasTransparency(ImageUtils.loadAndValidateIcon('logo.png')),
        isTrue,
      );
      expect(
        ImageUtils.hasTransparency(
          ImageUtils.loadAndValidateIcon('opaque.png'),
        ),
        isFalse,
      );
    });
  });

  group('App name', () {
    const name = 'Tom & "Jerry" <3';

    test('is escaped for every platform file format', () {
      androidProject();
      iosProject();
      macosProject();
      webProject();
      windowsProject();
      linuxProject();

      MetadataService.updateAppName(name);

      // Android: only <application> is changed, the activity label is kept.
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains('android:label="Tom &amp; &quot;Jerry&quot; &lt;3"'),
      );
      expect(manifest, contains('android:label="Main Screen"'));

      // iOS.
      final plist = read('ios/Runner/Info.plist');
      expect(
        plist,
        contains('<string>Tom &amp; &quot;Jerry&quot; &lt;3</string>'),
      );

      // macOS.
      expect(
        read('macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_NAME = $name'),
      );

      // Web.
      expect(
        read('web/index.html'),
        contains('<title>Tom &amp; &quot;Jerry&quot; &lt;3</title>'),
      );
      final webManifest =
          jsonDecode(read('web/manifest.json')) as Map<String, dynamic>;
      expect(webManifest['name'], name);
      expect(webManifest['short_name'], name);

      // Windows.
      expect(
        read('windows/runner/main.cpp'),
        contains(r'window.CreateAndShow(L"Tom & \"Jerry\" <3"'),
      );
      final rc = read('windows/runner/Runner.rc');
      expect(
        rc,
        contains(r'VALUE "FileDescription", "Tom & ""Jerry"" <3" "\0"'),
      );
      expect(rc, contains(r'VALUE "ProductName", "Tom & ""Jerry"" <3" "\0"'));

      // Linux.
      final linux = read('linux/runner/my_application.cc');
      expect(
        linux,
        contains(r'gtk_window_set_title(window, "Tom & \"Jerry\" <3");'),
      );
      expect(
        linux,
        contains(
          r'gtk_header_bar_set_title(header_bar, "Tom & \"Jerry\" <3");',
        ),
      );
    });

    test('Windows keeps window.Create vs window.CreateAndShow', () {
      write('windows/runner/main.cpp', 'window.Create(L"a", origin, size);\n');
      MetadataService.updateAppName('Shop');
      expect(
        read('windows/runner/main.cpp'),
        contains('window.Create(L"Shop"'),
      );

      write(
        'windows/runner/main.cpp',
        'window.CreateAndShow(L"a", origin, size);\n',
      );
      MetadataService.updateAppName('Shop');
      expect(
        read('windows/runner/main.cpp'),
        contains('window.CreateAndShow(L"Shop"'),
      );
    });

    test('iOS inserts CFBundleDisplayName when it is missing', () {
      write(
        'ios/Runner/Info.plist',
        '<plist><dict>\n\t<key>CFBundleName</key>\n\t<string>x</string>\n</dict></plist>\n',
      );
      MetadataService.updateAppName('Shop');
      final plist = read('ios/Runner/Info.plist');
      expect(plist, contains('<key>CFBundleDisplayName</key>'));
      expect(plist, contains('<string>Shop</string>'));
    });
  });

  group('Package ID', () {
    test('rejects invalid IDs before touching any file', () {
      androidProject();
      groovyGradle();
      final before = read('android/app/build.gradle');
      expect(() => MetadataService.updatePackageId('myapp'), throwsException);
      expect(read('android/app/build.gradle'), before);
    });

    test(
      'Groovy Gradle: only defaultConfig changes, flavors and comments stay',
      () {
        androidProject();
        groovyGradle();
        MetadataService.updatePackageId('com.acme.shop');

        final gradle = read('android/app/build.gradle');
        expect(gradle, contains('namespace "com.acme.shop"'));
        expect(gradle, contains('        applicationId "com.acme.shop"'));
        expect(gradle, contains('// applicationId "com.commented.out"'));
        expect(gradle, contains('applicationId "com.example.app.dev"'));
      },
    );

    test('Kotlin DSL and "=" syntax are supported', () {
      androidProject();
      write('android/app/build.gradle.kts', '''
android {
    namespace = "com.example.app"
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''');
      MetadataService.updatePackageId('com.acme.shop');

      final gradle = read('android/app/build.gradle.kts');
      expect(gradle, contains('namespace = "com.acme.shop"'));
      expect(gradle, contains('applicationId = "com.acme.shop"'));
    });

    test('Groovy Gradle with "=" assignments is supported', () {
      androidProject();
      write('android/app/build.gradle', '''
android {
    namespace = "com.example.app"
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''');
      MetadataService.updatePackageId('com.acme.shop');
      final gradle = read('android/app/build.gradle');
      expect(gradle, contains('namespace = "com.acme.shop"'));
      expect(gradle, contains('applicationId = "com.acme.shop"'));
    });

    test('migrates the Kotlin tree, imports and manifest', () {
      androidProject();
      groovyGradle();
      write(
        'android/app/src/debug/AndroidManifest.xml',
        '<manifest package="com.example.app"></manifest>',
      );

      MetadataService.updatePackageId('com.acme.shop');

      const root = 'android/app/src/main/kotlin';
      final activity = read('$root/com/acme/shop/MainActivity.kt');
      expect(activity, contains('package com.acme.shop\n'));
      expect(activity, contains('import com.acme.shop.utils.Helper'));
      expect(
        activity,
        contains('import io.flutter.embedding.android.FlutterActivity'),
      );
      expect(
        read('$root/com/acme/shop/utils/Helper.kt'),
        contains('package com.acme.shop.utils'),
      );

      // Old folders are pruned, unrelated code is untouched.
      expect(dirExists('$root/com/example'), isFalse);
      expect(fileExists('$root/org/other/Other.kt'), isTrue);
      expect(read('$root/org/other/Other.kt'), contains('package org.other'));

      // Flutter engine files stay where they are, unchanged.
      final registrant = read(
        'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
      );
      expect(registrant, contains('package io.flutter.plugins;'));

      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        contains('package="com.acme.shop"'),
      );
      expect(
        read('android/app/src/debug/AndroidManifest.xml'),
        contains('package="com.acme.shop"'),
      );
    });

    test('a package whose path contains "io/flutter" is still migrated', () {
      // "com/studio/flutterapp" contains the substring "io/flutter".
      androidProject(package: 'com.studio.flutterapp');
      groovyGradle(package: 'com.studio.flutterapp');

      MetadataService.updatePackageId('com.acme.shop');

      const root = 'android/app/src/main/kotlin';
      expect(fileExists('$root/com/acme/shop/MainActivity.kt'), isTrue);
      expect(dirExists('$root/com/studio'), isFalse);
    });

    test('detects the base package even without Gradle hints', () {
      androidProject();
      write(
        'android/app/src/main/AndroidManifest.xml',
        '<manifest></manifest>',
      );

      MetadataService.updatePackageId('com.acme.shop');

      const root = 'android/app/src/main/kotlin';
      expect(fileExists('$root/com/acme/shop/MainActivity.kt'), isTrue);
      expect(fileExists('$root/com/acme/shop/utils/Helper.kt'), isTrue);
    });

    test('is idempotent', () {
      androidProject();
      groovyGradle();
      iosProject();
      macosProject();
      windowsProject();
      linuxProject();

      MetadataService.updatePackageId('com.acme.shop');
      final first = [
        snapshot('android/app/src/main/kotlin'),
        read('android/app/build.gradle'),
        read('android/app/src/main/AndroidManifest.xml'),
        read('ios/Runner.xcodeproj/project.pbxproj'),
        read('macos/Runner.xcodeproj/project.pbxproj'),
        read('windows/runner/Runner.rc'),
      ];

      MetadataService.updatePackageId('com.acme.shop');
      final second = [
        snapshot('android/app/src/main/kotlin'),
        read('android/app/build.gradle'),
        read('android/app/src/main/AndroidManifest.xml'),
        read('ios/Runner.xcodeproj/project.pbxproj'),
        read('macos/Runner.xcodeproj/project.pbxproj'),
        read('windows/runner/Runner.rc'),
      ];

      expect(second, first);
    });

    test(
      'iOS: tests and extensions keep their suffix, variables are untouched',
      () {
        iosProject();
        MetadataService.updatePackageId('com.acme.shop');

        final pbxproj = read('ios/Runner.xcodeproj/project.pbxproj');
        expect(
          'PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop;'
              .allMatches(pbxproj)
              .length,
          2,
        );
        expect(
          pbxproj,
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop.RunnerTests;'),
        );
        expect(
          pbxproj,
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop.ShareExtension;'),
        );
        expect(pbxproj, contains(r'"$(PRODUCT_BUNDLE_IDENTIFIER).Variable"'));
      },
    );

    test(
      'iOS: an ID containing "widget" or "extension" is not mistaken for a target',
      () {
        iosProject();
        MetadataService.updatePackageId('com.acme.widgetstore');
        MetadataService.updatePackageId('com.acme.widgetstore');

        final pbxproj = read('ios/Runner.xcodeproj/project.pbxproj');
        expect(pbxproj, isNot(contains('com.acme.widgetstore.widgetstore')));
        expect(
          pbxproj,
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.widgetstore;'),
        );
        expect(
          pbxproj,
          contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.acme.widgetstore.RunnerTests;',
          ),
        );
      },
    );

    test('macOS: the test target keeps its suffix', () {
      macosProject();
      MetadataService.updatePackageId('com.acme.shop');

      expect(
        read('macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop\n'),
      );
      final pbxproj = read('macos/Runner.xcodeproj/project.pbxproj');
      expect(
        pbxproj,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop.RunnerTests;'),
      );
      expect(
        pbxproj,
        isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.shop;')),
      );
    });

    test('Windows and Linux metadata', () {
      windowsProject();
      linuxProject();
      MetadataService.updatePackageId('com.acme.shop');

      expect(
        read('windows/CMakeLists.txt'),
        contains('set(BINARY_NAME "shop")'),
      );
      final rc = read('windows/runner/Runner.rc');
      expect(rc, contains(r'VALUE "InternalName", "shop" "\0"'));
      expect(rc, contains(r'VALUE "OriginalFilename", "shop.exe" "\0"'));
      expect(
        read('linux/CMakeLists.txt'),
        contains('set(APPLICATION_ID "com.acme.shop")'),
      );
    });
  });

  group('Version', () {
    test('updates pubspec.yaml and rejects invalid versions', () {
      write('pubspec.yaml', 'name: demo\nversion: 1.0.0+1\n');
      MetadataService.updateVersion('2.3.4+7');
      expect(read('pubspec.yaml'), contains('version: 2.3.4+7'));
      expect(() => MetadataService.updateVersion('2.3'), throwsException);
    });
  });

  group('Launcher icons', () {
    void allPlatforms() {
      write(
        'android/app/src/main/AndroidManifest.xml',
        '<manifest>\n<application android:label="a">\n</application>\n</manifest>\n',
      );
      Directory('ios').createSync();
      Directory('macos').createSync();
      write('web/index.html', '<html></html>');
      Directory('windows').createSync();
      Directory('linux').createSync();
    }

    test('generates every platform and skips missing ones', () {
      writeLogo();
      write('android/app/src/main/AndroidManifest.xml', _manifest);
      final generated = ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );
      expect(generated, ['Android']);
      expect(dirExists('ios'), isFalse);
      expect(dirExists('macos'), isFalse);
      expect(dirExists('windows'), isFalse);
      expect(dirExists('linux'), isFalse);
    });

    test(
      'Android: round icons are circular and the manifest references them',
      () {
        writeLogo();
        allPlatforms();
        final generated = ImageService.generateLauncherIcons(
          iconPath: 'logo.png',
          bgColorHex: '#112233',
        );
        expect(generated, [
          'Android',
          'iOS',
          'macOS',
          'Web',
          'Windows',
          'Linux',
        ]);

        const res = 'android/app/src/main/res';
        final square = decode('$res/mipmap-xxxhdpi/ic_launcher.png');
        final round = decode('$res/mipmap-xxxhdpi/ic_launcher_round.png');
        expect(square.width, 192);
        expect(round.width, 192);
        expect(
          round.getPixel(0, 0).a,
          0,
          reason: 'corner of the round icon is transparent',
        );
        expect(round.getPixel(96, 96).a, 255);
        expect(square.numChannels, 3, reason: 'square icon stays opaque (RGB)');

        expect(
          decode('$res/mipmap-xxxhdpi/ic_launcher_foreground.png').width,
          432,
        );
        expect(
          fileExists('$res/mipmap-xxhdpi/ic_launcher_monochrome.png'),
          isTrue,
        );
        expect(fileExists('$res/mipmap-anydpi-v26/ic_launcher.xml'), isTrue);
        expect(
          fileExists('$res/mipmap-anydpi-v26/ic_launcher_round.xml'),
          isTrue,
        );

        final manifest = read('android/app/src/main/AndroidManifest.xml');
        expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
        expect(
          manifest,
          contains('android:roundIcon="@mipmap/ic_launcher_round"'),
        );
      },
    );

    test('Android: the adaptive background color follows config changes', () {
      writeLogo();
      write('android/app/src/main/AndroidManifest.xml', _manifest);
      write(
        'android/app/src/main/res/values/colors.xml',
        '<resources><color name="brand">#000000</color></resources>',
      );

      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );
      var colors = read('android/app/src/main/res/values/colors.xml');
      expect(
        colors,
        contains('<color name="ic_launcher_background">#112233</color>'),
      );
      expect(colors, contains('<color name="brand">#000000</color>'));

      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#445566',
      );
      colors = read('android/app/src/main/res/values/colors.xml');
      expect(
        colors,
        contains('<color name="ic_launcher_background">#445566</color>'),
      );
      expect(colors, isNot(contains('#112233')));
      expect(colors, contains('<color name="brand">#000000</color>'));
    });

    test('Android: a self-closing <resources/> colors.xml is handled', () {
      writeLogo();
      write('android/app/src/main/AndroidManifest.xml', _manifest);
      write('android/app/src/main/res/values/colors.xml', '<resources />');
      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );
      expect(
        read('android/app/src/main/res/values/colors.xml'),
        contains('<color name="ic_launcher_background">#112233</color>'),
      );
    });

    test(
      'iOS: standard catalog is complete, opaque, and has Dark and Tinted',
      () {
        writeLogo();
        allPlatforms();
        ImageService.generateLauncherIcons(
          iconPath: 'logo.png',
          bgColorHex: '#112233',
        );

        const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
        final contents =
            jsonDecode(read('$dir/Contents.json')) as Map<String, dynamic>;
        final images = (contents['images'] as List)
            .cast<Map<String, dynamic>>();

        for (final image in images) {
          expect(
            fileExists('$dir/${image['filename']}'),
            isTrue,
            reason: '${image['filename']} is referenced but missing',
          );
        }

        // Required slots.
        bool has(String idiom, String size, String scale) => images.any(
          (i) =>
              i['idiom'] == idiom && i['size'] == size && i['scale'] == scale,
        );
        expect(has('iphone', '60x60', '3x'), isTrue);
        expect(has('iphone', '20x20', '2x'), isTrue);
        expect(has('ipad', '20x20', '1x'), isTrue);
        expect(has('ipad', '29x29', '1x'), isTrue);
        expect(has('ipad', '40x40', '1x'), isTrue);
        expect(has('ipad', '76x76', '1x'), isTrue);
        expect(has('ipad', '83.5x83.5', '2x'), isTrue);
        expect(has('ios-marketing', '1024x1024', '1x'), isTrue);

        // Dark and Tinted appearances.
        String? appearanceOf(Map<String, dynamic> image) {
          final list = image['appearances'] as List?;
          return list == null ? null : (list.first as Map)['value'] as String;
        }

        expect(images.where((i) => appearanceOf(i) == 'dark').length, 1);
        expect(images.where((i) => appearanceOf(i) == 'tinted').length, 1);

        // Sizes are exact and light icons carry no alpha channel (App Store).
        final light = decode('$dir/Icon-App-60x60@3x.png');
        expect(light.width, 180);
        expect(light.numChannels, 3);
        expect(decode('$dir/Icon-App-83.5x83.5@2x.png').width, 167);
        expect(decode('$dir/Icon-App-Dark-1024x1024@1x.png').width, 1024);
        expect(decode('$dir/Icon-App-Tinted-1024x1024@1x.png').width, 1024);
      },
    );

    test('iOS: stale catalog files from older runs are removed', () {
      writeLogo();
      allPlatforms();
      const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      write('$dir/Icon-App-38x38@2x.png', 'stale');
      write('$dir/Icon-App-Dark-60x60@3x.png', 'stale');
      write('$dir/my-own-file.txt', 'keep');

      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );

      expect(fileExists('$dir/Icon-App-38x38@2x.png'), isFalse);
      expect(fileExists('$dir/Icon-App-Dark-60x60@3x.png'), isFalse);
      expect(fileExists('$dir/my-own-file.txt'), isTrue);
    });

    test('macOS, Web and Linux outputs', () {
      writeLogo();
      allPlatforms();
      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );

      const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
      final contents =
          jsonDecode(read('$mac/Contents.json')) as Map<String, dynamic>;
      for (final image
          in (contents['images'] as List).cast<Map<String, dynamic>>()) {
        expect(fileExists('$mac/${image['filename']}'), isTrue);
      }
      expect(decode('$mac/app_icon_1024.png').width, 1024);

      expect(decode('web/favicon.png').width, 32);
      expect(decode('web/icons/Icon-192.png').width, 192);
      expect(decode('web/icons/Icon-512.png').width, 512);
      expect(decode('web/icons/Icon-maskable-192.png').width, 192);
      expect(decode('web/icons/Icon-maskable-512.png').width, 512);

      expect(decode('linux/runner/assets/app_icon.png').width, 256);
    });

    test('Windows: valid multi-resolution .ico with transparency', () {
      writeLogo();
      allPlatforms();
      ImageService.generateLauncherIcons(
        iconPath: 'logo.png',
        bgColorHex: '#112233',
      );

      final bytes = File(
        'windows/runner/resources/app_icon.ico',
      ).readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      expect(data.getUint16(0, Endian.little), 0, reason: 'reserved');
      expect(data.getUint16(2, Endian.little), 1, reason: 'type: icon');
      final count = data.getUint16(4, Endian.little);
      expect(count, 4);

      final widths = <int>[];
      for (int i = 0; i < count; i++) {
        final entry = 6 + i * 16;
        widths.add(data.getUint8(entry));
        final size = data.getUint32(entry + 8, Endian.little);
        final offset = data.getUint32(entry + 12, Endian.little);
        expect(offset + size <= bytes.length, isTrue);
        expect(bytes.sublist(offset, offset + 4), [0x89, 0x50, 0x4E, 0x47]);
      }
      expect(widths, [16, 32, 48, 0], reason: '0 means 256 px');

      // The largest frame keeps the transparent corners of the master image.
      final lastEntry = 6 + 3 * 16;
      final size = data.getUint32(lastEntry + 8, Endian.little);
      final offset = data.getUint32(lastEntry + 12, Endian.little);
      final frame = img.decodePng(
        Uint8List.sublistView(bytes, offset, offset + size),
      )!;
      expect(frame.width, 256);
      expect(frame.getPixel(0, 0).a, 0);
    });

    test('bad colors fail with a clear error', () {
      writeLogo();
      write('android/app/src/main/AndroidManifest.xml', _manifest);
      expect(
        () => ImageService.generateLauncherIcons(
          iconPath: 'logo.png',
          bgColorHex: 'blue',
        ),
        throwsException,
      );
    });
  });

  group('Notification icons', () {
    test('white silhouettes, all densities, stale default removed', () {
      writeLogo();
      write(
        'android/app/src/main/res/drawable-mdpi/ic_notification.png',
        'stale',
      );

      final generated = ImageService.generateNotificationIcons(
        'logo.png',
        iconName: 'ic_stat_notification',
      );
      expect(generated, isTrue);

      const res = 'android/app/src/main/res';
      const sizes = {
        'drawable-mdpi': 24,
        'drawable-hdpi': 36,
        'drawable-xhdpi': 48,
        'drawable-xxhdpi': 72,
        'drawable-xxxhdpi': 96,
      };
      sizes.forEach((folder, size) {
        final icon = decode('$res/$folder/ic_stat_notification.png');
        expect(icon.width, size);
        expect(icon.height, size);
      });

      final xxxhdpi = decode('$res/drawable-xxxhdpi/ic_stat_notification.png');
      final center = xxxhdpi.getPixel(48, 48);
      expect([center.r, center.g, center.b, center.a], [255, 255, 255, 255]);
      expect(xxxhdpi.getPixel(0, 0).a, 0);

      expect(fileExists('$res/drawable-mdpi/ic_notification.png'), isFalse);
    });

    test('does nothing without an android/ folder and rejects bad names', () {
      writeLogo();
      expect(ImageService.generateNotificationIcons('logo.png'), isFalse);
      expect(dirExists('android'), isFalse);

      Directory('android').createSync();
      expect(
        () => ImageService.generateNotificationIcons(
          'logo.png',
          iconName: 'IC-Bad',
        ),
        throwsException,
      );
    });
  });

  group('Native splash', () {
    const storyboard = r'''
<document>
  <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
    <subviews>
      <imageView image="LaunchImage" id="YRO-k0-Ey4"/>
    </subviews>
    <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
  </view>
</document>
''';

    test('Android: density assets, drawable-v21 and merged Android 12 styles', () {
      writeLogo();
      const res = 'android/app/src/main/res';
      write('$res/drawable/splash_logo.png', 'stale single-density asset');
      write(
        '$res/drawable-v21/launch_background.xml',
        '<layer-list><item android:drawable="?android:colorBackground"/></layer-list>',
      );
      write(
        '$res/values/colors.xml',
        '<resources><color name="brand">#000000</color><color name="splash_color">#ABCDEF</color></resources>',
      );
      write('$res/values-v31/styles.xml', '''
<resources>
    <style name="Other" parent="x"><item name="a">b</item></style>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
    </style>
</resources>
''');

      final platforms = SplashService.generateNativeSplash(
        'logo.png',
        '#1E1E2E',
      );
      expect(platforms, ['Android']);

      // Density-specific assets (288dp canvas).
      expect(decode('$res/drawable-mdpi/splash_logo.png').width, 288);
      expect(decode('$res/drawable-xhdpi/splash_logo.png').width, 576);
      expect(decode('$res/drawable-xxxhdpi/splash_logo.png').width, 1152);
      expect(fileExists('$res/drawable/splash_logo.png'), isFalse);

      // The file that wins on API 21+ is updated.
      expect(
        read('$res/drawable-v21/launch_background.xml'),
        contains('@color/splash_color'),
      );
      expect(
        read('$res/drawable/launch_background.xml'),
        contains('@drawable/splash_logo'),
      );

      // colors.xml: the entry is replaced, other colors are kept.
      final colors = read('$res/values/colors.xml');
      expect(colors, contains('<color name="splash_color">#1E1E2E</color>'));
      expect(colors, isNot(contains('#ABCDEF')));
      expect(colors, contains('<color name="brand">#000000</color>'));

      // values-v31/styles.xml is merged, not replaced.
      final styles = read('$res/values-v31/styles.xml');
      expect(styles, contains('<style name="Other"'));
      expect(styles, contains('android:forceDarkAllowed'));
      expect(styles, contains('android:windowSplashScreenBackground'));
      expect(styles, contains('android:windowSplashScreenAnimatedIcon'));

      // Running again does not duplicate items.
      SplashService.generateNativeSplash('logo.png', '#1E1E2E');
      final again = read('$res/values-v31/styles.xml');
      expect('windowSplashScreenBackground'.allMatches(again).length, 1);
    });

    test('iOS: scaled launch images and storyboard background color', () {
      writeLogo();
      write('ios/Runner/Base.lproj/LaunchScreen.storyboard', storyboard);

      final platforms = SplashService.generateNativeSplash(
        'logo.png',
        '#1E1E2E',
      );
      expect(platforms, ['iOS']);

      const set = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
      expect(decode('$set/LaunchImage.png').width, 150);
      expect(decode('$set/LaunchImage@2x.png').width, 300);
      expect(decode('$set/LaunchImage@3x.png').width, 450);

      final updated = read('ios/Runner/Base.lproj/LaunchScreen.storyboard');
      expect(updated, contains('red="0.11765" green="0.11765" blue="0.18039"'));
      expect(updated, isNot(contains('red="1" green="1" blue="1"')));
    });

    test('does nothing without android/ or ios/', () {
      writeLogo();
      expect(
        SplashService.generateNativeSplash('logo.png', '#FFFFFF'),
        isEmpty,
      );
      expect(dirExists('android'), isFalse);
      expect(dirExists('ios'), isFalse);
    });
  });
}
