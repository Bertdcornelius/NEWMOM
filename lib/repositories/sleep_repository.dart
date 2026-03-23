import '../core/result.dart';
import '../services/local_database_service.dart';
import '../services/offline_sync_service.dart';
import 'base_repository.dart';

/// Handles all sleep-related database interactions.
class SleepRepository extends BaseRepository {
  final LocalDatabaseService _localDb;
  final OfflineSyncService? _offlineSync;
  static const String _cacheKey = 'sleep_logs_cache';

  SleepRepository(this._localDb, {OfflineSyncService? offlineSync}) : _offlineSync = offlineSync;

  Future<Result<void>> saveSleepLog(Map<String, dynamic> sleepData) async {
    return _insertWithCache('sleep_logs', _cacheKey, sleepData);
  }

  Future<Result<List<Map<String, dynamic>>>> getSleepLogs({int limit = 100, DateTime? startDate}) async {
    try {
      dynamic query = supabase.from('sleep_logs').select();
      if (startDate != null) {
        query = query.gte('created_at', startDate.toUtc().toIso8601String());
      }
      final data = await query.order('created_at', ascending: false).limit(limit);
      await _localDb.cacheData(_cacheKey, data);
      return Success(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      // Fallback to SQLite cache on network failure, instead of throwing an error
      final cached = await _localDb.getCachedData(_cacheKey);
      if (cached != null) {
        return Success(List<Map<String, dynamic>>.from(cached));
      }
      return Failure('Cannot connect to network and no offline data found', e as Exception);
    }
  }

  Future<Result<void>> deleteSleepLog(String id) async {
    return _deleteWithCache('sleep_logs', id, _cacheKey);
  }

  Future<Result<void>> updateSleepLog(String id, Map<String, dynamic> updates) async {
    return _updateWithCache('sleep_logs', id, updates, _cacheKey);
  }

  Future<Result<void>> _insertWithCache(String table, String cacheKey, Map<String, dynamic> data) async {
    return executeOfflineMutation(
      action: () async {
        await supabase.from(table).insert(data);
        await _localDb.clearCache(cacheKey);
      },
      offlineSync: _offlineSync,
      table: table,
      method: 'insert',
      data: data,
      errorMessage: 'Failed to save to $table'
    );
  }

  Future<Result<void>> _deleteWithCache(String table, String id, String cacheKey) async {
    return executeOfflineMutation(
      action: () async {
        await supabase.from(table).delete().eq('id', id);
        await _localDb.clearCache(cacheKey);
      },
      offlineSync: _offlineSync,
      table: table,
      method: 'delete',
      data: {},
      matchKey: 'id',
      matchValue: id,
      errorMessage: 'Failed to delete from $table'
    );
  }

  Future<Result<void>> _updateWithCache(String table, String id, Map<String, dynamic> updates, String cacheKey) async {
    return executeOfflineMutation(
      action: () async {
        await supabase.from(table).update(updates).eq('id', id);
        await _localDb.clearCache(cacheKey);
      },
      offlineSync: _offlineSync,
      table: table,
      method: 'update',
      data: updates,
      matchKey: 'id',
      matchValue: id,
      errorMessage: 'Failed to update $table'
    );
  }
}
