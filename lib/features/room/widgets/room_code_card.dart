import 'package:flutter/material.dart';

class RoomCodeCard extends StatelessWidget {
  const RoomCodeCard({
    required this.roomName,
    required this.roomCode,
    required this.role,
    super.key,
  });

  final String roomName;
  final String roomCode;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(roomName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              'Room Code',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              roomCode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(role),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
