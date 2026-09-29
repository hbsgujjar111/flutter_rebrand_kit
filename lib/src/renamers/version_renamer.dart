import 'dart:convert';
import 'dart:io';

/// Renamer service for updating app version and build numbers in `pubspec.yaml`.
class VersionRenamer {
  VersionRenamer._();

  /// Updates the `version:` field in `pubspec.yaml`.
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
}
