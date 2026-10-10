import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/image_utils.dart';
import '../utils/logger.dart';
import '../utils/validators.dart';

/// Generator for Android status bar monochrome notification icons.
class NotificationIconGenerator {
  NotificationIconGenerator._();

  /// Generates anti-aliased white silhouettes matching Android notification specifications.
  ///
  /// Returns false (and writes nothing) when the project has no `android/`
  /// folder.
  static bool generate({
    required String iconPath,
    String iconName = 'ic_notification',
  }) {
    final cleanIconName = Validators.resourceName(iconName);
    final image = ImageUtils.loadAndValidateIcon(iconPath);

    if (!Directory('android').existsSync()) {
      Logger.warn('No android/ folder found; skipping notification icons.');
      return false;
    }

    if (!ImageUtils.hasTransparency(image)) {
      Logger.warn(
        'The notification icon ($iconPath) has no transparency, so the '
        'status bar icon will be a solid white square. Use a PNG with a '
        'transparent background.',
      );
    }

    final densities = {
      'drawable-mdpi': 24,
      'drawable-hdpi': 36,
      'drawable-xhdpi': 48,
      'drawable-xxhdpi': 72,
      'drawable-xxxhdpi': 96,
    };

    for (final entry in densities.entries) {
      final targetSize = entry.value;

      final scaled = img.copyResize(
        image,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.average,
      );

      for (int y = 0; y < scaled.height; y++) {
        for (int x = 0; x < scaled.width; x++) {
          final pixel = scaled.getPixel(x, y);
          if (pixel.a > 0) {
            scaled.setPixelRgba(x, y, 255, 255, 255, pixel.a);
          }
        }
      }

      final dir = Directory(
        p.join('android', 'app', 'src', 'main', 'res', entry.key),
      );
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      if (cleanIconName != 'ic_notification') {
        final oldDefaultFile = File(p.join(dir.path, 'ic_notification.png'));
        if (oldDefaultFile.existsSync()) {
          try {
            oldDefaultFile.deleteSync();
          } catch (_) {}
        }
      }

      File(
        p.join(dir.path, '$cleanIconName.png'),
      ).writeAsBytesSync(img.encodePng(scaled));
    }

    return true;
  }
}
