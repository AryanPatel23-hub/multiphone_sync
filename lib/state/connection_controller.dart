import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../app/routes.dart';
import '../models/connection_state.dart';
import '../models/device.dart';
import '../services/websocket/websocket_client.dart';
import '../services/websocket/websocket_message.dart';
import '../services/websocket/websocket_server.dart';

class ConnectionController extends ChangeNotifier {
  ConnectionController({WebSocketServer? server, WebSocketClient? client})
    : _server = server ?? WebSocketServer(),
      _client = client ?? WebSocketClient();

  final WebSocketServer _server;
  final WebSocketClient _client;
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  final devices = <Device>[];
  String? errorMessage;
  String? endpoint;
  StreamSubscription<WebSocketMessage>? _serverEvents;
  StreamSubscription<WebSocketMessage>? _clientMessages;

  Future<void> startHost(RoomRouteArguments room) async {
    state = DeviceConnectionState.connecting;
    errorMessage = null;
    notifyListeners();
    try {
      await _server.start(roomCode: room.roomCode);
      endpoint = 'ws://${await _findHostAddress()}:${_server.boundPort}/ws';
      _serverEvents ??= _server.events.stream.listen(_handleHostEvent);
      state = DeviceConnectionState.connected;
    } catch (error) {
      state = DeviceConnectionState.error;
      errorMessage = 'Unable to start the Host connection.';
    }
    notifyListeners();
  }

  Future<void> connectClient({
    required RoomRouteArguments room,
    required String host,
    required String deviceName,
  }) async {
    state = DeviceConnectionState.connecting;
    errorMessage = null;
    notifyListeners();
    try {
      _clientMessages ??= _client.messages.stream.listen(_handleClientMessage);
      final deviceId = 'client-${DateTime.now().microsecondsSinceEpoch}';
      await _client.connect(
        host: host,
        port: room.port,
        connectMessage: _message('CONNECT', {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'role': 'client',
        }),
        joinMessage: _message('JOIN_ROOM', {
          'roomCode': room.roomCode,
          'deviceId': deviceId,
          'deviceName': deviceName,
        }),
      );
      state = DeviceConnectionState.connected;
    } catch (error) {
      state = DeviceConnectionState.error;
      errorMessage = 'Unable to connect to the Host.';
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _client.disconnect();
    state = DeviceConnectionState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _serverEvents?.cancel();
    _clientMessages?.cancel();
    _client.dispose();
    _server.dispose();
    super.dispose();
  }

  void _handleHostEvent(WebSocketMessage message) {
    final deviceId = message.payload['deviceId'];
    final deviceName = message.payload['deviceName'];
    if (message.type != 'JOIN_ROOM' ||
        deviceId is! String ||
        deviceName is! String) {
      return;
    }
    devices.removeWhere((device) => device.deviceId == deviceId);
    devices.add(
      Device(
        deviceId: deviceId,
        deviceName: deviceName,
        role: DeviceRole.client,
        connectionState: DeviceConnectionState.connected,
      ),
    );
    notifyListeners();
  }

  void _handleClientMessage(WebSocketMessage message) {
    if (message.type == 'ROOM_STATE') {
      state = DeviceConnectionState.connected;
    } else if (message.type == 'ERROR' || message.type == 'DISCONNECT') {
      state = DeviceConnectionState.error;
      errorMessage =
          message.payload['message'] as String? ?? 'Connection lost.';
    }
    notifyListeners();
  }

  WebSocketMessage _message(String type, Map<String, dynamic> payload) {
    return WebSocketMessage(
      type: type,
      messageId: '$type-${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: payload,
    );
  }

  Future<String> _findHostAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) return address.address;
      }
    }
    return '127.0.0.1';
  }
}
