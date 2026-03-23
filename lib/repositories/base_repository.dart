import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/result.dart';
import '../services/offline_sync_service.dart';

/// Base repository providing robust execution wrappers to catch errors
/// and standardized Supabase Client access.
abstract class BaseRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Executes an async network or DB operation and safely returns a Result<T>
  Future<Result<T>> execute<T>(Future<T> Function() action, {String errorMessage = 'An error occurred'}) async {
    try {
      final result = await action();
      return Success(result);
    } catch (e) {
      if (e is PostgrestException) {
        return Failure(e.message, e);
      } else if (e is AuthException) {
        return Failure(e.message, e);
      }
      return Failure('$errorMessage: ${e.toString()}', e as Exception);
    }
  }

  /// Executes a mutation (insert, update, delete) and falls back to offline queue
  /// if a network/socket exception is detected.
  Future<Result<void>> executeOfflineMutation({
    required Future<void> Function() action,
    required OfflineSyncService? offlineSync,
    required String table,
    required String method,
    required Map<String, dynamic> data,
    String? matchKey,
    dynamic matchValue,
    String errorMessage = 'Mutation failed',
  }) async {
    try {
      await action();
      return Success(null);
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('clientexception') ||
          str.contains('failed host lookup') ||
          str.contains('handshake') ||
          str.contains('connection')) {
        if (offlineSync != null) {
          await offlineSync.enqueueAction(
            table,
            method,
            data,
            matchKey: matchKey,
            matchValue: matchValue,
          );
          return Success(null); // Pretend it succeeded
        }
      }
      return Failure(errorMessage, e as Exception);
    }
  }
}
