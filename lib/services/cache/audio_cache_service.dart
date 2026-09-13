import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../models/audio.dart';
import '../transfer/checksum_service.dart';

abstract interface class AudioCacheService {
  Future<AudioMetadata?> findValid(String audioId);
  Future<AudioMetadata> storeVerified(File verifiedFile, AudioMetadata metadata);
  Future<void> invalidate(String audioId);
  Future<void> dispose();
}

class LocalAudioCacheService implements AudioCacheService {
  LocalAudioCacheService({this._root, ChecksumService? checksumService})
    : _checksumService = checksumService ?? Sha256ChecksumService();

  Directory? _root;
  final ChecksumService _checksumService;

  @override
  Future<AudioMetadata?> findValid(String audioId) async {
    if (audioId.isEmpty) return null;
    final root = await _cacheRoot();
    final metadataFile = File(_metadataPath(root, audioId));
    if (!await metadataFile.exists()) return null;

    try {
      final metadata = AudioMetadata.fromJson(
        jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>,
      );
      final audioFile = File(metadata.localPath);
      if (!await audioFile.exists()) {
        await invalidate(audioId);
        return null;
      }
      final result = await _checksumService.verify(audioFile, metadata);
      if (!result.isValid) {
        await invalidate(audioId);
        return null;
      }
      return metadata;
    } catch (error, stackTrace) {
      AppLogger.error('Audio cache validation failed', error, stackTrace);
      await invalidate(audioId);
      return null;
    }
  }

  @override
  Future<AudioMetadata> storeVerified(
    File verifiedFile,
    AudioMetadata metadata,
  ) async {
    final verification = await _checksumService.verify(verifiedFile, metadata);
    if (!verification.isValid) {
      throw const FormatException('Only verified audio may enter the cache.');
    }

    final root = await _cacheRoot();
    final safeId = _safeId(metadata.audioId);
    final cacheFile = File(
      '${root.path}${Platform.pathSeparator}$safeId.${metadata.format}',
    );
    final cachePart = File('${cacheFile.path}.part');
    final cachedMetadata = metadata.copyWith(localPath: cacheFile.path);

    await cachePart.parent.create(recursive: true);
    if (await cachePart.exists()) await cachePart.delete();
    await verifiedFile.copy(cachePart.path);
    if (await cacheFile.exists()) await cacheFile.delete();
    await cachePart.rename(cacheFile.path);
    await File(_metadataPath(root, metadata.audioId)).writeAsString(
      jsonEncode(cachedMetadata.toJson()),
      flush: true,
    );
    return cachedMetadata;
  }

  @override
  Future<void> invalidate(String audioId) async {
    final root = await _cacheRoot();
    final metadataFile = File(_metadataPath(root, audioId));
    if (await metadataFile.exists()) {
      try {
        final metadata = AudioMetadata.fromJson(
          jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>,
        );
        final audioFile = File(metadata.localPath);
        if (await audioFile.exists()) await audioFile.delete();
      } catch (_) {
        // Metadata is invalid; deleting the metadata file is sufficient.
      }
      await metadataFile.delete();
    }
  }

  @override
  Future<void> dispose() async {}

  Future<Directory> _cacheRoot() async {
    return _root ??= Directory(
      '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}audio_cache',
    )..createSync(recursive: true);
  }

  String _metadataPath(Directory root, String audioId) =>
      '${root.path}${Platform.pathSeparator}${_safeId(audioId)}.json';

  String _safeId(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
