import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineSyncAction {
  final String id;
  final String table;
  final String method; // 'insert', 'update', 'delete'
  final Map<String, dynamic> data;
  final String? matchKey;
  final dynamic matchValue;

  OfflineSyncAction({
    required this.id,
    required this.table,
    required this.method,
    required this.data,
    this.matchKey,
    this.matchValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'method': method,
        'data': data,
        'matchKey': matchKey,
        'matchValue': matchValue,
      };

  factory OfflineSyncAction.fromJson(Map<String, dynamic> json) =>
      OfflineSyncAction(
        id: json['id'],
        table: json['table'],
        method: json['method'],
        data: json['data'] as Map<String, dynamic>,
        matchKey: json['matchKey'],
        matchValue: json['matchValue'],
      );
}

class OfflineSyncService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  Timer? _retryTimer;
  
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Useful for tests where Supabase isn't initialized
    }
  }
  
  static const String _queueKey = 'offline_sync_queue';
  bool _isSyncing = false;

  OfflineSyncService(this._localStorageService) {
    // Attempt sync on startup
    syncPendingActions();
    // Retry every 30 seconds so queued actions sync when connectivity returns
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncPendingActions();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Expose queue for testing and UI display
  List<OfflineSyncAction> get queue => _getQueue();

  /// Add a failed action to the local queue
  Future<void> enqueueAction(
    String table,
    String method,
    Map<String, dynamic> data, {
    String? matchKey,
    dynamic matchValue,
  }) async {
    try {
      final queue = _getQueue();
      final action = OfflineSyncAction(
        id: const Uuid().v4(),
        table: table,
        method: method,
        data: data,
        matchKey: matchKey,
        matchValue: matchValue,
      );
      queue.add(action);
      await _saveQueue(queue);
      if (kDebugMode) debugPrint('Added to offline queue: ${action.method} on ${action.table}');
      
      // Attempt to sync immediately just in case
      syncPendingActions();
    } catch (e) {
      if (kDebugMode) debugPrint('Error enqueueing offline action: $e');
    }
  }

  /// Process all pending actions
  Future<void> syncPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final queue = _getQueue();
      if (queue.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) debugPrint('Attempting to sync ${queue.length} offline actions...');
      
      final failedActions = <OfflineSyncAction>[];

      final client = _client;
      if (client == null) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      for (final action in queue) {
        try {
          if (action.method == 'insert') {
            await client.from(action.table).insert(action.data);
          } else if (action.method == 'update') {
            await client.from(action.table).update(action.data).eq(action.matchKey!, action.matchValue);
          } else if (action.method == 'delete') {
            await client.from(action.table).delete().eq(action.matchKey!, action.matchValue);
          }
          if (kDebugMode) debugPrint('Successfully synced offline action: ${action.id}');
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to sync offline action ${action.id}: $e');
          // If it fails again, keep it in the queue for the next retry
          failedActions.add(action);
        }
      }

      await _saveQueue(failedActions);
      if (kDebugMode) debugPrint('Sync complete. ${failedActions.length} actions remaining in queue.');

    } catch (e) {
      if (kDebugMode) debugPrint('Fatal error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  List<OfflineSyncAction> _getQueue() {
    final String? jsonString = _localStorageService.getString(_queueKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((e) => OfflineSyncAction.fromJson(e)).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('Error decoding offline queue: $e');
        return [];
      }
    }
    return [];
  }

  Future<void> _saveQueue(List<OfflineSyncAction> queue) async {
    final jsonList = queue.map((e) => e.toJson()).toList();
    await _localStorageService.saveString(_queueKey, jsonEncode(jsonList));
  }
}
