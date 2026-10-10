import 'dart:convert';
import 'dart:io';

import '../utils/logger.dart';
import '../utils/validators.dart';

/// Renamer service for updating app version and build numbers in `pubspec.yaml`.
class VersionRenamer {
  VersionRenamer._();

  /// Updates the `version:` field in `pubspec.yaml`.
  ///
  /// Throws when [version] is not `x.y.z` or `x.y.z+build`.
  static void updateVersion(String version) {
    Validators.version(version);

    final file = File('pubspec.yaml');
    if (!file.existsSync()) return;

    final versionLine = RegExp(r'^version:\s*.*$', multiLine: true);
    final original = file.readAsStringSync(encoding: utf8);
    if (!versionLine.hasMatch(original)) {
      Logger.warn(
        'No "version:" line found in pubspec.yaml; version not updated.',
      );
      return;
    }

    final updated = original.replaceFirstMapped(
      versionLine,
      (_) => 'version: $version',
    );
    file.writeAsStringSync(updated, encoding: utf8);
  }
}
