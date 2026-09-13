import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../room/widgets/room_code_card.dart';
import '../room/widgets/room_playback_controls.dart';

class HostScreen extends StatelessWidget {
  const HostScreen({required this.room, super.key});

  final RoomRouteArguments room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.roomName),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Share room',
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          RoomCodeCard(
            roomName: room.roomName,
            roomCode: room.roomCode,
            role: 'Host',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.wifi_tethering_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Connection'),
                  subtitle: const Text('Room ready for clients'),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.devices_other_outlined),
                  title: const Text('Connected Devices'),
                  subtitle: Text('0 / ${room.deviceLimit} connected'),
                  children: const [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No devices connected yet.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const RoomPlaybackControls(enabled: false),
        ],
      ),
    );
  }
}
