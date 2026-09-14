import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/logging/app_logger.dart';
import '../models/playback_state.dart';
import '../services/audio/audio_service.dart';
import 'connection_controller.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({
    AudioService? audioService,
    this._connection,
    this._broadcastCommands = false,
  }) : _audioService = audioService ?? JustAudioService() {
    _subscriptions.addAll([
      _audioService.playerStateStream.listen(_handlePlayerState),
      _audioService.positionStream.listen((_) => notifyListeners()),
      _audioService.durationStream.listen((_) => notifyListeners()),
      _audioService.bufferedPositionStream.listen((_) => notifyListeners()),
    ]);
    if (_connection != null) {
      _subscriptions.add(
        _connection.messages.stream.listen(_handleConnectionMessage),
      );
    }
  }

  final AudioService _audioService;
  final ConnectionController? _connection;
  final bool _broadcastCommands;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _applyingRemoteCommand = false;
  PlaybackStatus status = PlaybackStatus.idle;
  String? filePath;
  String? errorMessage;
  double speed = 1.0;

  Duration get position => _audioService.position;
  Duration? get duration => _audioService.duration;
  Duration get bufferedPosition => _audioService.bufferedPosition;
  bool get isPlaying => _audioService.playing;

  Future<void> loadFile(String path) async {
    if (path.trim().isEmpty) {
      _setError('Enter a local audio file path.');
      notifyListeners();
      return;
    }
    status = PlaybackStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await _audioService.loadFile(path.trim());
      filePath = path.trim();
      status = PlaybackStatus.ready;
    } catch (error, stackTrace) {
      AppLogger.error('Audio load failed', error, stackTrace);
      _setError('Unable to load this audio file.');
    }
    notifyListeners();
  }

  Future<void> play() async {
    await _run(() => _audioService.play());
    _sendCommand('PLAY');
  }

  Future<void> pause() async {
    await _run(() => _audioService.pause());
    _sendCommand('PAUSE');
  }

  Future<void> stop() async {
    await _run(() => _audioService.stop());
    status = PlaybackStatus.stopped;
    _sendCommand('STOP', {'positionMs': 0});
    notifyListeners();
  }

  Future<void> seek(Duration target) async {
    final maximum = duration ?? target;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > maximum
        ? maximum
        : target;
    await _run(() => _audioService.seek(clamped));
    _sendCommand('SEEK', {'positionMs': clamped.inMilliseconds});
  }

  Future<void> setSpeed(double value) async {
    final clamped = value.clamp(0.5, 2.0).toDouble();
    await _run(() => _audioService.setSpeed(clamped));
    speed = clamped;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioService.dispose();
    super.dispose();
  }

  void _handleConnectionMessage(dynamic value) {
    final message = value as dynamic;
    if (message.type == 'SYNC_REQUEST' && _connection?.isHost == true) {
      _connection?.send('SYNC_RESPONSE', _playbackPayload());
      return;
    }
    if (message.type == 'SYNC_RESPONSE' && _connection?.isHost != true) {
      _applyRemoteCommand(message.payload, () async {
        await seek(_durationFromPayload(message.payload));
        if (message.payload['playing'] == true) {
          await _audioService.play();
        } else {
          await _audioService.pause();
        }
      });
      return;
    }
    if (_connection?.isHost == true) return;
    if (message.type == 'PLAY' ||
        message.type == 'PAUSE' ||
        message.type == 'STOP' ||
        message.type == 'SEEK') {
      _applyRemoteCommand(message.payload, () async {
        if (message.payload['positionMs'] is int) {
          await _audioService.seek(_durationFromPayload(message.payload));
        }
        switch (message.type) {
          case 'PLAY':
            await _audioService.play();
          case 'PAUSE':
            await _audioService.pause();
          case 'STOP':
            await _audioService.stop();
        }
      });
    }
  }

  Future<void> _applyRemoteCommand(
    Map<String, dynamic> payload,
    Future<void> Function() action,
  ) async {
    _applyingRemoteCommand = true;
    try {
      await action();
    } finally {
      _applyingRemoteCommand = false;
    }
  }

  Duration _durationFromPayload(Map<String, dynamic> payload) {
    final positionMs = payload['positionMs'];
    return Duration(milliseconds: positionMs is int ? positionMs : 0);
  }

  Map<String, dynamic> _playbackPayload() {
    return {
      'positionMs': position.inMilliseconds,
      'playing': isPlaying,
      'speed': speed,
    };
  }

  void _sendCommand(String type, [Map<String, dynamic>? payload]) {
    if (!_broadcastCommands || _applyingRemoteCommand) return;
    _connection?.send(type, {..._playbackPayload(), ...?payload});
  }

  void _handlePlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.loading ||
        playerState.processingState == ProcessingState.buffering) {
      status = PlaybackStatus.loading;
    } else if (playerState.playing) {
      status = PlaybackStatus.playing;
    } else if (playerState.processingState == ProcessingState.completed) {
      status = PlaybackStatus.stopped;
    } else if (filePath != null) {
      status = PlaybackStatus.paused;
    }
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      errorMessage = null;
    } catch (error, stackTrace) {
      AppLogger.error('Audio operation failed', error, stackTrace);
      _setError('Audio playback operation failed.');
    }
    notifyListeners();
  }

  void _setError(String message) {
    status = PlaybackStatus.error;
    errorMessage = message;
  }
}
