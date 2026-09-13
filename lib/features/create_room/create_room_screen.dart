import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomNameController = TextEditingController(text: 'My Room');
  int _deviceLimit = 5;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Room Name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _roomNameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(hintText: 'My Room'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Device Limit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _deviceLimit > 2
                            ? () => setState(() => _deviceLimit--)
                            : null,
                        tooltip: 'Decrease device limit',
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '$_deviceLimit',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: _deviceLimit < 5
                            ? () => setState(() => _deviceLimit++)
                            : null,
                        tooltip: 'Increase device limit',
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      AppRoutes.host,
                      arguments: RoomRouteArguments(
                        roomName: _roomNameController.text.trim().isEmpty
                            ? 'My Room'
                            : _roomNameController.text.trim(),
                        roomCode: AppConstants.demoRoomCode,
                        deviceLimit: _deviceLimit,
                      ),
                    ),
                    icon: const Icon(Icons.wifi_tethering_outlined),
                    label: const Text('Create Room'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
