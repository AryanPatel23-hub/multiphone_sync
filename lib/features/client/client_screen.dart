import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../room/widgets/room_code_card.dart';
import '../room/widgets/room_playback_controls.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({required this.room, super.key});

  final RoomRouteArguments room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(room.roomName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          RoomCodeCard(
            roomName: room.roomName,
            roomCode: room.roomCode,
            role: 'Client',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.link_outlined),
                  title: Text('Connection'),
                  subtitle: Text('Waiting for Host'),
                  trailing: Icon(Icons.circle, size: 12),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.devices_other_outlined),
                  title: const Text('Connected Devices'),
                  subtitle: const Text('Waiting for room state'),
                  children: const [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No device status available yet.'),
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
