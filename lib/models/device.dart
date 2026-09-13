import 'connection_state.dart';

class Device {
  const Device({
    required this.deviceId,
    required this.deviceName,
    required this.role,
    required this.connectionState,
  });

  final String deviceId;
  final String deviceName;
  final DeviceRole role;
  final DeviceConnectionState connectionState;

  Device copyWith({
    String? deviceName,
    DeviceConnectionState? connectionState,
  }) {
    return Device(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      role: role,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}
