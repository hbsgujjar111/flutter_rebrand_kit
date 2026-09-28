import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Service for updating manifest files, package IDs, and app labels across all platforms.
class MetadataService {
  MetadataService._();

  /// Updates version and build number in `pubspec.yaml`.
  static void updateVersion(String version) {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync(encoding: utf8);
    content = content.replaceFirst(
      RegExp(r'^version:\s*.*$', multiLine: true),
      'version: $version',
    );
    file.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates app name across Android, iOS, macOS, Web, Windows, and Linux.
  static void updateAppName(String name) {
    // 1. Android (AndroidManifest.xml)
    final manifest = File(
      p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    );
    if (manifest.existsSync()) {
      var content = manifest.readAsStringSync(encoding: utf8);
      final escapedName = name.replaceAll('&', '&amp;'); // <-- Safeguard
      content = content.replaceAll(
        RegExp(r'android:label="[^"]*"'),
        'android:label="$escapedName"',
      );
      manifest.writeAsStringSync(content, encoding: utf8);
    }

    // 2. iOS (Info.plist)
    final plist = File(p.join('ios', 'Runner', 'Info.plist'));
    if (plist.existsSync()) {
      var content = plist.readAsStringSync(encoding: utf8);
      if (content.contains('<key>CFBundleDisplayName</key>')) {
        content = content.replaceAll(
          RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'),
          '<key>CFBundleDisplayName</key>\n\t<string>$name</string>',
        );
      } else {
        content = content.replaceFirst(
          '<dict>',
          '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>$name</string>',
        );
      }

      if (content.contains('<key>CFBundleName</key>')) {
        content = content.replaceAll(
          RegExp(r'<key>CFBundleName</key>\s*<string>[^<]*</string>'),
          '<key>CFBundleName</key>\n\t<string>$name</string>',
        );
      }
      plist.writeAsStringSync(content, encoding: utf8);
    }

    // 3. macOS (AppInfo.xcconfig)
    final macAppInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (macAppInfo.existsSync()) {
      var content = macAppInfo.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'^PRODUCT_NAME\s*=\s*.*$', multiLine: true),
        'PRODUCT_NAME = $name',
      );
      macAppInfo.writeAsStringSync(content, encoding: utf8);
    }

    // 4. Web (index.html & manifest.json)
    final webIndex = File(p.join('web', 'index.html'));
    if (webIndex.existsSync()) {
      var content = webIndex.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'<title>[^<]*</title>'),
        '<title>$name</title>',
      );
      content = content.replaceAll(
        RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
        '<meta name="apple-mobile-web-app-title" content="$name">',
      );
      webIndex.writeAsStringSync(content, encoding: utf8);
    }

    final webManifest = File(p.join('web', 'manifest.json'));
    if (webManifest.existsSync()) {
      var content = webManifest.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'"name":\s*"[^"]*"'),
        '"name": "$name"',
      );
      content = content.replaceAll(
        RegExp(r'"short_name":\s*"[^"]*"'),
        '"short_name": "$name"',
      );
      webManifest.writeAsStringSync(content, encoding: utf8);
    }

    // 5. Windows (main.cpp & Runner.rc)
    final winMain = File(p.join('windows', 'runner', 'main.cpp'));
    if (winMain.existsSync()) {
      var content = winMain.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'window\.Create(AndShow)?\(L"[^"]*"'),
        'window.Create(L"$name"',
      );
      winMain.writeAsStringSync(content, encoding: utf8);
    }

    final winRc = File(p.join('windows', 'runner', 'Runner.rc'));
    if (winRc.existsSync()) {
      var content = winRc.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'VALUE "FileDescription", "[^"]*"'),
        'VALUE "FileDescription", "$name"',
      );
      content = content.replaceAll(
        RegExp(r'VALUE "ProductName", "[^"]*"'),
        'VALUE "ProductName", "$name"',
      );
      winRc.writeAsStringSync(content, encoding: utf8);
    }

    // 6. Linux (linux/runner/my_application.cc)
    final linuxApp = File(p.join('linux', 'runner', 'my_application.cc'));
    final fallbackLinuxApp = File(p.join('linux', 'my_application.cc'));

    final targetLinuxFile = linuxApp.existsSync()
        ? linuxApp
        : (fallbackLinuxApp.existsSync() ? fallbackLinuxApp : null);

    if (targetLinuxFile != null) {
      var content = targetLinuxFile.readAsStringSync(encoding: utf8);
      // Updates standard window title
      content = content.replaceAll(
        RegExp(r'gtk_window_set_title\(window,\s*"[^"]*"\);'),
        'gtk_window_set_title(window, "$name");',
      );
      // Updates GTK HeaderBar title
      content = content.replaceAll(
        RegExp(r'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"\);'),
        'gtk_header_bar_set_title(header_bar, "$name");',
      );
      targetLinuxFile.writeAsStringSync(content, encoding: utf8);
    }
  }

  /// Updates package/bundle ID across Android, iOS, macOS, Windows, and Linux.
  static void updatePackageId(String newId) {
    // 1. Android build.gradle (Groovy & Kotlin DSL)
    final groovyGradle = File(p.join('android', 'app', 'build.gradle'));
    if (groovyGradle.existsSync()) {
      var content = groovyGradle.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'applicationId\s+["\x27][^"\x27]+["\x27]'),
        'applicationId "$newId"',
      );
      content = content.replaceAll(
        RegExp(r'namespace\s+["\x27][^"\x27]+["\x27]'),
        'namespace "$newId"',
      );
      groovyGradle.writeAsStringSync(content, encoding: utf8);
    }

    final ktsGradle = File(p.join('android', 'app', 'build.gradle.kts'));
    if (ktsGradle.existsSync()) {
      var content = ktsGradle.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'applicationId\s*=\s*["\x27][^"\x27]+["\x27]'),
        'applicationId = "$newId"',
      );
      content = content.replaceAll(
        RegExp(r'namespace\s*=\s*["\x27][^"\x27]+["\x27]'),
        'namespace = "$newId"',
      );
      ktsGradle.writeAsStringSync(content, encoding: utf8);
    }

    // 2. Android Full-Tree File & Folder Migration
    _migrateFullAndroidPackageTree(newId);

    // 3. iOS (project.pbxproj)
    final iosPbxproj = File(
      p.join('ios', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    if (iosPbxproj.existsSync()) {
      var content = iosPbxproj.readAsStringSync(encoding: utf8);
      content = content.replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);'),
        (match) {
          final currentId = match.group(1)!.trim();
          final lastPart = currentId.split('.').last;
          if (lastPart == 'RunnerTests' ||
              lastPart.toLowerCase().contains('extension') ||
              lastPart.toLowerCase().contains('widget')) {
            return 'PRODUCT_BUNDLE_IDENTIFIER = $newId.$lastPart;'; // <-- Keeps extension distinct
          }
          return 'PRODUCT_BUNDLE_IDENTIFIER = $newId;';
        },
      );
      iosPbxproj.writeAsStringSync(content, encoding: utf8);
    }

    // 4. macOS (AppInfo.xcconfig & project.pbxproj)
    final macAppInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (macAppInfo.existsSync()) {
      var content = macAppInfo.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*$', multiLine: true),
        'PRODUCT_BUNDLE_IDENTIFIER = $newId',
      );
      macAppInfo.writeAsStringSync(content, encoding: utf8);
    }

    final macPbxproj = File(
      p.join('macos', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    if (macPbxproj.existsSync()) {
      var content = macPbxproj.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
        'PRODUCT_BUNDLE_IDENTIFIER = $newId;',
      );
      macPbxproj.writeAsStringSync(content, encoding: utf8);
    }

    // 5. Linux (CMakeLists.txt)
    final linuxCMake = File(p.join('linux', 'CMakeLists.txt'));
    if (linuxCMake.existsSync()) {
      var content = linuxCMake.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'set\(APPLICATION_ID\s+"[^"]*"\)'),
        'set(APPLICATION_ID "$newId")',
      );
      linuxCMake.writeAsStringSync(content, encoding: utf8);
    }

    // 6. Windows (CMakeLists.txt binary target name)
    final winCMake = File(p.join('windows', 'CMakeLists.txt'));
    if (winCMake.existsSync()) {
      final sanitizedBinary = newId.split('.').last;
      var content = winCMake.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'set\(BINARY_NAME\s+"[^"]*"\)'),
        'set(BINARY_NAME "$sanitizedBinary")',
      );
      winCMake.writeAsStringSync(content, encoding: utf8);
    }
  }

  static void _migrateFullAndroidPackageTree(String newId) {
    final mainDir = Directory(p.join('android', 'app', 'src', 'main'));
    if (!mainDir.existsSync()) return;

    final sourceRoots = [
      Directory(p.join(mainDir.path, 'kotlin')),
      Directory(p.join(mainDir.path, 'java')),
    ];

    String? detectedOldPackage;

    for (final root in sourceRoots) {
      if (!root.existsSync()) continue;

      final sourceFiles = <File>[];

      // ---> THIS IS THE LOOP <---
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.kt') || entity.path.endsWith('.java'))) {
          // Never touch Flutter engine generated registrant files
          final normalized = p.normalize(entity.path);
          if (normalized.contains(p.join('io', 'flutter'))) {
            continue;
          }

          sourceFiles.add(entity);

          if (detectedOldPackage == null) {
            final content = entity.readAsStringSync(encoding: utf8);
            final match = RegExp(
              r'^\s*package\s+([a-zA-Z0-9_.]+)',
              multiLine: true,
            ).firstMatch(content);
            if (match != null && !match.group(1)!.startsWith('io.flutter')) {
              detectedOldPackage = match.group(1);
            }
          }
        }
      }

      if (sourceFiles.isEmpty || detectedOldPackage == null) continue;

      final oldPackageBase = detectedOldPackage;
      final oldSubPath = oldPackageBase.replaceAll('.', Platform.pathSeparator);
      final newSubPath = newId.replaceAll('.', Platform.pathSeparator);

      for (final file in sourceFiles) {
        var content = file.readAsStringSync(encoding: utf8);

        content = content.replaceAllMapped(
          RegExp(
            r'^\s*package\s+' +
                RegExp.escape(oldPackageBase) +
                r'(\.[a-zA-Z0-9_.]+)?',
            multiLine: true,
          ),
          (match) {
            final sub = match.group(1) ?? '';
            return 'package $newId$sub';
          },
        );

        content = content.replaceAllMapped(
          RegExp(
            r'^\s*import\s+' +
                RegExp.escape(oldPackageBase) +
                r'(\.[a-zA-Z0-9_.*]+)?',
            multiLine: true,
          ),
          (match) {
            final sub = match.group(1) ?? '';
            return 'import $newId$sub';
          },
        );

        final normalizedFilePath = p.normalize(file.path);
        final oldPackageDirPath = p.normalize(p.join(root.path, oldSubPath));

        String targetFilePath;
        if (normalizedFilePath.startsWith(oldPackageDirPath)) {
          final relativeToOldPackage = p.relative(
            normalizedFilePath,
            from: oldPackageDirPath,
          );
          targetFilePath = p.join(root.path, newSubPath, relativeToOldPackage);
        } else {
          targetFilePath = p.join(root.path, newSubPath, p.basename(file.path));
        }

        final targetFile = File(targetFilePath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(content, encoding: utf8);

        if (p.normalize(p.absolute(file.path)) !=
            p.normalize(p.absolute(targetFile.path))) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
      }

      final oldDir = Directory(p.join(root.path, oldSubPath));
      if (oldDir.existsSync()) {
        _pruneEmptyDirectories(oldDir, root);
      }
    }

    final manifest = File(p.join(mainDir.path, 'AndroidManifest.xml'));
    if (manifest.existsSync() && detectedOldPackage != null) {
      var content = manifest.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        'package="$detectedOldPackage"',
        'package="$newId"',
      );
      content = content.replaceAll('"$detectedOldPackage.', '"$newId.');
      manifest.writeAsStringSync(content, encoding: utf8);
    }
  }

  static void _pruneEmptyDirectories(Directory dir, Directory boundary) {
    if (p.normalize(p.absolute(dir.path)) ==
        p.normalize(p.absolute(boundary.path))) {
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
