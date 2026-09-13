import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/logging/app_logger.dart';

void main() {
  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  ErrorWidget.builder = (details) => const _ApplicationErrorWidget();
  runApp(const MultiPhoneSyncApp());
}

class _ApplicationErrorWidget extends StatelessWidget {
  const _ApplicationErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Something went wrong. Please restart the app.'),
        ),
      ),
    );
  }
}
