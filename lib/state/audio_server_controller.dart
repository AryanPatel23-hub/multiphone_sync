import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/logging/app_logger.dart';
import '../models/audio.dart';
import '../services/http/audio_http_server.dart';

enum AudioServerStatus { stopped, starting, ready, error }

class AudioServerController extends ChangeNotifier {
  AudioServerController({AudioHttpServer? server})
    : _server = server ?? AudioHttpServer();

  final AudioHttpServer _server;
  AudioServerStatus status = AudioServerStatus.stopped;
  AudioMetadata? metadata;
  String? endpoint;
  String? errorMessage;

  Future<void> start() async {
    if (status == AudioServerStatus.ready) return;
    status = AudioServerStatus.starting;
    errorMessage = null;
    notifyListeners();
    try {
      await _server.start();
      status = AudioServerStatus.ready;
    } catch (error, stackTrace) {
      AppLogger.error('Audio HTTP server failed to start', error, stackTrace);
      status = AudioServerStatus.error;
      errorMessage = 'Unable to start the local audio server.';
    }
    notifyListeners();
  }

  Future<void> exposeFile(String path, {Duration? duration}) async {
    try {
      if (status != AudioServerStatus.ready) await start();
      if (status != AudioServerStatus.ready) return;
      metadata = await _server.registerFile(path, duration: duration);
        endpoint =
          'http://${await _findHostAddress()}:${_server.boundPort}/audio/${metadata!.audioId}';
      errorMessage = null;
    } on FileSystemException catch (error) {
      errorMessage = error.message;
      status = AudioServerStatus.error;
    } on FormatException catch (error) {
      errorMessage = error.message;
      status = AudioServerStatus.error;
    } catch (error, stackTrace) {
      AppLogger.error('Audio exposure failed', error, stackTrace);
      errorMessage = 'Unable to expose this audio file.';
      status = AudioServerStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<String> _findHostAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) return address.address;
      }
    }
    return '127.0.0.1';
  }
}