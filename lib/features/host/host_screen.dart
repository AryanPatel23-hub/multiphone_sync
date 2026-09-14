import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/routes.dart';
import '../../models/connection_state.dart';
import '../../state/audio_server_controller.dart';
import '../../state/connection_controller.dart';
import '../../state/playback_controller.dart';
import '../../state/playback_queue_controller.dart';
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
  late final AudioServerController _audioServer;
  late final PlaybackController _playback;
  late final PlaybackQueueController _queue;
  late final TextEditingController _audioPathController;

  @override
  void initState() {
    super.initState();
    _connection = ConnectionController()..addListener(_refresh);
    _audioServer = AudioServerController()..addListener(_refresh);
    _playback = PlaybackController(
      connection: _connection,
      broadcastCommands: true,
    )..addListener(_refresh);
    _queue = PlaybackQueueController()..addListener(_refresh);
    _audioPathController = TextEditingController();
    _connection.startHost(widget.room);
  }

  @override
  void dispose() {
    _audioPathController.dispose();
    _playback
      ..removeListener(_refresh)
      ..dispose();
    _queue
      ..removeListener(_refresh)
      ..dispose();
    _audioServer
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
      appBar: AppBar(
        title: Text(widget.room.roomName),
        actions: [
          IconButton(
            onPressed: _showRoomQr,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Local Audio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _audioPathController,
                    decoration: const InputDecoration(
                      labelText: 'Audio file path',
                      hintText: '/storage/emulated/0/Music/song.mp3',
                      prefixIcon: Icon(Icons.audio_file_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadAudio,
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Load Audio'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exposeAudio(),
                    icon: const Icon(Icons.http_outlined),
                    label: const Text('Expose Audio on Local Network'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                _audioServer.status == AudioServerStatus.ready
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: _audioServer.status == AudioServerStatus.ready
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: const Text('Local Audio Server'),
              subtitle: Text(
                _audioServer.errorMessage ??
                    (_audioServer.endpoint ?? 'No audio exposed yet.'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQueue(context),
          const SizedBox(height: 16),
          RoomPlaybackControls(enabled: true, controller: _playback),
        ],
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _exposeAudio() async {
    final path = _audioPathController.text.trim();
    await _audioServer.exposeFile(path, duration: _playback.duration);
    final metadata = _audioServer.metadata;
    final endpoint = _audioServer.endpoint;
    if (metadata != null && endpoint != null) {
      _connection.send('AUDIO_INFO', {
        'audioId': metadata.audioId,
        'fileName': metadata.fileName,
        'format': metadata.format,
        'size': metadata.size,
        'checksum': metadata.checksum,
        'durationMs': metadata.duration?.inMilliseconds,
        'url': endpoint,
      });
    }
  }

  Future<void> _loadAudio() async {
    final path = _audioPathController.text.trim();
    await _playback.loadFile(path);
    if (_playback.filePath != null) _queue.add(_playback.filePath!);
  }

  Widget _buildQueue(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.queue_music_outlined),
            title: const Text('Playback Queue'),
            subtitle: Text('${_queue.items.length} track(s)'),
            trailing: IconButton(
              onPressed: _queue.currentIndex + 1 >= _queue.items.length
                  ? null
                  : _playNext,
              tooltip: 'Play next track',
              icon: const Icon(Icons.skip_next_outlined),
            ),
          ),
          if (_queue.items.isEmpty)
            const ListTile(
              dense: true,
              title: Text('Load local audio to add it to the queue.'),
            )
          else
            ..._queue.items.asMap().entries.map(
              (entry) => ListTile(
                dense: true,
                selected: entry.key == _queue.currentIndex,
                leading: Text('${entry.key + 1}'),
                title: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  onPressed: () => _queue.removeAt(entry.key),
                  tooltip: 'Remove track',
                  icon: const Icon(Icons.close_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _playNext() async {
    final next = _queue.next();
    if (next == null) return;
    await _playback.loadFile(next);
    await _playback.play();
  }

  void _showRoomQr() {
    final endpoint = _connection.endpoint;
    final data = Uri(
      scheme: 'multiphonesync',
      host: 'join',
      queryParameters: {
        'roomCode': widget.room.roomCode,
        'host': endpoint == null
            ? widget.room.hostAddress
            : Uri.parse(endpoint).host,
        'port': widget.room.port.toString(),
      },
    ).toString();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: data, size: 220),
            const SizedBox(height: 12),
            Text(
              widget.room.roomCode,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
