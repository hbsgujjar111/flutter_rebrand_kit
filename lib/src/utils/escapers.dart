import 'dart:convert';

/// Escaping helpers so a user-provided app name can never break the native
/// file format it is written into.
class Escapers {
  Escapers._();

  /// Escapes text for XML/HTML element content and double-quoted attributes
  /// (`AndroidManifest.xml`, `Info.plist`, `index.html`).
  static String xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Escapes text for the inside of a JSON string literal (`manifest.json`).
  static String json(String value) {
    final encoded = jsonEncode(value);
    return encoded.substring(1, encoded.length - 1);
  }

  /// Escapes text for a C string literal (Linux GTK runner).
  static String cString(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');

  /// Escapes text for a C++ wide string literal `L"..."` (Windows runner).
  ///
  /// Non-ASCII characters are written as universal character names, so the
  /// result compiles correctly regardless of the source file encoding.
  static String cppWideString(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune == 0x5C) {
        buffer.write('\\\\');
      } else if (rune == 0x22) {
        buffer.write('\\"');
      } else if (rune == 0x0A) {
        buffer.write('\\n');
      } else if (rune == 0x0D) {
        continue;
      } else if (rune < 0x80) {
        buffer.writeCharCode(rune);
      } else if (rune <= 0xFFFF) {
        buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
      } else {
        buffer.write('\\U${rune.toRadixString(16).padLeft(8, '0')}');
      }
    }
    return buffer.toString();
  }

  /// Escapes text for a Windows resource (`.rc`) string literal.
  static String rcString(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '""')
      .replaceAll('\n', ' ')
      .replaceAll('\r', '');
}
