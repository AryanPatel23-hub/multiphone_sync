import 'device.dart';

class Room {
  const Room({
    required this.roomName,
    required this.roomCode,
    required this.hostId,
    required this.devices,
  });

  final String roomName;
  final String roomCode;
  final String hostId;
  final List<Device> devices;
}