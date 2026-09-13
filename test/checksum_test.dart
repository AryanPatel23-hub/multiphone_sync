import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/models/audio.dart';
import 'package:multi_phone_sync/services/transfer/checksum_service.dart';

void main() {
  test('accepts a file with matching size and SHA-256', () async {
    final directory = await Directory.systemTemp.createTemp('checksum_test');
    final file = File('${directory.path}${Platform.pathSeparator}audio.mp3');
    final bytes = List<int>.generate(128, (index) => index);
    await file.writeAsBytes(bytes);
    final checksum = sha256.convert(bytes).toString();

    try {
      final result = await Sha256ChecksumService().verify(
        file,
        _metadata(bytes.length, checksum),
      );
      expect(result.isValid, isTrue);
      expect(result.actualSize, bytes.length);
      expect(result.actualChecksum, checksum);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('rejects a size mismatch', () async {
    final directory = await Directory.systemTemp.createTemp('checksum_test');
    final file = File('${directory.path}${Platform.pathSeparator}audio.mp3');
    final bytes = List<int>.filled(32, 4);
    await file.writeAsBytes(bytes);

    try {
      final result = await Sha256ChecksumService().verify(
        file,
        _metadata(bytes.length + 1, sha256.convert(bytes).toString()),
      );
      expect(result.sizeMatches, isFalse);
      expect(result.checksumMatches, isTrue);
      expect(result.isValid, isFalse);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('rejects a checksum mismatch', () async {
    final directory = await Directory.systemTemp.createTemp('checksum_test');
    final file = File('${directory.path}${Platform.pathSeparator}audio.mp3');
    final bytes = List<int>.filled(32, 8);
    await file.writeAsBytes(bytes);

    try {
      final result = await Sha256ChecksumService().verify(
        file,
        _metadata(bytes.length, 'incorrect-checksum'),
      );
      expect(result.sizeMatches, isTrue);
      expect(result.checksumMatches, isFalse);
      expect(result.isValid, isFalse);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

AudioMetadata _metadata(int size, String checksum) {
  return AudioMetadata(
    audioId: 'audio-1',
    fileName: 'audio.mp3',
    format: 'mp3',
    size: size,
    checksum: checksum,
  );
}
