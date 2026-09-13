import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:multi_phone_sync/models/playback_state.dart';
import 'package:multi_phone_sync/services/audio/audio_service.dart';
import 'package:multi_phone_sync/state/playback_controller.dart';

void main() {
  test('rejects an empty local audio path', () async {
    final service = FakeAudioService();
    final controller = PlaybackController(audioService: service);

    await controller.loadFile(' ');

    expect(controller.status, PlaybackStatus.error);
    expect(controller.errorMessage, 'Enter a local audio file path.');
    controller.dispose();
    await service.close();
  });

  test('loads a file, clamps seek, and limits playback speed', () async {
    final service = FakeAudioService();
    final controller = PlaybackController(audioService: service);

    await controller.loadFile('/music/song.mp3');
    await controller.seek(const Duration(minutes: 5));
    await controller.setSpeed(4);

    expect(controller.status, PlaybackStatus.ready);
    expect(controller.filePath, '/music/song.mp3');
    expect(service.lastSeek, const Duration(minutes: 2));
    expect(controller.speed, 2.0);
    controller.dispose();
    await service.close();
  });
}

class FakeAudioService implements AudioService {
  final playerStates = StreamController<PlayerState>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final bufferedPositions = StreamController<Duration>.broadcast();
  Duration currentPosition = Duration.zero;
  Duration? currentDuration = const Duration(minutes: 2);
  Duration currentBufferedPosition = Duration.zero;
  Duration? lastSeek;
  bool isPlaying = false;
  double currentSpeed = 1.0;

  @override
  Stream<PlayerState> get playerStateStream => playerStates.stream;

  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  Stream<Duration?> get durationStream => durations.stream;

  @override
  Stream<Duration> get bufferedPositionStream => bufferedPositions.stream;

  @override
  Duration get position => currentPosition;

  @override
  Duration? get duration => currentDuration;

  @override
  Duration get bufferedPosition => currentBufferedPosition;

  @override
  bool get playing => isPlaying;

  @override
  Future<Duration?> loadFile(String path) async => currentDuration;

  @override
  Future<void> play() async {
    isPlaying = true;
    playerStates.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    playerStates.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    playerStates.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    currentPosition = position;
    positions.add(position);
  }

  @override
  Future<void> setSpeed(double speed) async => currentSpeed = speed;

  @override
  Future<void> dispose() async {}

  Future<void> close() async {
    await playerStates.close();
    await positions.close();
    await durations.close();
    await bufferedPositions.close();
  }
}
