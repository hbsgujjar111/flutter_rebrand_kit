import 'dart:io';
import 'package:image/image.dart' as img;
import 'logger.dart';

/// Image utility functions for decoding, validating, and color parsing.
class ImageUtils {
  ImageUtils._();

  /// Loads and validates that an icon exists and is decoded properly.
  static img.Image loadAndValidateIcon(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File not found at: $path');
    }

    final image = img.decodeImage(file.readAsBytesSync());
    if (image == null) {
      throw Exception('Unable to decode image at: $path');
    }

    if (image.width != 1024 || image.height != 1024) {
      Logger.warn(
        'Image ($path) is ${image.width}x${image.height}. '
        'For sharp downscaling and store compliance, use a 1024x1024 source PNG.',
      );
    }
    return image;
  }

  /// Parses a hex color string (e.g. `#1E1E2E`) into an [img.ColorRgb8].
  static img.ColorRgb8 parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final val = int.parse(clean, radix: 16);
    return img.ColorRgb8((val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF);
  }

  /// Converts a logo into a monochrome white-on-transparent silhouette for Android 13+ theming.
  static img.Image createMonochromeSilhouette(img.Image source) {
    final mono = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        if (p.a > 15) {
          mono.setPixelRgba(x, y, 255, 255, 255, p.a);
        } else {
          mono.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
    return mono;
  }
}
