import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Renamer service for Windows C++ runner, resource metadata, and CMake targets.
class WindowsRenamer {
  WindowsRenamer._();

  /// Updates window title in `main.cpp` and executable resource metadata in `Runner.rc`.
  static void updateAppName(String name) {
    final mainCpp = File(p.join('windows', 'runner', 'main.cpp'));
    if (mainCpp.existsSync()) {
      var content = mainCpp.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'window\.Create(AndShow)?\(L"[^"]*"'),
        'window.Create(L"$name"',
      );
      mainCpp.writeAsStringSync(content, encoding: utf8);
    }

    final runnerRc = File(p.join('windows', 'runner', 'Runner.rc'));
    if (runnerRc.existsSync()) {
      var content = runnerRc.readAsStringSync(encoding: utf8);
      content = content.replaceAll(
        RegExp(r'VALUE "FileDescription", "[^"]*"'),
        'VALUE "FileDescription", "$name"',
      );
      content = content.replaceAll(
        RegExp(r'VALUE "ProductName", "[^"]*"'),
        'VALUE "ProductName", "$name"',
      );
      runnerRc.writeAsStringSync(content, encoding: utf8);
    }
  }

  /// Updates BINARY_NAME in `windows/CMakeLists.txt`.
  static void updatePackageId(String newId) {
    final cmake = File(p.join('windows', 'CMakeLists.txt'));
    if (!cmake.existsSync()) return;

    final sanitizedBinary = newId.split('.').last;
    var content = cmake.readAsStringSync(encoding: utf8);
    content = content.replaceAll(
      RegExp(r'set\(BINARY_NAME\s+"[^"]*"\)'),
      'set(BINARY_NAME "$sanitizedBinary")',
    );
    cmake.writeAsStringSync(content, encoding: utf8);
  }
}
