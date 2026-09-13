import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/audio.dart';
import '../../models/connection_state.dart';
import '../../state/connection_controller.dart';
import '../../state/transfer_controller.dart';
import '../../models/transfer_state.dart';
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
  late final TransferController _transfer;
  late final TextEditingController _hostAddressController;
  late final TextEditingController _audioUrlController;
  late final TextEditingController _audioSizeController;
  late final TextEditingController _audioChecksumController;

  @override
  void initState() {
    super.initState();
    _connection = ConnectionController()..addListener(_refresh);
    _transfer = TransferController()..addListener(_refresh);
    _hostAddressController = TextEditingController(
      text: widget.room.hostAddress,
    );
    _audioUrlController = TextEditingController();
    _audioSizeController = TextEditingController();
    _audioChecksumController = TextEditingController();
  }

  @override
  void dispose() {
    _hostAddressController.dispose();
    _audioUrlController.dispose();
    _audioSizeController.dispose();
    _audioChecksumController.dispose();
    _transfer
      ..removeListener(_refresh)
      ..dispose();
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
                    isConnected ? Icons.link_outlined : Icons.link_off_outlined,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Audio Download',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Downloads use a temporary file until later verification.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audioUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Host audio URL',
                      hintText: 'http://192.168.1.10:4041/audio/<audioId>',
                      prefixIcon: Icon(Icons.link_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audioSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expected size in bytes',
                      prefixIcon: Icon(Icons.data_usage_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audioChecksumController,
                    decoration: const InputDecoration(
                      labelText: 'Expected SHA-256 checksum',
                      prefixIcon: Icon(Icons.fingerprint_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        _transfer.snapshot.status ==
                                TransferStatus.downloading ||
                            _transfer.snapshot.status ==
                                TransferStatus.verifying
                        ? null
                        : _downloadAudio,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download Audio'),
                  ),
                  if (_transfer.snapshot.status ==
                      TransferStatus.downloading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _transfer.snapshot.progress),
                    const SizedBox(height: 6),
                    Text(
                      '${_transfer.snapshot.bytesReceived} / ${_transfer.snapshot.totalBytes} bytes',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_transfer.snapshot.status == TransferStatus.verifying)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Verifying audio...'),
                        ],
                      ),
                    ),
                  if (_transfer.snapshot.status == TransferStatus.completed)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Audio verified; cache promotion is pending.',
                      ),
                    ),
                  if (_transfer.snapshot.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _transfer.snapshot.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
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

  Future<void> _downloadAudio() async {
    final source = Uri.tryParse(_audioUrlController.text.trim());
    final size = int.tryParse(_audioSizeController.text.trim());
    if (source == null || !source.hasScheme || size == null || size < 0) {
      setState(() {});
      return;
    }
    final audioId = source.pathSegments.isEmpty ? '' : source.pathSegments.last;
    await _transfer.download(
      source,
      AudioMetadata(
        audioId: audioId,
        fileName: 'download.mp3',
        format: 'mp3',
        size: size,
        checksum: _audioChecksumController.text.trim(),
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}
