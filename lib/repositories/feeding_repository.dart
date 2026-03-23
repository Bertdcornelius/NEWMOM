import '../core/result.dart';
import '../services/local_database_service.dart';
import '../services/offline_sync_service.dart';
import 'base_repository.dart';

class FeedingRepository extends BaseRepository {
  final LocalDatabaseService _localDb;
  final OfflineSyncService? _offlineSync;
  static const String _cacheKey = 'feeds_cache';

  FeedingRepository(this._localDb, {OfflineSyncService? offlineSync}) : _offlineSync = offlineSync;

  Future<Result<void>> saveFeed(Map<String, dynamic> feedData) async {
    return _insertWithCache('feeds', _cacheKey, feedData);
  }

  Future<Result<List<Map<String, dynamic>>>> getFeeds({int limit = 100, DateTime? startDate}) async {
    try {
      dynamic query = supabase.from('feeds').select();
      if (startDate != null) {
        query = query.gte('created_at', startDate.toUtc().toIso8601String());
      }
      final data = await query.order('created_at', ascending: false).limit(limit);
      await _localDb.cacheData(_cacheKey, data);
      return Success(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      final cached = await _localDb.getCachedData(_cacheKey);
      if (cached != null) {
        return Success(List<Map<String, dynamic>>.from(cached));
      }
      return Failure('Cannot connect to network and no offline data found', e as Exception);
    }
  }

  Future<Result<Map<String, dynamic>?>> getLastFeed() async {
    return execute(() async {
      return await supabase.from('feeds').select().order('created_at', ascending: false).limit(1).maybeSingle();
    }, errorMessage: 'Failed to retrieve last feed');
  }

  Future<Result<void>> deleteFeed(String id) async {
    return _deleteWithCache('feeds', id, _cacheKey);
  }

  Future<Result<void>> updateFeed(String id, Map<String, dynamic> updates) async {
    return _updateWithCache('feeds', id, updates, _cacheKey);
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
