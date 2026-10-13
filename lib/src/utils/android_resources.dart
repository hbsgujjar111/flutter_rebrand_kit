import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Shared helpers for editing Android resource and manifest files without
/// clobbering content that belongs to the user.
class AndroidResources {
  AndroidResources._();

  static String get _mainDir => p.join('android', 'app', 'src', 'main');

  /// Sets `<color name="[name]">[hex]</color>` in `res/[valuesFolder]/colors.xml`
  /// (`values` by default, `values-night` for dark mode colors).
  ///
  /// Updates the entry when it already exists, otherwise inserts it, and keeps
  /// every other color in the file. Handles `<resources/>` self-closing files.
  static void setColor(
    String name,
    String hex, {
    String valuesFolder = 'values',
  }) {
    final valuesDir = Directory(p.join(_mainDir, 'res', valuesFolder));
    if (!valuesDir.existsSync()) {
      valuesDir.createSync(recursive: true);
    }

    final file = File(p.join(valuesDir.path, 'colors.xml'));
    var content = file.existsSync()
        ? file.readAsStringSync(encoding: utf8)
        : '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n';

    final entry = '<color name="$name">$hex</color>';
    final existing = RegExp(
      '<color\\s+name="${RegExp.escape(name)}"\\s*>[^<]*</color>',
    );
    final selfClosing = RegExp(r'<resources\b([^>]*?)\s*/>');

    if (existing.hasMatch(content)) {
      content = content.replaceFirstMapped(existing, (_) => entry);
    } else if (selfClosing.hasMatch(content)) {
      content = content.replaceFirstMapped(
        selfClosing,
        (m) => '<resources${m[1]}>\n    $entry\n</resources>',
      );
    } else if (content.contains('</resources>')) {
      content = content.replaceFirst(
        '</resources>',
        '    $entry\n</resources>',
      );
    } else {
      throw Exception(
        'Unable to update colors.xml: no <resources> element was found.',
      );
    }

    file.writeAsStringSync(content, encoding: utf8);
  }

  /// Removes `<color name="[name]">` from `res/[valuesFolder]/colors.xml`
  /// when present. Other colors are kept.
  static void removeColor(String name, {String valuesFolder = 'values'}) {
    final file = File(p.join(_mainDir, 'res', valuesFolder, 'colors.xml'));
    if (!file.existsSync()) return;

    final content = file.readAsStringSync(encoding: utf8);
    final entry = RegExp(
      '[ \\t]*<color\\s+name="${RegExp.escape(name)}"\\s*>[^<]*</color>[ \\t]*\\r?\\n?',
    );
    if (!entry.hasMatch(content)) return;
    file.writeAsStringSync(content.replaceFirst(entry, ''), encoding: utf8);
  }

  /// Makes sure `<application>` references the generated launcher icons.
  ///
  /// Adds `android:icon` and `android:roundIcon` only when they are missing;
  /// existing values are never overwritten.
  static void ensureLauncherIconReferences() {
    final manifest = File(p.join(_mainDir, 'AndroidManifest.xml'));
    if (!manifest.existsSync()) return;

    var content = manifest.readAsStringSync(encoding: utf8);
    final match = RegExp(r'<application\b[^>]*>').firstMatch(content);
    if (match == null) return;

    final original = match.group(0)!;
    var tag = original;
    if (!tag.contains('android:icon=')) {
      tag = tag.replaceFirst(
        '<application',
        '<application android:icon="@mipmap/ic_launcher"',
      );
    }
    if (!tag.contains('android:roundIcon=')) {
      tag = tag.replaceFirst(
        '<application',
        '<application android:roundIcon="@mipmap/ic_launcher_round"',
      );
    }

    if (tag != original) {
      content = content.replaceRange(match.start, match.end, tag);
      manifest.writeAsStringSync(content, encoding: utf8);
    }
  }
}
