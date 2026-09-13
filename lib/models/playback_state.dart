enum PlaybackStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  stopped,
  error,
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.status,
    required this.position,
    required this.duration,
    required this.bufferedPosition,
    required this.speed,
    this.errorMessage,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration? duration;
  final Duration bufferedPosition;
  final double speed;
  final String? errorMessage;
}