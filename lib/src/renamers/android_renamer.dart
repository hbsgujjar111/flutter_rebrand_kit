import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Renamer service for Android manifests, Gradle build scripts, and source tree migration.
class AndroidRenamer {
  AndroidRenamer._();

  /// Updates the application label in `AndroidManifest.xml` with XML entity escaping.
  static void updateAppName(String name) {
    final manifest = File(
      p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    );
    if (!manifest.existsSync()) return;

    var content = manifest.readAsStringSync(encoding: utf8);
    final escapedName = name.replaceAll('&', '&amp;');
    content = content.replaceAll(
      RegExp(r'android:label="[^"]*"'),
      'android:label="$escapedName"',
    );
    manifest.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates the package ID in build scripts and executes full-tree Kotlin/Java migration.
  static void updatePackageId(String newId) {
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

    _migrateFullAndroidPackageTree(newId);
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

      for (final entity in root.listSync(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.kt') || entity.path.endsWith('.java'))) {
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
          (match) => 'package $newId${match.group(1) ?? ''}',
        );

        content = content.replaceAllMapped(
          RegExp(
            r'^\s*import\s+' +
                RegExp.escape(oldPackageBase) +
                r'(\.[a-zA-Z0-9_.*]+)?',
            multiLine: true,
          ),
          (match) => 'import $newId${match.group(1) ?? ''}',
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
