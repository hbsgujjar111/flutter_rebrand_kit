import 'dart:typed_data';

/// Pure-Dart Win32 binary .ICO struct encoder.
class IcoEncoder {
  IcoEncoder._();

  /// Encodes a list of PNG frames into a single multi-resolution .ICO binary container.
  static Uint8List encode(List<Uint8List> pngFrames, List<int> sizes) {
    final count = pngFrames.length;
    var imageOffset = 6 + (count * 16);

    final byteBuilder = BytesBuilder();

    // 1. ICONDIR Header (6 bytes)
    final iconDir = ByteData(6);
    iconDir.setUint16(0, 0, Endian.little); // Reserved
    iconDir.setUint16(2, 1, Endian.little); // Type 1 = Icon
    iconDir.setUint16(4, count, Endian.little); // Number of frames
    byteBuilder.add(iconDir.buffer.asUint8List());

    // 2. ICONDIRENTRY Structures (16 bytes per frame)
    for (int i = 0; i < count; i++) {
      final size = sizes[i];
      final pngSize = pngFrames[i].length;

      final entry = ByteData(16);
      entry.setUint8(0, size == 256 ? 0 : size); // Width (0 = 256)
      entry.setUint8(1, size == 256 ? 0 : size); // Height (0 = 256)
      entry.setUint8(2, 0); // Palette count
      entry.setUint8(3, 0); // Reserved
      entry.setUint16(4, 1, Endian.little); // Color planes
      entry.setUint16(6, 32, Endian.little); // Bits per pixel
      entry.setUint32(8, pngSize, Endian.little); // Data size
      entry.setUint32(12, imageOffset, Endian.little); // File offset
      byteBuilder.add(entry.buffer.asUint8List());

      imageOffset += pngSize;
    }

    // 3. PNG Image Payloads
    for (final frame in pngFrames) {
      byteBuilder.add(frame);
    }

    return byteBuilder.toBytes();
  }
}
