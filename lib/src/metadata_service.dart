import 'renamers/android_renamer.dart';
import 'renamers/ios_renamer.dart';
import 'renamers/linux_renamer.dart';
import 'renamers/macos_renamer.dart';
import 'renamers/version_renamer.dart';
import 'renamers/web_renamer.dart';
import 'renamers/windows_renamer.dart';

/// Orchestrator service for updating manifest files, package IDs, and app labels.
class MetadataService {
  MetadataService._();

  /// Updates app version and build number in `pubspec.yaml`.
  static void updateVersion(String version) {
    VersionRenamer.updateVersion(version);
  }

  /// Updates application name across all platforms.
  static void updateAppName(String name) {
    AndroidRenamer.updateAppName(name);
    IosRenamer.updateAppName(name);
    MacOsRenamer.updateAppName(name);
    WebRenamer.updateAppName(name);
    WindowsRenamer.updateAppName(name);
    LinuxRenamer.updateAppName(name);
  }

  /// Updates package ID / bundle ID across all platforms.
  static void updatePackageId(String newId) {
    AndroidRenamer.updatePackageId(newId);
    IosRenamer.updatePackageId(newId);
    MacOsRenamer.updatePackageId(newId);
    WindowsRenamer.updatePackageId(newId);
    LinuxRenamer.updatePackageId(newId);
  }
}
