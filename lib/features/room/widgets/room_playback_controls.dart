import 'package:flutter/material.dart';

import '../../../models/playback_state.dart';
import '../../../state/playback_controller.dart';

class RoomPlaybackControls extends StatelessWidget {
  const RoomPlaybackControls({
    required this.enabled,
    this.controller,
    super.key,
  });

  final bool enabled;
  final PlaybackController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return _buildCard(context, null);

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) => _buildCard(context, controller),
    );
  }

  Widget _buildCard(BuildContext context, PlaybackController? playback) {
    final duration = playback?.duration ?? Duration.zero;
    final position = playback?.position ?? Duration.zero;
    final maxMilliseconds = duration.inMilliseconds.toDouble();
    final value = maxMilliseconds == 0
        ? 0.0
        : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
    final isPlaying = playback?.isPlaying ?? false;
    final status = playback?.status ?? PlaybackStatus.idle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Player', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              playback?.filePath ?? 'No local audio loaded',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Slider(
              value: value,
              max: maxMilliseconds == 0 ? 1 : maxMilliseconds,
              onChanged: enabled && playback != null && duration > Duration.zero
                  ? (next) =>
                        playback.seek(Duration(milliseconds: next.round()))
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_format(position)), Text(_format(duration))],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: enabled && playback != null
                      ? () => playback.seek(
                          position - const Duration(seconds: 10),
                        )
                      : null,
                  tooltip: 'Back 10 seconds',
                  icon: const Icon(Icons.replay_10_outlined),
                ),
                IconButton(
                  onPressed: enabled && playback != null
                      ? () => isPlaying ? playback.pause() : playback.play()
                      : null,
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_outlined
                        : Icons.play_arrow_outlined,
                  ),
                ),
                IconButton(
                  onPressed: enabled && playback != null
                      ? () => playback.seek(
                          position + const Duration(seconds: 10),
                        )
                      : null,
                  tooltip: 'Forward 10 seconds',
                  icon: const Icon(Icons.forward_10_outlined),
                ),
                IconButton(
                  onPressed: enabled && playback != null ? playback.stop : null,
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop_outlined),
                ),
                PopupMenuButton<double>(
                  enabled: enabled && playback != null,
                  tooltip: 'Playback speed',
                  initialValue: playback?.speed,
                  onSelected: playback?.setSpeed,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    PopupMenuItem(value: 1.0, child: Text('1.0x')),
                    PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    PopupMenuItem(value: 2.0, child: Text('2.0x')),
                  ],
                  icon: const Icon(Icons.speed_outlined),
                ),
              ],
            ),
            if (status == PlaybackStatus.loading)
              const LinearProgressIndicator(),
            if (playback?.errorMessage != null)
              Text(
                playback!.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
