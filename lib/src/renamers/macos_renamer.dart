import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Renamer service for macOS AppInfo.xcconfig and Xcode project configurations.
class MacOsRenamer {
  MacOsRenamer._();

  /// Updates PRODUCT_NAME in `macos/Runner/Configs/AppInfo.xcconfig`.
  static void updateAppName(String name) {
    final appInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (!appInfo.existsSync()) return;

    var content = appInfo.readAsStringSync(encoding: utf8);
    content = content.replaceAll(
      RegExp(r'^PRODUCT_NAME\s*=\s*.*$', multiLine: true),
      'PRODUCT_NAME = $name',
    );
    appInfo.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates PRODUCT_BUNDLE_IDENTIFIER in `AppInfo.xcconfig` and `project.pbxproj`.
  static void updatePackageId(String newId) {
    final appInfo = File(
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
    );
    if (appInfo.existsSync()) {
      var content = appInfo.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*$', multiLine: true),
        'PRODUCT_BUNDLE_IDENTIFIER = $newId',
      );
      appInfo.writeAsStringSync(content, encoding: utf8);
    }

    final pbxproj = File(
      p.join('macos', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    if (pbxproj.existsSync()) {
      var content = pbxproj.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
        'PRODUCT_BUNDLE_IDENTIFIER = $newId;',
      );
      pbxproj.writeAsStringSync(content, encoding: utf8);
    }
  }
}
