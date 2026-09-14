import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/models/audio.dart';
import 'package:multi_phone_sync/services/cache/audio_cache_service.dart';

void main() {
  test(
    'stores verified audio and reuses it after service recreation',
    () async {
      final root = await Directory.systemTemp.createTemp('audio_cache_test');
      final source = File('${root.path}${Platform.pathSeparator}source.mp3');
      final bytes = List<int>.generate(64, (index) => index);
      await source.writeAsBytes(bytes);
      final metadata = _metadata(bytes);

      try {
        final first = LocalAudioCacheService(root: root);
        final cached = await first.storeVerified(source, metadata);
        expect(await File(cached.localPath).exists(), isTrue);
        await first.dispose();

        final second = LocalAudioCacheService(root: root);
        final reused = await second.findValid(metadata.audioId);
        expect(reused?.localPath, cached.localPath);
        expect(await File(reused!.localPath).readAsBytes(), bytes);
        await second.dispose();
      } finally {
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );

  test('rejects unverified audio and never stores it', () async {
    final root = await Directory.systemTemp.createTemp('audio_cache_test');
    final source = File('${root.path}${Platform.pathSeparator}source.mp3');
    await source.writeAsBytes(List<int>.filled(16, 4));
    final metadata = AudioMetadata(
      audioId: 'audio-bad',
      fileName: 'source.mp3',
      format: 'mp3',
      size: 16,
      checksum: 'wrong',
    );

    try {
      final cache = LocalAudioCacheService(root: root);
      await expectLater(
        cache.storeVerified(source, metadata),
        throwsA(isA<FormatException>()),
      );
      expect(
        await Directory(
          root.path,
        ).list().where((entity) => entity.path.endsWith('.json')).toList(),
        isEmpty,
      );
      await cache.dispose();
    } finally {
      if (await root.exists()) await root.delete(recursive: true);
    }
  });

  test('invalidates a corrupted cached file', () async {
    final root = await Directory.systemTemp.createTemp('audio_cache_test');
    final source = File('${root.path}${Platform.pathSeparator}source.mp3');
    final bytes = List<int>.filled(16, 9);
    await source.writeAsBytes(bytes);
    final metadata = _metadata(bytes);

    try {
      final cache = LocalAudioCacheService(root: root);
      final cached = await cache.storeVerified(source, metadata);
      await File(cached.localPath).writeAsBytes(List<int>.filled(16, 1));
      expect(await cache.findValid(metadata.audioId), isNull);
      expect(await File(cached.localPath).exists(), isFalse);
      await cache.dispose();
    } finally {
      if (await root.exists()) await root.delete(recursive: true);
    }
  });
}

AudioMetadata _metadata(List<int> bytes) {
  return AudioMetadata(
    audioId: sha256.convert(bytes).toString(),
    fileName: 'source.mp3',
    format: 'mp3',
    size: bytes.length,
    checksum: sha256.convert(bytes).toString(),
  );
}
