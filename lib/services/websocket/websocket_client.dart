import 'dart:async';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import 'websocket_message.dart';

class WebSocketClient {
  WebSocket? _socket;
  Timer? _heartbeatTimeout;

  final messages = StreamController<WebSocketMessage>.broadcast();

  Future<void> connect({
    required String host,
    required int port,
    required WebSocketMessage connectMessage,
    required WebSocketMessage joinMessage,
  }) async {
    await disconnect();
    _socket = await WebSocket.connect('ws://$host:$port/ws');
    _socket!.listen(
      _handleData,
      onDone: _handleDisconnect,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('WebSocket client error', error, stackTrace);
        _handleDisconnect();
      },
      cancelOnError: true,
    );
    send(connectMessage);
    send(joinMessage);
  }

  void send(WebSocketMessage message) {
    _socket?.add(message.encode());
  }

  Future<void> disconnect() async {
    _heartbeatTimeout?.cancel();
    _heartbeatTimeout = null;
    final socket = _socket;
    _socket = null;
    await socket?.close(1000, 'Client disconnected');
  }

  void _handleData(Object? data) {
    try {
      final message = WebSocketMessage.decode(data);
      if (message.type == 'HEARTBEAT') {
        _heartbeatTimeout?.cancel();
        _heartbeatTimeout = Timer(const Duration(seconds: 25), () {
          messages.add(const WebSocketMessage(
            type: 'DISCONNECT',
            messageId: 'heartbeat-timeout',
            timestamp: 1,
            payload: {'reason': 'Heartbeat timeout'},
          ));
        });
      }
      if (!messages.isClosed) messages.add(message);
    } on FormatException catch (error) {
      if (!messages.isClosed) {
        messages.add(WebSocketMessage(
          type: 'ERROR',
          messageId: 'malformed-message',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: {'code': 'MALFORMED_MESSAGE', 'message': error.message},
        ));
      }
    }
  }

  void _handleDisconnect() {
    if (!messages.isClosed) {
      messages.add(WebSocketMessage(
        type: 'DISCONNECT',
        messageId: 'socket-closed',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: const {'reason': 'Socket closed'},
      ));
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await messages.close();
  }
}