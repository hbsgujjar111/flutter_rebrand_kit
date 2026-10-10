import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/bundle_id_rewriter.dart';

/// Renamer service for macOS AppInfo.xcconfig and Xcode project configurations.
class MacOsRenamer {
  MacOsRenamer._();

  static final RegExp _productName = RegExp(
    r'^PRODUCT_NAME\s*=\s*.*$',
    multiLine: true,
  );

  static final RegExp _bundleIdLine = RegExp(
    r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(.*)$',
    multiLine: true,
  );

  /// Updates PRODUCT_NAME in `macos/Runner/Configs/AppInfo.xcconfig`.
  static void updateAppName(String name) {
    final appInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (!appInfo.existsSync()) return;

    final content = appInfo
        .readAsStringSync(encoding: utf8)
        .replaceAllMapped(_productName, (_) => 'PRODUCT_NAME = $name');
    appInfo.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates PRODUCT_BUNDLE_IDENTIFIER in `AppInfo.xcconfig` and `project.pbxproj`.
  ///
  /// macOS keeps the main identifier in `AppInfo.xcconfig`, while the Xcode
  /// project only holds the test target (`<id>.RunnerTests`). The old main
  /// identifier is read first so the test target keeps its suffix instead of
  /// being collapsed onto the main identifier.
  static void updatePackageId(String newId) {
    String? oldBase;

    final appInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (appInfo.existsSync()) {
      final original = appInfo.readAsStringSync(encoding: utf8);
      final match = _bundleIdLine.firstMatch(original);
      oldBase = match?.group(1)?.trim();

      final updated = original.replaceAllMapped(
        _bundleIdLine,
        (_) => 'PRODUCT_BUNDLE_IDENTIFIER = $newId',
      );
      if (updated != original) {
        appInfo.writeAsStringSync(updated, encoding: utf8);
      }
    }

    final pbxproj = File(
      p.join('macos', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    if (pbxproj.existsSync()) {
      final original = pbxproj.readAsStringSync(encoding: utf8);
      final updated = BundleIdRewriter.rewrite(
        original,
        newId,
        knownOldBase: oldBase,
      );
      if (updated != original) {
        pbxproj.writeAsStringSync(updated, encoding: utf8);
      }
    }
  }
}
