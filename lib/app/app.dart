import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import 'routes.dart';
import 'theme.dart';

class MultiPhoneSyncApp extends StatelessWidget {
  const MultiPhoneSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: (settings) {
        AppLogger.warning('Unknown route: ${settings.name}');
        return MaterialPageRoute<void>(
          builder: (_) => const AppRouteNotFoundScreen(),
          settings: settings,
        );
      },
    );
  }
}
