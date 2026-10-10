import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/escapers.dart';

/// Renamer service for Linux GTK runner and CMake project configuration.
class LinuxRenamer {
  LinuxRenamer._();

  /// Updates standard window title and GTK HeaderBar title in `my_application.cc`.
  static void updateAppName(String name) {
    final runnerApp = File(p.join('linux', 'runner', 'my_application.cc'));
    final fallbackApp = File(p.join('linux', 'my_application.cc'));

    final targetFile = runnerApp.existsSync()
        ? runnerApp
        : (fallbackApp.existsSync() ? fallbackApp : null);
    if (targetFile == null) return;

    final escaped = Escapers.cString(name);
    final content = targetFile
        .readAsStringSync(encoding: utf8)
        .replaceAllMapped(
          RegExp(r'gtk_window_set_title\(window,\s*"[^"]*"\);'),
          (_) => 'gtk_window_set_title(window, "$escaped");',
        )
        .replaceAllMapped(
          RegExp(r'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"\);'),
          (_) => 'gtk_header_bar_set_title(header_bar, "$escaped");',
        );
    targetFile.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates APPLICATION_ID in `linux/CMakeLists.txt`.
  static void updatePackageId(String newId) {
    final cmake = File(p.join('linux', 'CMakeLists.txt'));
    if (!cmake.existsSync()) return;

    final content = cmake
        .readAsStringSync(encoding: utf8)
        .replaceAllMapped(
          RegExp(r'set\(APPLICATION_ID\s+"[^"]*"\)'),
          (_) => 'set(APPLICATION_ID "$newId")',
        );
    cmake.writeAsStringSync(content, encoding: utf8);
  }
}
