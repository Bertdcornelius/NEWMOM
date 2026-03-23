import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A centralized Logger and Crash Reporting Service.
/// In a production environment, this should be hooked up to Sentry or Firebase Crashlytics.
class LoggerService {
  
  /// Logs an informational message.
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('💡 [INFO]: $message');
    }
    // TODO: Send to remote observability tool if in production.
  }

  /// Logs a warning that doesn't crash the app but should be investigated.
  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARN]: $message');
    }
  }

  /// Logs a critical error or exception.
  static void error(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🛑 [ERROR]: $message');
      debugPrint('Exception: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    } else {
      Sentry.captureException(
        error, 
        stackTrace: stackTrace, 
        withScope: (scope) => scope.setExtra('context', message)
      );
    }
  }

  /// Initializes the global error catchers for Flutter.
  static void initErrorHandler() {
    // Catch Flutter framework errors (like layout Render exceptions)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      error("Flutter Framework Error: ${details.exception}", details.exception, details.stack);
    };

    // Catch asynchronous Dart errors (like failed Futures)
    PlatformDispatcher.instance.onError = (dynamic exception, StackTrace stackTrace) {
      error("Asynchronous Dart Error: $exception", exception, stackTrace);
      return true; // Return true to signify the error was handled.
    };
  }

  /// A helper to show a user-friendly error SnackBar.
  static void showUIError(BuildContext context, String userMessage) {
    if (!context.mounted) return;
    
    // Check if there's already a snackbar to avoid spamming the user
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(userMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
