import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/bundle_id_rewriter.dart';
import '../utils/escapers.dart';

/// Renamer service for iOS Info.plist and Xcode project configurations.
class IosRenamer {
  IosRenamer._();

  /// Updates CFBundleDisplayName and CFBundleName in `ios/Runner/Info.plist`.
  ///
  /// The name is XML-escaped, so titles such as "Tom & Jerry" stay valid.
  static void updateAppName(String name) {
    final plist = File(p.join('ios', 'Runner', 'Info.plist'));
    if (!plist.existsSync()) return;

    final escaped = Escapers.xml(name);
    var content = plist.readAsStringSync(encoding: utf8);
    content = _setPlistString(
      content,
      'CFBundleDisplayName',
      escaped,
      insertIfMissing: true,
    );
    content = _setPlistString(
      content,
      'CFBundleName',
      escaped,
      insertIfMissing: false,
    );
    plist.writeAsStringSync(content, encoding: utf8);
  }

  static String _setPlistString(
    String content,
    String key,
    String value, {
    required bool insertIfMissing,
  }) {
    final existing = RegExp('<key>$key</key>\\s*<string>[^<]*</string>');
    if (existing.hasMatch(content)) {
      return content.replaceFirstMapped(
        existing,
        (_) => '<key>$key</key>\n\t<string>$value</string>',
      );
    }
    if (insertIfMissing) {
      return content.replaceFirstMapped(
        '<dict>',
        (_) => '<dict>\n\t<key>$key</key>\n\t<string>$value</string>',
      );
    }
    return content;
  }

  /// Updates PRODUCT_BUNDLE_IDENTIFIER in `ios/Runner.xcodeproj/project.pbxproj`.
  ///
  /// Identifiers that are the main ID plus a suffix (tests, extensions,
  /// widgets) keep their suffix. See [BundleIdRewriter].
  static void updatePackageId(String newId) {
    final pbxproj = File(p.join('ios', 'Runner.xcodeproj', 'project.pbxproj'));
    if (!pbxproj.existsSync()) return;

    final original = pbxproj.readAsStringSync(encoding: utf8);
    final updated = BundleIdRewriter.rewrite(original, newId);
    if (updated != original) {
      pbxproj.writeAsStringSync(updated, encoding: utf8);
    }
  }
}
