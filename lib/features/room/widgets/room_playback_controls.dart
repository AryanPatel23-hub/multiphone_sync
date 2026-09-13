import 'package:flutter/material.dart';

class RoomPlaybackControls extends StatelessWidget {
  const RoomPlaybackControls({required this.enabled, super.key});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Player', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0:00'), Text('0:00')],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: enabled ? () {} : null,
                  tooltip: 'Previous',
                  icon: const Icon(Icons.skip_previous_outlined),
                ),
                IconButton.filled(
                  onPressed: enabled ? () {} : null,
                  tooltip: 'Play',
                  icon: const Icon(Icons.play_arrow_outlined),
                ),
                IconButton(
                  onPressed: enabled ? () {} : null,
                  tooltip: 'Next',
                  icon: const Icon(Icons.skip_next_outlined),
                ),
                IconButton(
                  onPressed: enabled ? () {} : null,
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
