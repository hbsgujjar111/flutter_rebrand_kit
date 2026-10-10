import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/escapers.dart';

/// Renamer service for Web index.html and PWA manifest.json.
class WebRenamer {
  WebRenamer._();

  /// Updates page title and mobile meta tags in `index.html`, and `name`/`short_name` in `manifest.json`.
  static void updateAppName(String name) {
    final indexHtml = File(p.join('web', 'index.html'));
    if (indexHtml.existsSync()) {
      final html = Escapers.xml(name);
      final content = indexHtml
          .readAsStringSync(encoding: utf8)
          .replaceAllMapped(
            RegExp(r'<title>[^<]*</title>'),
            (_) => '<title>$html</title>',
          )
          .replaceAllMapped(
            RegExp(
              r'(<meta\s+name="apple-mobile-web-app-title"\s+content=")[^"]*(")',
            ),
            (m) => '${m[1]}$html${m[2]}',
          );
      indexHtml.writeAsStringSync(content, encoding: utf8);
    }

    final manifest = File(p.join('web', 'manifest.json'));
    if (manifest.existsSync()) {
      final json = Escapers.json(name);
      final content = manifest
          .readAsStringSync(encoding: utf8)
          .replaceFirstMapped(
            RegExp(r'("name"\s*:\s*")[^"]*(")'),
            (m) => '${m[1]}$json${m[2]}',
          )
          .replaceFirstMapped(
            RegExp(r'("short_name"\s*:\s*")[^"]*(")'),
            (m) => '${m[1]}$json${m[2]}',
          );
      manifest.writeAsStringSync(content, encoding: utf8);
    }
  }
}
