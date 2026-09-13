import 'dart:convert';

const supportedWebSocketMessageTypes = {
  'CONNECT',
  'JOIN_ROOM',
  'ROOM_STATE',
  'AUDIO_INFO',
  'AUDIO_READY',
  'PLAY',
  'PAUSE',
  'STOP',
  'SEEK',
  'SYNC_REQUEST',
  'SYNC_RESPONSE',
  'PLAYBACK_STATUS',
  'HEARTBEAT',
  'ERROR',
  'DISCONNECT',
};

class WebSocketMessage {
  const WebSocketMessage({
    required this.type,
    required this.messageId,
    required this.timestamp,
    required this.payload,
    this.version = 1,
  });

  final int version;
  final String type;
  final String messageId;
  final int timestamp;
  final Map<String, dynamic> payload;

  String encode() {
    return jsonEncode({
      'version': version,
      'type': type,
      'messageId': messageId,
      'timestamp': timestamp,
      'payload': payload,
    });
  }

  static WebSocketMessage decode(Object? raw) {
    if (raw is! String) {
      throw const FormatException('WebSocket message must be text.');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('WebSocket message must be an object.');
    }

    final version = decoded['version'];
    final type = decoded['type'];
    final messageId = decoded['messageId'];
    final timestamp = decoded['timestamp'];
    final payload = decoded['payload'];

    if (version is! int || version != 1) {
      throw const FormatException('Unsupported WebSocket message version.');
    }
    if (type is! String || !supportedWebSocketMessageTypes.contains(type)) {
      throw const FormatException('Unsupported WebSocket message type.');
    }
    if (messageId is! String || messageId.isEmpty) {
      throw const FormatException('WebSocket messageId is required.');
    }
    if (timestamp is! int || timestamp <= 0) {
      throw const FormatException('WebSocket timestamp is invalid.');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('WebSocket payload must be an object.');
    }

    return WebSocketMessage(
      version: version,
      type: type,
      messageId: messageId,
      timestamp: timestamp,
      payload: payload,
    );
  }
}