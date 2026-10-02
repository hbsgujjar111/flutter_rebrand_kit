import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Renamer service for iOS Info.plist and Xcode project configurations.
class IosRenamer {
  IosRenamer._();

  /// Updates CFBundleDisplayName and CFBundleName in `ios/Runner/Info.plist`.
  static void updateAppName(String name) {
    final plist = File(p.join('ios', 'Runner', 'Info.plist'));
    if (!plist.existsSync()) return;

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

  /// Updates PRODUCT_BUNDLE_IDENTIFIER in `ios/Runner.xcodeproj/project.pbxproj` while preserving extension targets.
  static void updatePackageId(String newId) {
    final pbxproj = File(p.join('ios', 'Runner.xcodeproj', 'project.pbxproj'));
    if (!pbxproj.existsSync()) return;

    var content = pbxproj.readAsStringSync(encoding: utf8);
    content = content.replaceAllMapped(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);'),
      (match) {
        final currentId = match.group(1)!.trim();
        final lastPart = currentId.split('.').last;
        if (lastPart == 'RunnerTests' ||
            lastPart.toLowerCase().contains('extension') ||
            lastPart.toLowerCase().contains('widget')) {
          return 'PRODUCT_BUNDLE_IDENTIFIER = $newId.$lastPart;';
        }
        return 'PRODUCT_BUNDLE_IDENTIFIER = $newId;';
      },
    );
    pbxproj.writeAsStringSync(content, encoding: utf8);
  }
}
