import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Renamer service for Linux GTK runner and CMake project configuration.
class LinuxRenamer {
  LinuxRenamer._();

  /// Updates window title, GTK HeaderBar title, and runtime icon linkage in `my_application.cc`.
  static void updateAppName(String name) {
    final runnerApp = File(p.join('linux', 'runner', 'my_application.cc'));
    final fallbackApp = File(p.join('linux', 'my_application.cc'));

    final targetFile = runnerApp.existsSync()
        ? runnerApp
        : (fallbackApp.existsSync() ? fallbackApp : null);
    if (targetFile == null) return;

    var content = targetFile.readAsStringSync(encoding: utf8);

    // 1. Update window title
    content = content.replaceAll(
      RegExp(r'gtk_window_set_title\(window,\s*"[^"]*"\);'),
      'gtk_window_set_title(window, "$name");',
    );

    // 2. Update GTK HeaderBar title
    content = content.replaceAll(
      RegExp(r'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"\);'),
      'gtk_header_bar_set_title(header_bar, "$name");',
    );

    // 3. Inject runtime icon loader if not present
    if (!content.contains('gtk_window_set_icon_from_file')) {
      const iconSnippet = '''
  gtk_window_set_icon_from_file(window, "assets/app_icon.png", nullptr);
  gtk_window_set_default_size(window, 1280, 720);''';
      content = content.replaceAll(
        'gtk_window_set_default_size(window, 1280, 720);',
        iconSnippet,
      );
    }

    targetFile.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates APPLICATION_ID and BINARY_NAME in `linux/CMakeLists.txt`.
  static void updatePackageId(String newId) {
    final cmake = File(p.join('linux', 'CMakeLists.txt'));
    if (!cmake.existsSync()) return;

    final sanitizedBinary = newId.split('.').last;
    var content = cmake.readAsStringSync(encoding: utf8);

    content = content.replaceAll(
      RegExp(r'set\(APPLICATION_ID\s+"[^"]*"\)'),
      'set(APPLICATION_ID "$newId")',
    );
    content = content.replaceAll(
      RegExp(r'set\(BINARY_NAME\s+"[^"]*"\)'),
      'set(BINARY_NAME "$sanitizedBinary")',
    );

    cmake.writeAsStringSync(content, encoding: utf8);
  }
}
