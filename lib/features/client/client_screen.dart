import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/connection_state.dart';
import '../../state/connection_controller.dart';
import '../room/widgets/room_code_card.dart';
import '../room/widgets/room_playback_controls.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({required this.room, super.key});

  final RoomRouteArguments room;

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  late final ConnectionController _connection;
  late final TextEditingController _hostAddressController;

  @override
  void initState() {
    super.initState();
    _connection = ConnectionController()..addListener(_refresh);
    _hostAddressController = TextEditingController(
      text: widget.room.hostAddress,
    );
  }

  @override
  void dispose() {
    _hostAddressController.dispose();
    _connection
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connection.state == DeviceConnectionState.connected;

    return Scaffold(
      appBar: AppBar(title: Text(widget.room.roomName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          RoomCodeCard(
            roomName: widget.room.roomName,
            roomCode: widget.room.roomCode,
            role: 'Client',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _hostAddressController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Host Address',
                      hintText: '192.168.1.10',
                      prefixIcon: Icon(Icons.computer_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isConnected ? null : _connect,
                    icon: const Icon(Icons.link_outlined),
                    label: Text(
                      _connection.state == DeviceConnectionState.connecting
                          ? 'Connecting...'
                          : 'Connect to Host',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isConnected
                        ? Icons.link_outlined
                        : Icons.link_off_outlined,
                    color: isConnected
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Connection'),
                  subtitle: Text(
                    _connection.errorMessage ??
                        (isConnected ? 'Connected to Host' : 'Not connected'),
                  ),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: isConnected
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                const ExpansionTile(
                  leading: Icon(Icons.devices_other_outlined),
                  title: Text('Connected Devices'),
                  subtitle: Text('Room state arrives after connection'),
                  children: [
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

  Future<void> _connect() async {
    await _connection.connectClient(
      room: widget.room,
      host: _hostAddressController.text.trim(),
      deviceName: 'Android Client',
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}
