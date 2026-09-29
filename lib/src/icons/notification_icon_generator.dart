import 'dart:io';
import 'package:image/image.dart' as img;
import '../utils/image_utils.dart';

/// Generator for Android status bar monochrome notification icons.
class NotificationIconGenerator {
  NotificationIconGenerator._();

  /// Generates anti-aliased white silhouettes matching Android notification specifications.
  static void generate({
    required String iconPath,
    String iconName = 'ic_notification',
  }) {
    var image = ImageUtils.loadAndValidateIcon(iconPath);
    final cleanIconName = iconName.replaceAll('.png', '');

    if (image.numChannels < 4 || image.hasPalette) {
      image = image.convert(numChannels: 4);
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
          final p = scaled.getPixel(x, y);
          if (p.a > 0) {
            scaled.setPixelRgba(x, y, 255, 255, 255, p.a);
          }
        }
      }

      final dir = Directory('android/app/src/main/res/${entry.key}');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      if (cleanIconName != 'ic_notification') {
        final oldDefaultFile = File('${dir.path}/ic_notification.png');
        if (oldDefaultFile.existsSync()) {
          try {
            oldDefaultFile.deleteSync();
          } catch (_) {}
        }
      }

      File(
        '${dir.path}/$cleanIconName.png',
      ).writeAsBytesSync(img.encodePng(scaled));
    }
  }
}
