import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/escapers.dart';

/// Renamer service for Android manifests, Gradle build scripts, and source tree migration.
class AndroidRenamer {
  AndroidRenamer._();

  static final RegExp _packageDeclaration = RegExp(
    r'^[ \t]*package[ \t]+([A-Za-z0-9_.]+)',
    multiLine: true,
  );

  /// Updates the application label in `AndroidManifest.xml`.
  ///
  /// Only the `<application>` element is changed (activity labels are left
  /// alone) and the name is XML-escaped.
  static void updateAppName(String name) {
    final manifest = File(
      p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    );
    if (!manifest.existsSync()) return;

    var content = manifest.readAsStringSync(encoding: utf8);
    final match = RegExp(r'<application\b[^>]*>').firstMatch(content);
    if (match == null) return;

    final escaped = Escapers.xml(name);
    final label = RegExp(r'android:label\s*=\s*"[^"]*"');
    final original = match.group(0)!;
    final tag = label.hasMatch(original)
        ? original.replaceFirstMapped(label, (_) => 'android:label="$escaped"')
        : original.replaceFirst(
            '<application',
            '<application android:label="$escaped"',
          );

    content = content.replaceRange(match.start, match.end, tag);
    manifest.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates the package ID in build scripts and migrates the Kotlin/Java tree.
  ///
  /// Only the first `applicationId` / `namespace` assignment is rewritten
  /// (the `defaultConfig` one in a standard project), so product flavors that
  /// declare their own IDs keep them.
  static void updatePackageId(String newId) {
    // Read the current values before the build scripts are modified.
    final oldNamespace = _readGradleValue('namespace');
    final oldApplicationId = _readGradleValue('applicationId');
    final oldManifestPackage = _readManifestPackage();

    for (final name in ['build.gradle', 'build.gradle.kts']) {
      final file = File(p.join('android', 'app', name));
      if (!file.existsSync()) continue;

      var content = file.readAsStringSync(encoding: utf8);
      content = _setGradleValue(content, 'applicationId', newId);
      content = _setGradleValue(content, 'namespace', newId);
      file.writeAsStringSync(content, encoding: utf8);
    }

    final hints = <String>[
      ?oldNamespace,
      ?oldApplicationId,
      ?oldManifestPackage,
    ];

    final detectedBase = _migrateSourceTree(newId, hints);
    final oldBase =
        detectedBase ?? oldManifestPackage ?? oldNamespace ?? oldApplicationId;
    _updateManifestPackages(newId, oldBase);
  }

  // ---------------------------------------------------------------------------
  // Gradle helpers
  // ---------------------------------------------------------------------------

  /// Matches `applicationId "x"`, `applicationId = "x"` and `namespace = 'x'`
  /// at the start of a line (commented-out lines are ignored).
  static RegExp _gradleAssignment(String key) {
    return RegExp(
      r'(^[ \t]*' + key + r'\s*=?\s*)(["\x27])([^"\x27\n]+)\2',
      multiLine: true,
    );
  }

  static String? _readGradleValue(String key) {
    for (final name in ['build.gradle.kts', 'build.gradle']) {
      final file = File(p.join('android', 'app', name));
      if (!file.existsSync()) continue;

      final match = _gradleAssignment(
        key,
      ).firstMatch(file.readAsStringSync(encoding: utf8));
      if (match != null) return match.group(3);
    }
    return null;
  }

  static String _setGradleValue(String content, String key, String value) {
    return content.replaceFirstMapped(
      _gradleAssignment(key),
      (m) => '${m[1]}${m[2]}$value${m[2]}',
    );
  }

  static String? _readManifestPackage() {
    final manifest = File(
      p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    );
    if (!manifest.existsSync()) return null;

    final match = RegExp(
      r'<manifest\b[^>]*?\bpackage\s*=\s*"([^"]*)"',
    ).firstMatch(manifest.readAsStringSync(encoding: utf8));
    return match?.group(1);
  }

  // ---------------------------------------------------------------------------
  // Source tree migration
  // ---------------------------------------------------------------------------

  /// Moves Kotlin/Java sources into the folder of [newId] and rewrites
  /// `package` and `import` lines. Returns the old base package, or null when
  /// there was nothing to migrate.
  static String? _migrateSourceTree(String newId, List<String> hints) {
    final mainDir = Directory(p.join('android', 'app', 'src', 'main'));
    if (!mainDir.existsSync()) return null;

    final entries = <_SourceEntry>[];
    for (final rootName in ['kotlin', 'java']) {
      final root = Directory(p.join(mainDir.path, rootName));
      if (!root.existsSync()) continue;

      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.kt') && !entity.path.endsWith('.java')) {
          continue;
        }
        if (_isFlutterEngineFile(entity.path, root.path)) continue;

        final content = entity.readAsStringSync(encoding: utf8);
        final match = _packageDeclaration.firstMatch(content);
        if (match == null) continue;

        final package = match.group(1)!;
        if (package == 'io.flutter' || package.startsWith('io.flutter.')) {
          continue;
        }
        entries.add(_SourceEntry(root, entity, content, package));
      }
    }

    final base = _detectBasePackage(entries, hints);
    if (base == null) return null;

    final newSubPath = newId.replaceAll('.', p.separator);
    final directoriesToPrune = <String, String>{};

    for (final entry in entries) {
      final inBase =
          entry.package == base || entry.package.startsWith('$base.');
      if (!inBase) continue; // Never touch code from unrelated packages.

      final content = _rewriteDeclarations(entry.content, base, newId);
      final subPackage = entry.package.length > base.length
          ? entry.package
                .substring(base.length + 1)
                .replaceAll('.', p.separator)
          : '';
      final targetPath = p.join(
        entry.root.path,
        newSubPath,
        subPackage,
        p.basename(entry.file.path),
      );

      final samePath =
          p.canonicalize(entry.file.path) == p.canonicalize(targetPath);
      if (samePath && content == entry.content) continue;

      final target = File(targetPath);
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(content, encoding: utf8);

      if (!samePath) {
        try {
          entry.file.deleteSync();
        } catch (_) {}
        directoriesToPrune[entry.file.parent.path] = entry.root.path;
      }
    }

    directoriesToPrune.forEach((directory, rootPath) {
      _pruneEmptyDirectories(Directory(directory), Directory(rootPath));
    });

    return base;
  }

  /// Files under `<root>/io/flutter/` belong to the Flutter engine
  /// (for example `GeneratedPluginRegistrant.java`) and must not be moved.
  static bool _isFlutterEngineFile(String filePath, String rootPath) {
    final segments = p.split(p.relative(filePath, from: rootPath));
    return segments.length >= 2 &&
        segments[0] == 'io' &&
        segments[1] == 'flutter';
  }

  /// Finds the application's base package.
  ///
  /// 1. The package that matches the current `namespace`, `applicationId` or
  ///    manifest `package`.
  /// 2. The package of the file that declares the app's entry point
  ///    (`MainActivity`, `FlutterActivity`, `FlutterApplication`).
  /// 3. The shortest declared package.
  static String? _detectBasePackage(
    List<_SourceEntry> entries,
    List<String> hints,
  ) {
    if (entries.isEmpty) return null;

    final packages = entries.map((e) => e.package).toSet();
    for (final hint in hints) {
      if (packages.contains(hint) ||
          packages.any((package) => package.startsWith('$hint.'))) {
        return hint;
      }
    }

    final entryPoint = RegExp(
      r'\b(FlutterActivity|FlutterFragmentActivity|FlutterApplication)\b|class\s+MainActivity\b',
    );
    final entryPackages =
        entries
            .where((e) => entryPoint.hasMatch(e.content))
            .map((e) => e.package)
            .toList()
          ..sort((a, b) => a.length.compareTo(b.length));
    if (entryPackages.isNotEmpty) return entryPackages.first;

    final sorted = packages.toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    return sorted.first;
  }

  static String _rewriteDeclarations(
    String content,
    String base,
    String newId,
  ) {
    final escapedBase = RegExp.escape(base);

    final packagePattern = RegExp(
      r'^([ \t]*package[ \t]+)' +
          escapedBase +
          r'((?:\.[A-Za-z0-9_]+)*)(?![A-Za-z0-9_])',
      multiLine: true,
    );
    final importPattern = RegExp(
      r'^([ \t]*import[ \t]+(?:static[ \t]+)?)' +
          escapedBase +
          r'((?:\.[A-Za-z0-9_*]+)*)(?![A-Za-z0-9_])',
      multiLine: true,
    );

    return content
        .replaceAllMapped(packagePattern, (m) => '${m[1]}$newId${m[2]}')
        .replaceAllMapped(importPattern, (m) => '${m[1]}$newId${m[2]}');
  }

  /// Updates `package="..."` and fully qualified class names in the main,
  /// debug and profile manifests.
  static void _updateManifestPackages(String newId, String? oldBase) {
    for (final variant in ['main', 'debug', 'profile']) {
      final manifest = File(
        p.join('android', 'app', 'src', variant, 'AndroidManifest.xml'),
      );
      if (!manifest.existsSync()) continue;

      final original = manifest.readAsStringSync(encoding: utf8);
      var content = original.replaceFirstMapped(
        RegExp(r'(<manifest\b[^>]*?\bpackage\s*=\s*")[^"]*(")'),
        (m) => '${m[1]}$newId${m[2]}',
      );
      if (oldBase != null && oldBase != newId) {
        content = content.replaceAll('"$oldBase.', '"$newId.');
      }

      if (content != original) {
        manifest.writeAsStringSync(content, encoding: utf8);
      }
    }
  }

  static void _pruneEmptyDirectories(Directory dir, Directory boundary) {
    if (p.canonicalize(dir.path) == p.canonicalize(boundary.path)) return;
    if (dir.existsSync() && dir.listSync().isEmpty) {
      final parent = dir.parent;
      try {
        dir.deleteSync();
      } catch (_) {}
      _pruneEmptyDirectories(parent, boundary);
    }
  }
}

class _SourceEntry {
  _SourceEntry(this.root, this.file, this.content, this.package);

  final Directory root;
  final File file;
  final String content;
  final String package;
}
