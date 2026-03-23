import 'package:flutter/material.dart';

/// Centralized error handler to provide consistent, user-facing error messages.
class ErrorHandler {
  static void showError(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F), // Muted red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white70,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      )
    );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4ACCA1), // NeoColors.mintGreen
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      )
    );
  }
}
