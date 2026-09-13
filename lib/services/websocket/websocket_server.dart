import 'dart:async';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import 'websocket_message.dart';

class WebSocketServer {
  WebSocketServer({this.port = 4040});

  final int port;
  HttpServer? _server;
  final _clients = <WebSocket>{};
  Timer? _heartbeatTimer;
  final events = StreamController<WebSocketMessage>.broadcast();

  Future<void> start({required String roomCode}) async {
    if (_server != null) return;

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _clients.add(socket);
        socket.listen(
          (data) => _handleMessage(socket, data, roomCode),
          onDone: () => _remove(socket),
          onError: (_) => _remove(socket),
          cancelOnError: true,
        );
      } catch (error, stackTrace) {
        AppLogger.error('WebSocket upgrade failed', error, stackTrace);
        await request.response.close();
      }
    });

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _broadcast(
        const WebSocketMessage(
          type: 'HEARTBEAT',
          messageId: 'server-heartbeat',
          timestamp: 1,
          payload: {},
        ),
      );
    });
  }

  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    for (final client in List<WebSocket>.from(_clients)) {
      await client.close(1000, 'Server stopped');
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> dispose() async {
    await stop();
    await events.close();
  }

  int get boundPort => _server?.port ?? port;

  void _handleMessage(WebSocket socket, Object? data, String roomCode) {
    try {
      final message = WebSocketMessage.decode(data);
      if (message.type == 'JOIN_ROOM' &&
          message.payload['roomCode'] != roomCode) {
        socket.add(
          const WebSocketMessage(
            type: 'ERROR',
            messageId: 'invalid-room',
            timestamp: 1,
            payload: {'code': 'INVALID_ROOM', 'message': 'Invalid room code.'},
          ).encode(),
        );
        socket.close(WebSocketStatus.policyViolation, 'Invalid room code');
        return;
      }

      if (message.type == 'JOIN_ROOM') {
        events.add(message);
      }
      socket.add(_roomStateMessage().encode());
    } on FormatException catch (error) {
      socket.add(
        WebSocketMessage(
          type: 'ERROR',
          messageId: 'malformed-message',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: {'code': 'MALFORMED_MESSAGE', 'message': error.message},
        ).encode(),
      );
    } catch (error, stackTrace) {
      AppLogger.error('WebSocket message handling failed', error, stackTrace);
    }
  }

  WebSocketMessage _roomStateMessage() {
    return WebSocketMessage(
      type: 'ROOM_STATE',
      messageId: 'room-state',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'status': 'OPEN', 'clientCount': _clients.length},
    );
  }

  void _broadcast(WebSocketMessage message) {
    for (final client in List<WebSocket>.from(_clients)) {
      try {
        client.add(message.encode());
      } catch (error, stackTrace) {
        AppLogger.error('WebSocket heartbeat failed', error, stackTrace);
        _remove(client);
      }
    }
  }

  void _remove(WebSocket socket) {
    _clients.remove(socket);
  }
}
