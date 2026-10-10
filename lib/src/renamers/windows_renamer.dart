import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/escapers.dart';

/// Renamer service for Windows C++ runner, resource metadata, and CMake targets.
class WindowsRenamer {
  WindowsRenamer._();

  /// Updates the window title in `main.cpp` and the `FileDescription` /
  /// `ProductName` entries in `Runner.rc`.
  static void updateAppName(String name) {
    final mainCpp = File(p.join('windows', 'runner', 'main.cpp'));
    if (mainCpp.existsSync()) {
      final wide = Escapers.cppWideString(name);
      final content = mainCpp
          .readAsStringSync(encoding: utf8)
          .replaceAllMapped(
            RegExp(r'window\.Create(AndShow)?\(\s*L"[^"]*"'),
            // Keep `Create` vs `CreateAndShow`: older Flutter templates only
            // have `CreateAndShow`.
            (m) => 'window.Create${m[1] ?? ''}(L"$wide"',
          );
      mainCpp.writeAsStringSync(content, encoding: utf8);
    }

    final runnerRc = File(p.join('windows', 'runner', 'Runner.rc'));
    if (runnerRc.existsSync()) {
      final rc = Escapers.rcString(name);
      var content = runnerRc.readAsStringSync(encoding: utf8);
      content = _setRcValue(content, 'FileDescription', rc);
      content = _setRcValue(content, 'ProductName', rc);
      runnerRc.writeAsStringSync(content, encoding: utf8);
    }
  }

  /// Updates BINARY_NAME in `windows/CMakeLists.txt`, plus the matching
  /// `InternalName` and `OriginalFilename` in `Runner.rc`.
  static void updatePackageId(String newId) {
    final binaryName = newId.split('.').last;

    final cmake = File(p.join('windows', 'CMakeLists.txt'));
    if (cmake.existsSync()) {
      final content = cmake
          .readAsStringSync(encoding: utf8)
          .replaceAllMapped(
            RegExp(r'set\(BINARY_NAME\s+"[^"]*"\)'),
            (_) => 'set(BINARY_NAME "$binaryName")',
          );
      cmake.writeAsStringSync(content, encoding: utf8);
    }

    final runnerRc = File(p.join('windows', 'runner', 'Runner.rc'));
    if (runnerRc.existsSync()) {
      var content = runnerRc.readAsStringSync(encoding: utf8);
      content = _setRcValue(content, 'InternalName', binaryName);
      content = _setRcValue(content, 'OriginalFilename', '$binaryName.exe');
      runnerRc.writeAsStringSync(content, encoding: utf8);
    }
  }

  static String _setRcValue(String content, String key, String value) {
    return content.replaceAllMapped(
      RegExp('VALUE\\s+"$key"\\s*,\\s*"[^"]*"'),
      (_) => 'VALUE "$key", "$value"',
    );
  }
}
