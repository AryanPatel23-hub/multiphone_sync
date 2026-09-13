import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../core/logging/app_logger.dart';
import '../../models/audio.dart';

class AudioHttpServer {
  AudioHttpServer({this.port = 0});

  final int port;
  final _audio = <String, AudioMetadata>{};
  HttpServer? _server;

  int get boundPort => _server?.port ?? port;
  bool get isRunning => _server != null;
  Iterable<AudioMetadata> get registeredAudio => _audio.values;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);
  }

  Future<AudioMetadata> registerFile(String path, {Duration? duration}) async {
    final file = File(path.trim());
    if (!await file.exists()) {
      throw const FileSystemException('Audio file does not exist.');
    }
    if (!_isSupportedAudio(file.path)) {
      throw const FormatException('Only MP3 audio files are supported.');
    }

    final checksum = await _checksum(file);
    final metadata = AudioMetadata(
      audioId: checksum,
      fileName: _fileName(file.path),
      format: 'mp3',
      size: await file.length(),
      checksum: checksum,
      localPath: file.path,
      duration: duration,
    );
    _audio[metadata.audioId] = metadata;
    return metadata;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _audio.clear();
  }

  Future<void> dispose() => stop();

  Future<void> _handleRequest(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (request.method != 'GET' ||
        segments.length != 2 ||
        segments.first != 'audio') {
      await _respond(request, HttpStatus.notFound, 'Not found');
      return;
    }

    final metadata = _audio[segments[1]];
    if (metadata == null) {
      await _respond(request, HttpStatus.notFound, 'Audio not found');
      return;
    }

    final file = File(metadata.localPath);
    if (!await file.exists()) {
      _audio.remove(metadata.audioId);
      await _respond(request, HttpStatus.notFound, 'Audio not found');
      return;
    }

    try {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..contentLength = metadata.size;
      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (error, stackTrace) {
      AppLogger.error('Audio HTTP response failed', error, stackTrace);
      if (!request.response.headers.chunkedTransferEncoding) {
        await request.response.close();
      }
    }
  }

  Future<void> _respond(HttpRequest request, int status, String message) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..write(message);
    await request.response.close();
  }

  Future<String> _checksum(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  bool _isSupportedAudio(String path) => path.toLowerCase().endsWith('.mp3');

  String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
}
