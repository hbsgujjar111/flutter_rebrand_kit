import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Renamer service for Web index.html and PWA manifest.json.
class WebRenamer {
  WebRenamer._();

  /// Updates page title and mobile meta tags in `index.html`, and `name`/`short_name` in `manifest.json`.
  static void updateAppName(String name) {
    final indexHtml = File(p.join('web', 'index.html'));
    if (indexHtml.existsSync()) {
      var content = indexHtml.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'<title>[^<]*</title>'),
        '<title>$name</title>',
      );
      content = content.replaceAll(
        RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
        '<meta name="apple-mobile-web-app-title" content="$name">',
      );
      indexHtml.writeAsStringSync(content, encoding: utf8);
    }

    final manifest = File(p.join('web', 'manifest.json'));
    if (manifest.existsSync()) {
      var content = manifest.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'"name":\s*"[^"]*"'),
        '"name": "$name"',
      );
      content = content.replaceAll(
        RegExp(r'"short_name":\s*"[^"]*"'),
        '"short_name": "$name"',
      );
      manifest.writeAsStringSync(content, encoding: utf8);
    }
  }
}
