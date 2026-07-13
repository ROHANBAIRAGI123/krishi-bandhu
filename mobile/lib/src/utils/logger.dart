import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple logger utility that only logs in debug mode
class Logger {
  /// Log a message - only shows in debug mode
  static void log(String message, {String name = ''}) {
    if (kDebugMode) {
      developer.log(message, name: name);
    }
  }

  /// Log error - always shows
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info - only shows in debug mode
  static void info(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Log warning - always shows
  static void warning(String message) {
    debugPrint('⚠️ $message');
  }
}
