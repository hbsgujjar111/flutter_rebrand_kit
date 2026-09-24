import 'dart:io';

import 'package:path/path.dart' as p;

import 'logger.dart';

class MetadataService {
  static void updateVersion(String version) {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    content = content.replaceFirst(RegExp(r'^version:\s*.*$', multiLine: true), 'version: $version');
    file.writeAsStringSync(content);
  }

  static void updateAppName(String name) {
    // 1. Android Manifest
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    if (manifest.existsSync()) {
      var content = manifest.readAsStringSync();
      content = content.replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="$name"');
      manifest.writeAsStringSync(content);
    }

    // 2. iOS Info.plist
    final plist = File('ios/Runner/Info.plist');
    if (plist.existsSync()) {
      var content = plist.readAsStringSync();

      if (content.contains('<key>CFBundleDisplayName</key>')) {
        content = content.replaceAll(
          RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'),
          '<key>CFBundleDisplayName</key>\n\t<string>$name</string>',
        );
      } else {
        content = content.replaceFirst('<dict>', '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>$name</string>');
      }

      if (content.contains('<key>CFBundleName</key>')) {
        content = content.replaceAll(
          RegExp(r'<key>CFBundleName</key>\s*<string>[^<]*</string>'),
          '<key>CFBundleName</key>\n\t<string>$name</string>',
        );
      }
      plist.writeAsStringSync(content);
    }

    // 3. Web
    final webIndex = File('web/index.html');
    if (webIndex.existsSync()) {
      var content = webIndex.readAsStringSync();
      content = content.replaceAll(RegExp(r'<title>[^<]*</title>'), '<title>$name</title>');
      content = content.replaceAll(
        RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
        '<meta name="apple-mobile-web-app-title" content="$name">',
      );
      webIndex.writeAsStringSync(content);
    }

    final webManifest = File('web/manifest.json');
    if (webManifest.existsSync()) {
      var content = webManifest.readAsStringSync();
      content = content.replaceAll(RegExp(r'"name":\s*"[^"]*"'), '"name": "$name"');
      content = content.replaceAll(RegExp(r'"short_name":\s*"[^"]*"'), '"short_name": "$name"');
      webManifest.writeAsStringSync(content);
    }

    // 4. Windows
    final winMain = File('windows/runner/main.cpp');
    if (winMain.existsSync()) {
      var content = winMain.readAsStringSync();
      content = content.replaceAll(RegExp(r'window\.Create\(L"[^"]*"'), 'window.Create(L"$name"');
      winMain.writeAsStringSync(content);
    }

    // 5. Linux
    final linuxApp = File('linux/my_application.cc');
    if (linuxApp.existsSync()) {
      var content = linuxApp.readAsStringSync();
      content = content.replaceAll(
        RegExp(r'gtk_window_set_title\(window,\s*"[^"]*"\);'),
        'gtk_window_set_title(window, "$name");',
      );
      linuxApp.writeAsStringSync(content);
    }
  }

  static void updatePackageId(String newId) {
    // 1. Android build.gradle (Groovy)
    final groovyGradle = File('android/app/build.gradle');
    if (groovyGradle.existsSync()) {
      var content = groovyGradle.readAsStringSync();
      content = content.replaceAll(RegExp(r'applicationId\s+["\x27][^"\x27]+["\x27]'), 'applicationId "$newId"');
      content = content.replaceAll(RegExp(r'namespace\s+["\x27][^"\x27]+["\x27]'), 'namespace "$newId"');
      groovyGradle.writeAsStringSync(content);
    }

    // 2. Android build.gradle.kts (Kotlin DSL)
    final ktsGradle = File('android/app/build.gradle.kts');
    if (ktsGradle.existsSync()) {
      var content = ktsGradle.readAsStringSync();
      content = content.replaceAll(RegExp(r'applicationId\s*=\s*["\x27][^"\x27]+["\x27]'), 'applicationId = "$newId"');
      content = content.replaceAll(RegExp(r'namespace\s*=\s*["\x27][^"\x27]+["\x27]'), 'namespace = "$newId"');
      ktsGradle.writeAsStringSync(content);
    }

    // 3. AndroidManifest.xml package attribute (if present)
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    if (manifest.existsSync()) {
      var content = manifest.readAsStringSync();
      if (content.contains('package="')) {
        content = content.replaceAll(RegExp(r'package="[^"]*"'), 'package="$newId"');
        manifest.writeAsStringSync(content);
      }
    }

    // 4. Move & Update MainActivity.kt / MainActivity.java
    _migrateMainActivityDirectory(newId);

    // 5. iOS project.pbxproj
    final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
    if (pbxproj.existsSync()) {
      var content = pbxproj.readAsStringSync();
      content = content.replaceAll(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
        'PRODUCT_BUNDLE_IDENTIFIER = $newId;',
      );
      pbxproj.writeAsStringSync(content);
    }

    // 6. Linux CMakeLists.txt
    final linuxCMake = File('linux/CMakeLists.txt');
    if (linuxCMake.existsSync()) {
      var content = linuxCMake.readAsStringSync();
      content = content.replaceAll(RegExp(r'set\(APPLICATION_ID\s+"[^"]*"\)'), 'set(APPLICATION_ID "$newId")');
      linuxCMake.writeAsStringSync(content);
    }
  }

  static void _migrateMainActivityDirectory(String newId) {
    final mainDir = Directory(p.join('android', 'app', 'src', 'main'));
    if (!mainDir.existsSync()) return;

    final activities = <File>[];
    for (final entity in mainDir.listSync(recursive: true)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name == 'MainActivity.kt' || name == 'MainActivity.java') {
          activities.add(entity);
        }
      }
    }

    if (activities.isEmpty) {
      Logger.warn('No MainActivity found under android/app/src/main');
      return;
    }

    for (final file in activities) {
      final isKotlin = file.path.endsWith('.kt');
      final langFolder = isKotlin ? 'kotlin' : 'java';
      final langRoot = Directory(p.join(mainDir.path, langFolder));

      // 1. Update package line in-place
      var content = file.readAsStringSync();
      final packageRegex = RegExp(r'^\s*package\s+.*$', multiLine: true);
      if (packageRegex.hasMatch(content)) {
        content = content.replaceFirst(packageRegex, 'package $newId');
      } else {
        content = 'package $newId\n\n$content';
      }
      file.writeAsStringSync(content);

      // 2. Prepare new folder path
      final targetSubPath = newId.replaceAll('.', Platform.pathSeparator);
      final targetDir = Directory(p.join(langRoot.path, targetSubPath));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final targetFile = File(p.join(targetDir.path, p.basename(file.path)));

      // 3. Move file if destination changed
      if (p.normalize(p.absolute(file.path)) != p.normalize(p.absolute(targetFile.path))) {
        targetFile.writeAsStringSync(content);
        final oldParent = file.parent;
        try {
          file.deleteSync();
          _pruneEmptyDirectories(oldParent, langRoot);
        } catch (_) {
          // Handles rare Windows lock edge-cases
        }
      }
    }
  }

  static void _pruneEmptyDirectories(Directory dir, Directory boundary) {
    if (p.normalize(p.absolute(dir.path)) == p.normalize(p.absolute(boundary.path))) {
      return;
    }
    if (dir.existsSync() && dir.listSync().isEmpty) {
      final parent = dir.parent;
      try {
        dir.deleteSync();
      } catch (_) {}
      _pruneEmptyDirectories(parent, boundary);
    }
  }
}
