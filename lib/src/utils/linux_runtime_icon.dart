import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'logger.dart';

/// Makes the Linux runner load the generated window icon at runtime.
///
/// The default Flutter Linux runner never loads an icon, and files under
/// `linux/runner/assets` are not part of the built bundle. Two small, marked
/// edits fix that:
///
/// * `CMakeLists.txt` installs the icon to `<bundle>/data/app_icon.png`;
/// * `my_application.cc` loads it from the executable's own folder, so it works
///   no matter which directory the app is started from.
class LinuxRuntimeIcon {
  LinuxRuntimeIcon._();

  static const String _cmakeMarker = 'rebrand_kit: install the window icon';
  static const String _ccMarker = 'rebrand_kit: load the window icon';

  /// [iconFile] is the generated `app_icon.png` (relative to the project root).
  static void link(File iconFile) {
    _linkCMake(iconFile);
    _linkWindow();
  }

  static void _linkCMake(File iconFile) {
    final cmake = File(p.join('linux', 'CMakeLists.txt'));
    if (!cmake.existsSync()) return;

    var content = cmake.readAsStringSync(encoding: utf8);
    if (content.contains(_cmakeMarker)) return;

    final relative = p
        .split(p.relative(iconFile.path, from: 'linux'))
        .join('/');
    if (!content.endsWith('\n')) content += '\n';
    content +=
        '''

# $_cmakeMarker next to the bundled app data.
if(DEFINED INSTALL_BUNDLE_DATA_DIR)
  install(FILES "\${CMAKE_CURRENT_SOURCE_DIR}/$relative"
    DESTINATION "\${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)
endif()
''';
    cmake.writeAsStringSync(content, encoding: utf8);
  }

  static void _linkWindow() {
    final runnerApp = File(p.join('linux', 'runner', 'my_application.cc'));
    final fallbackApp = File(p.join('linux', 'my_application.cc'));
    final target = runnerApp.existsSync()
        ? runnerApp
        : (fallbackApp.existsSync() ? fallbackApp : null);
    if (target == null) return;

    final content = target.readAsStringSync(encoding: utf8);
    if (content.contains(_ccMarker)) return;

    const snippet =
        '''
  // $_ccMarker from <executable folder>/data/app_icon.png
  {
    g_autofree gchar* rebrand_exe = g_file_read_link("/proc/self/exe", nullptr);
    if (rebrand_exe != nullptr) {
      g_autofree gchar* rebrand_dir = g_path_get_dirname(rebrand_exe);
      g_autofree gchar* rebrand_icon =
          g_build_filename(rebrand_dir, "data", "app_icon.png", nullptr);
      gtk_window_set_icon_from_file(window, rebrand_icon, nullptr);
    }
  }
''';

    // Prefer the line that sets the default size (insert before it), otherwise
    // the statement that creates the window (insert after it).
    final beforeDefaultSize = RegExp(
      r'^[ \t]*gtk_window_set_default_size\(window[^;]*;[ \t]*\r?\n',
      multiLine: true,
    );
    final afterWindowCreation = RegExp(
      r'^[ \t]*GtkWindow\*\s*window\s*=[^;]*;[ \t]*\r?\n',
      multiLine: true,
    );

    final sizeMatch = beforeDefaultSize.firstMatch(content);
    final creationMatch = afterWindowCreation.firstMatch(content);
    if (sizeMatch != null || creationMatch != null) {
      final updated = sizeMatch != null
          ? content.replaceRange(sizeMatch.start, sizeMatch.start, snippet)
          : content.replaceRange(
              creationMatch!.end,
              creationMatch.end,
              snippet,
            );
      target.writeAsStringSync(updated, encoding: utf8);
      return;
    }

    Logger.warn(
      'Could not find where the Linux window is created in '
      '${p.basename(target.path)}, so the window icon was generated but not '
      'loaded. Call gtk_window_set_icon_from_file() yourself.',
    );
  }
}
