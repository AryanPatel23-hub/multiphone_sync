import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/connection_state.dart';
import '../../state/connection_controller.dart';
import '../room/widgets/room_code_card.dart';
import '../room/widgets/room_playback_controls.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({required this.room, super.key});

  final RoomRouteArguments room;

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late final ConnectionController _connection;

  @override
  void initState() {
    super.initState();
    _connection = ConnectionController()..addListener(_refresh);
    _connection.startHost(widget.room);
  }

  @override
  void dispose() {
    _connection
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connection.state == DeviceConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.roomName),
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
            roomName: widget.room.roomName,
            roomCode: widget.room.roomCode,
            role: 'Host',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isConnected
                        ? Icons.wifi_tethering_outlined
                        : Icons.sync_problem_outlined,
                    color: isConnected
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Connection'),
                  subtitle: Text(
                    _connection.errorMessage ??
                        (isConnected
                            ? 'WebSocket server ready'
                            : 'Starting WebSocket server...'),
                  ),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: isConnected
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                if (_connection.endpoint != null)
                  ListTile(
                    leading: const Icon(Icons.link_outlined),
                    title: const Text('Host Endpoint'),
                    subtitle: Text(_connection.endpoint!),
                  ),
                ExpansionTile(
                  leading: const Icon(Icons.devices_other_outlined),
                  title: const Text('Connected Devices'),
                  subtitle: Text(
                    '${_connection.devices.length} / ${widget.room.deviceLimit} connected',
                  ),
                  children: _connection.devices.isEmpty
                      ? const [
                          ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('No devices connected yet.'),
                          ),
                        ]
                      : _connection.devices
                            .map(
                              (device) => ListTile(
                                leading: const Icon(
                                  Icons.phone_android_outlined,
                                ),
                                title: Text(device.deviceName),
                                subtitle: const Text('Connected'),
                                trailing: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            )
                            .toList(),
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

  void _refresh() {
    if (mounted) setState(() {});
  }
}
