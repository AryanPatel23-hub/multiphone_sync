import 'dart:async';
import 'dart:io';

import '../../models/audio.dart';

class AudioTransferProgress {
  const AudioTransferProgress(this.bytesReceived, this.totalBytes);

  final int bytesReceived;
  final int totalBytes;

  double get progress =>
      totalBytes <= 0 ? 0 : (bytesReceived / totalBytes).clamp(0.0, 1.0);
}

abstract interface class AudioTransferService {
  Stream<AudioTransferProgress> get progressStream;

  Future<String> download(
    Uri source,
    AudioMetadata metadata, {
    int maxAttempts = 3,
  });

  Future<void> dispose();
}

class LocalAudioTransferService implements AudioTransferService {
  LocalAudioTransferService({HttpClient? client, Directory? temporaryDirectory})
    : _client = client ?? HttpClient(),
      _temporaryDirectory = temporaryDirectory ?? Directory.systemTemp;

  final HttpClient _client;
  final Directory _temporaryDirectory;
  final _progressController =
      StreamController<AudioTransferProgress>.broadcast();

  @override
  Stream<AudioTransferProgress> get progressStream =>
      _progressController.stream;

  @override
  Future<String> download(
    Uri source,
    AudioMetadata metadata, {
    int maxAttempts = 3,
  }) async {
    if (maxAttempts < 1) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Must be at least 1.',
      );
    }
    if (metadata.audioId.isEmpty || metadata.size < 0) {
      throw const FormatException('Audio metadata is invalid.');
    }

    Directory? attemptDirectory;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      attemptDirectory = await _createAttemptDirectory(metadata.audioId);
      final temporaryFile = File(
        '${attemptDirectory.path}${Platform.pathSeparator}${metadata.fileName}.part',
      );
      try {
        await _downloadToFile(source, metadata, temporaryFile);
        return temporaryFile.path;
      } catch (error) {
        lastError = error;
        await _deleteQuietly(attemptDirectory);
        if (attempt == maxAttempts) rethrow;
      }
    }

    throw StateError('Audio download failed: $lastError');
  }

  @override
  Future<void> dispose() async {
    _client.close(force: true);
    await _progressController.close();
  }

  Future<void> _downloadToFile(
    Uri source,
    AudioMetadata metadata,
    File temporaryFile,
  ) async {
    final request = await _client.getUrl(source);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Audio download failed with HTTP ${response.statusCode}.',
        uri: source,
      );
    }

    final expectedBytes = metadata.size > 0
        ? metadata.size
        : response.contentLength;
    var receivedBytes = 0;
    final sink = temporaryFile.openWrite();
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        _progressController.add(
          AudioTransferProgress(receivedBytes, expectedBytes),
        );
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (metadata.size > 0 && receivedBytes != metadata.size) {
      throw const FileSystemException('Audio download was incomplete.');
    }
  }

  Future<Directory> _createAttemptDirectory(String audioId) async {
    final safeId = audioId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final root = await Directory(
      '${_temporaryDirectory.path}${Platform.pathSeparator}multi_phone_sync_$safeId',
    ).create(recursive: true);
    return root.createTemp('attempt_');
  }

  Future<void> _deleteQuietly(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // A failed temporary file must never be promoted or reused.
    }
  }
}
