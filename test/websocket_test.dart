import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_phone_sync/services/websocket/websocket_client.dart';
import 'package:multi_phone_sync/services/websocket/websocket_message.dart';
import 'package:multi_phone_sync/services/websocket/websocket_server.dart';

void main() {
  test('encodes and validates the versioned message envelope', () {
    const message = WebSocketMessage(
      type: 'CONNECT',
      messageId: 'message-1',
      timestamp: 1000,
      payload: {'deviceId': 'device-1'},
    );

    final decoded = WebSocketMessage.decode(message.encode());

    expect(decoded.version, 1);
    expect(decoded.type, 'CONNECT');
    expect(decoded.payload['deviceId'], 'device-1');
  });

  test('rejects malformed messages without throwing application errors', () {
    expect(
      () => WebSocketMessage.decode('{"type":"CONNECT"}'),
      throwsFormatException,
    );
    expect(
      () => WebSocketMessage.decode(
        '{"version":1,"type":"UNKNOWN",'
        '"messageId":"1","timestamp":1,"payload":{}}',
      ),
      throwsFormatException,
    );
  });

  test(
    'connects a client, validates room code, and exchanges room state',
    () async {
      final server = WebSocketServer(port: 0);
      final client = WebSocketClient();
      final roomState = Completer<WebSocketMessage>();
      final joinEvent = Completer<WebSocketMessage>();
      final command = Completer<WebSocketMessage>();

      final serverSubscription = server.events.stream.listen((message) {
        if (!joinEvent.isCompleted) joinEvent.complete(message);
      });
      final clientSubscription = client.messages.stream.listen((message) {
        if (message.type == 'ROOM_STATE' && !roomState.isCompleted) {
          roomState.complete(message);
        }
        if (message.type == 'PLAY' && !command.isCompleted) {
          command.complete(message);
        }
      });

      await server.start(roomCode: '4827');
      await client.connect(
        host: '127.0.0.1',
        port: server.boundPort,
        connectMessage: _message('CONNECT', {
          'deviceId': 'device-1',
          'deviceName': 'Test Client',
          'role': 'client',
        }),
        joinMessage: _message('JOIN_ROOM', {
          'roomCode': '4827',
          'deviceId': 'device-1',
          'deviceName': 'Test Client',
        }),
      );

      final receivedRoomState = await roomState.future.timeout(
        const Duration(seconds: 2),
      );
      final receivedJoin = await joinEvent.future.timeout(
        const Duration(seconds: 2),
      );

      expect(receivedRoomState.type, 'ROOM_STATE');
      expect(receivedJoin.payload['roomCode'], '4827');

      server.broadcast(_message('PLAY', {'positionMs': 0}));
      expect(
        (await command.future.timeout(const Duration(seconds: 2))).type,
        'PLAY',
      );

      await clientSubscription.cancel();
      await serverSubscription.cancel();
      await client.dispose();
      await server.dispose();
    },
  );
}

WebSocketMessage _message(String type, Map<String, dynamic> payload) {
  return WebSocketMessage(
    type: type,
    messageId: '$type-test',
    timestamp: DateTime.now().millisecondsSinceEpoch,
    payload: payload,
  );
}
