import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'logger.dart';

/// Image utility functions for decoding, validating, and color parsing.
class ImageUtils {
  ImageUtils._();

  /// Loads an image and normalizes it for the generators.
  ///
  /// The result is always an 8-bit RGBA image (palette, grayscale and 16-bit
  /// PNGs are converted) and always square: a non-square image is centered on
  /// a transparent square canvas instead of being stretched later.
  static img.Image loadAndValidateIcon(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File not found at: $path');
    }

    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) {
      throw Exception('Unable to decode image at: $path');
    }

    if (decoded.width != 1024 || decoded.height != 1024) {
      Logger.warn(
        'Image ($path) is ${decoded.width}x${decoded.height}. '
        'For sharp downscaling and store compliance, use a 1024x1024 source PNG.',
      );
    }

    var image = decoded.convert(format: img.Format.uint8, numChannels: 4);

    if (image.width != image.height) {
      final side = math.max(image.width, image.height);
      final square = img.Image(width: side, height: side, numChannels: 4);
      img.compositeImage(
        square,
        image,
        dstX: (side - image.width) ~/ 2,
        dstY: (side - image.height) ~/ 2,
      );
      Logger.warn(
        'Image ($path) is not square. It was centered on a transparent '
        '${side}x$side canvas to avoid stretching.',
      );
      image = square;
    }

    return image;
  }

  /// Loads an image as 8-bit RGBA without squaring it or warning about its
  /// size. Used for images whose aspect ratio matters (for example a wide
  /// branding footer).
  static img.Image loadImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File not found at: $path');
    }
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) {
      throw Exception('Unable to decode image at: $path');
    }
    return decoded.convert(format: img.Format.uint8, numChannels: 4);
  }

  /// Crops fully transparent margins so the visible artwork can be sized
  /// precisely. Returns [image] unchanged when nothing can be trimmed.
  ///
  /// [image] must be 8-bit RGBA (see [loadImage]).
  static img.Image trimTransparent(img.Image image, {int alphaThreshold = 8}) {
    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (image.getPixel(x, y).a > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0) return image;

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    if (width == image.width && height == image.height) return image;
    return img.copyCrop(image, x: minX, y: minY, width: width, height: height);
  }

  /// Scales [source] (keeping its aspect ratio) to fit inside
  /// [maxWidth] x [maxHeight] pixels.
  static img.Image fitInside(img.Image source, int maxWidth, int maxHeight) {
    final scale = math.min(maxWidth / source.width, maxHeight / source.height);
    return img.copyResize(
      source,
      width: math.max(1, (source.width * scale).round()),
      height: math.max(1, (source.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  /// Scales [source] (keeping its aspect ratio) so that its diagonal is
  /// [diagonalPx] pixels. A rectangle with that diagonal always fits inside a
  /// circle whose diameter is [diagonalPx].
  static img.Image fitDiagonal(img.Image source, double diagonalPx) {
    final diagonal = math.sqrt(
      source.width * source.width + source.height * source.height,
    );
    final scale = diagonalPx / diagonal;
    return img.copyResize(
      source,
      width: math.max(1, (source.width * scale).round()),
      height: math.max(1, (source.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  /// Parses `#RGB`, `RGB`, `#RRGGBB` or `RRGGBB` into an [img.ColorRgb8].
  static img.ColorRgb8 parseHexColor(String hex) {
    final value = _hexValue(hex);
    return img.ColorRgb8(
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }

  /// Returns [hex] normalized to the upper-case `#RRGGBB` form that Android
  /// color resources require.
  static String normalizeHex(String hex) {
    final value = _hexValue(hex);
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static int _hexValue(String hex) {
    var clean = hex.trim().replaceAll('#', '');
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) {
      throw Exception(
        'Invalid color "$hex". Use a hex value such as "#FFFFFF" or "#FFF".',
      );
    }
    return int.parse(clean, radix: 16);
  }

  /// True when at least one pixel of [image] is not fully opaque.
  ///
  /// [image] must come from [loadAndValidateIcon] (8-bit RGBA).
  static bool hasTransparency(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (image.getPixel(x, y).a < 255) return true;
      }
    }
    return false;
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

  /// Returns a copy of the square image [source] clipped to a circle with a
  /// one-pixel anti-aliased edge (used for legacy round launcher icons).
  static img.Image circularMask(img.Image source) {
    final size = source.width;
    final out = img.Image(width: size, height: size, numChannels: 4);
    final radius = size / 2;
    final center = (size - 1) / 2;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final distance = math.sqrt(dx * dx + dy * dy);
        final coverage = (radius + 0.5 - distance).clamp(0.0, 1.0);
        if (coverage <= 0) continue;

        final pixel = source.getPixel(x, y);
        out.setPixelRgba(
          x,
          y,
          pixel.r,
          pixel.g,
          pixel.b,
          (255 * coverage).round(),
        );
      }
    }
    return out;
  }
}
