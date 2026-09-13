import 'package:flutter/material.dart';

import '../features/client/client_screen.dart';
import '../features/create_room/create_room_screen.dart';
import '../features/home/home_screen.dart';
import '../features/host/host_screen.dart';
import '../features/join_room/join_room_screen.dart';

class RoomRouteArguments {
  const RoomRouteArguments({
    required this.roomName,
    required this.roomCode,
    this.deviceLimit = 5,
  });

  final String roomName;
  final String roomCode;
  final int deviceLimit;
}

abstract final class AppRoutes {
  static const home = '/';
  static const createRoom = '/create-room';
  static const joinRoom = '/join-room';
  static const host = '/host';
  static const client = '/client';

  static Route<void>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      home => _page(const HomeScreen(), settings),
      createRoom => _page(const CreateRoomScreen(), settings),
      joinRoom => _page(const JoinRoomScreen(), settings),
      host => _page(
        HostScreen(room: _roomArguments(settings.arguments)),
        settings,
      ),
      client => _page(ClientScreen(room: _roomArguments(settings)), settings),
      _ => null,
    };
  }

  static RoomRouteArguments _roomArguments(Object? arguments) {
    if (arguments is RoomRouteArguments) {
      return arguments;
    }

    return const RoomRouteArguments(roomName: 'Party Room', roomCode: '4827');
  }

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }
}

class AppRouteNotFoundScreen extends StatelessWidget {
  const AppRouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Return home'),
        ),
      ),
    );
  }
}
