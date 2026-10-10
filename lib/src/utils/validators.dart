/// Input validation so bad configuration fails early with a clear message
/// instead of producing a project that no longer builds.
class Validators {
  Validators._();

  static final RegExp _packageId = RegExp(
    r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
  );

  static final RegExp _version = RegExp(
    r'^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+\d+)?$',
  );

  static final RegExp _resourceName = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Throws when [id] is not a valid Android application ID / bundle ID.
  ///
  /// The same ID is written to every platform, so the stricter Android rules
  /// apply: at least two dot-separated segments, each starting with a letter
  /// and containing only letters, digits or underscores.
  static void packageId(String id) {
    if (!_packageId.hasMatch(id)) {
      throw Exception(
        'Invalid package_id "$id". Use at least two dot-separated segments '
        'that start with a letter and contain only letters, digits or '
        'underscores (for example "com.company.app").',
      );
    }
  }

  /// Throws when [value] is not a valid `x.y.z` or `x.y.z+build` version.
  static void version(String value) {
    if (!_version.hasMatch(value)) {
      throw Exception(
        'Invalid version "$value". Use the format "x.y.z" or "x.y.z+build" '
        '(for example "1.2.0+15").',
      );
    }
  }

  /// Returns [raw] without a trailing `.png`, or throws when it is not a valid
  /// Android drawable resource name (lowercase letters, digits, underscores).
  static String resourceName(String raw) {
    final clean = raw.trim().replaceAll(
      RegExp(r'\.png$', caseSensitive: false),
      '',
    );
    if (!_resourceName.hasMatch(clean)) {
      throw Exception(
        'Invalid notification_icon_name "$raw". Android resource names must '
        'start with a lowercase letter and contain only lowercase letters, '
        'digits and underscores (for example "ic_stat_notification").',
      );
    }
    return clean;
  }
}
