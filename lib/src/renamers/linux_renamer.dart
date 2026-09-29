import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

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

    var content = targetFile.readAsStringSync(encoding: utf8);
    content = content.replaceAll(
      RegExp(r'gtk_window_set_title\(window,\s*"[^"]*"\);'),
      'gtk_window_set_title(window, "$name");',
    );
    content = content.replaceAll(
      RegExp(r'gtk_header_bar_set_title\(header_bar,\s*"[^"]*"\);'),
      'gtk_header_bar_set_title(header_bar, "$name");',
    );
    targetFile.writeAsStringSync(content, encoding: utf8);
  }

  /// Updates APPLICATION_ID in `linux/CMakeLists.txt`.
  static void updatePackageId(String newId) {
    final cmake = File(p.join('linux', 'CMakeLists.txt'));
    if (!cmake.existsSync()) return;

    var content = cmake.readAsStringSync(encoding: utf8);
    content = content.replaceAll(
      RegExp(r'set\(APPLICATION_ID\s+"[^"]*"\)'),
      'set(APPLICATION_ID "$newId")',
    );
    cmake.writeAsStringSync(content, encoding: utf8);
  }
}
