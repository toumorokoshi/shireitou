/// Pure-Dart PNG renderer for colored status dots in the native system tray
/// menu.
library;

import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

const _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// Renders an anti-aliased circular status dot of [color] on a transparent
/// [size]×[size] RGBA PNG.
Uint8List renderStatusDotPng(
  Color color, {
  int size = 16,
  double radius = 4.0,
}) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  final baseAlpha = color.a;

  // Each scanline starts with a 1-byte filter type (0 = None) + RGBA pixels.
  final raw = Uint8List(size * (1 + size * 4));
  final center = (size - 1) / 2.0;

  var offset = 0;
  for (var y = 0; y < size; y++) {
    raw[offset++] = 0;
    final dy = y - center;
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dist = math.sqrt(dx * dx + dy * dy);
      final coverage = (radius + 0.5 - dist).clamp(0.0, 1.0);
      final a = (baseAlpha * coverage * 255.0).round().clamp(0, 255);
      raw[offset++] = r;
      raw[offset++] = g;
      raw[offset++] = b;
      raw[offset++] = a;
    }
  }

  final ihdr = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6) // color type: RGBA
    ..setUint8(10, 0) // compression
    ..setUint8(11, 0) // filter
    ..setUint8(12, 0); // interlace

  final compressed = Uint8List.fromList(zlib.encode(raw));

  final out = BytesBuilder(copy: false)
    ..add(_pngSignature)
    ..add(_pngChunk('IHDR', ihdr.buffer.asUint8List()))
    ..add(_pngChunk('IDAT', compressed))
    ..add(_pngChunk('IEND', const []));
  return out.toBytes();
}

/// Encodes [renderStatusDotPng] as a `data:image/png;base64,...` URI for
/// `nativeapi.Image.fromBase64`.
String statusDotDataUri(Color color, {int size = 16, double radius = 4.0}) =>
    'data:image/png;base64,${base64Encode(renderStatusDotPng(color, size: size, radius: radius))}';

Uint8List _pngChunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final chunk = BytesBuilder(copy: false)
    ..add(_uint32be(data.length))
    ..add(typeBytes)
    ..add(data);
  final crcInput = BytesBuilder(copy: false)
    ..add(typeBytes)
    ..add(data);
  chunk.add(_uint32be(_crc32(crcInput.toBytes())));
  return chunk.toBytes();
}

Uint8List _uint32be(int value) {
  final data = ByteData(4)..setUint32(0, value);
  return data.buffer.asUint8List();
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
  }
  return c;
}, growable: false);

int _crc32(List<int> bytes) {
  var c = 0xffffffff;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) & 0xffffffff;
}
