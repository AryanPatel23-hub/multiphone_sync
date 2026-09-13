import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/logging/app_logger.dart';
import '../models/playback_state.dart';
import '../services/audio/audio_service.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({AudioService? audioService})
    : _audioService = audioService ?? JustAudioService() {
    _subscriptions.addAll([
      _audioService.playerStateStream.listen(_handlePlayerState),
      _audioService.positionStream.listen((_) => notifyListeners()),
      _audioService.durationStream.listen((_) => notifyListeners()),
      _audioService.bufferedPositionStream.listen((_) => notifyListeners()),
    ]);
  }

  final AudioService _audioService;
  final _subscriptions = <StreamSubscription<dynamic>>[];
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

  Future<void> play() async => _run(() => _audioService.play());

  Future<void> pause() async => _run(() => _audioService.pause());

  Future<void> stop() async {
    await _run(() => _audioService.stop());
    status = PlaybackStatus.stopped;
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
