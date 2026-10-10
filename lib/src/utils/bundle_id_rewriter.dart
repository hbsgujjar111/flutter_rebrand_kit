/// Rewrites `PRODUCT_BUNDLE_IDENTIFIER` values inside an Xcode `project.pbxproj`.
///
/// The main app target receives the new identifier. Any identifier that is the
/// main identifier plus a suffix (for example `.RunnerTests` or
/// `.ShareExtension`) keeps its suffix, so test targets and app extensions
/// stay distinct and code signing keeps working. Values that are driven by
/// build variables (`$(...)`) are left untouched.
class BundleIdRewriter {
  BundleIdRewriter._();

  static final RegExp _setting = RegExp(
    r'PRODUCT_BUNDLE_IDENTIFIER(\s*=\s*)("?)([^";\n]+)\2;',
  );

  /// Returns [content] with bundle identifiers rewritten to [newId].
  ///
  /// [knownOldBase] is the current main identifier when it is stored somewhere
  /// else (for example macOS keeps it in `AppInfo.xcconfig`). When omitted, the
  /// shortest identifier found in the file is treated as the main identifier.
  static String rewrite(String content, String newId, {String? knownOldBase}) {
    final candidates = _setting
        .allMatches(content)
        .map((m) => m.group(3)!.trim())
        .where((value) => !value.contains(r'$('))
        .toSet()
        .toList();

    String base;
    if (knownOldBase != null && knownOldBase.isNotEmpty) {
      base = knownOldBase;
    } else if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.length.compareTo(b.length));
      base = candidates.first;
    } else {
      return content;
    }

    return content.replaceAllMapped(_setting, (m) {
      final value = m.group(3)!.trim();
      if (value.contains(r'$(')) return m.group(0)!;

      final equals = m.group(1)!;
      final quote = m.group(2)!;

      if (value == base) {
        return 'PRODUCT_BUNDLE_IDENTIFIER$equals$quote$newId$quote;';
      }
      if (value.startsWith('$base.')) {
        final suffix = value.substring(base.length);
        return 'PRODUCT_BUNDLE_IDENTIFIER$equals$quote$newId$suffix$quote;';
      }
      return m.group(0)!;
    });
  }
}
