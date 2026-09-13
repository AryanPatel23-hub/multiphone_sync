import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void warning(String message) {
    debugPrint('[WARNING] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message${error == null ? '' : ': $error'}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
