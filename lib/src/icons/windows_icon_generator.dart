import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../utils/ico_encoder.dart';

/// Generator for multi-resolution Windows binary `.ico` application icons.
class WindowsIconGenerator {
  WindowsIconGenerator._();

  /// Encodes 16, 32, 48, and 256px frames into `windows/runner/resources/app_icon.ico`.
  ///
  /// The master image's transparency is preserved, so the icon blends with the
  /// taskbar and title bar instead of showing a solid square.
  static void generate({required img.Image baseImage}) {
    final winResDir = Directory(p.join('windows', 'runner', 'resources'));
    if (!winResDir.existsSync()) {
      winResDir.createSync(recursive: true);
    }

    final icoSizes = [16, 32, 48, 256];
    final pngFrames = <Uint8List>[];

    for (final size in icoSizes) {
      final frame = img.copyResize(
        baseImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      );
      pngFrames.add(Uint8List.fromList(img.encodePng(frame)));
    }

    final icoBytes = IcoEncoder.encode(pngFrames, icoSizes);
    File(p.join(winResDir.path, 'app_icon.ico')).writeAsBytesSync(icoBytes);
  }
}
