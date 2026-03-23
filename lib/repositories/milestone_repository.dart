import '../core/result.dart';
import '../services/local_database_service.dart';
import 'base_repository.dart';

class MilestoneRepository extends BaseRepository {
  final LocalDatabaseService _localDb;
  static const String _cacheKey = 'milestones_cache';

  MilestoneRepository(this._localDb);

  Future<Result<void>> saveMilestone(Map<String, dynamic> data) async {
    return execute(() async {
      await supabase.from('milestones').insert(data);
      await _localDb.clearCache(_cacheKey);
    }, errorMessage: 'Failed to save milestone');
  }

  Future<Result<List<Map<String, dynamic>>>> getMilestones() async {
    try {
      final data = await supabase.from('milestones').select().order('date');
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

  Future<Result<void>> deleteMilestone(String id) async {
    return execute(() async {
      await supabase.from('milestones').delete().eq('id', id);
      await _localDb.clearCache(_cacheKey);
    }, errorMessage: 'Failed to delete milestone');
  }

  Future<Result<void>> updateMilestone(String id, Map<String, dynamic> updates) async {
    return execute(() async {
      await supabase.from('milestones').update(updates).eq('id', id);
      await _localDb.clearCache(_cacheKey);
    }, errorMessage: 'Failed to update milestone');
  }
}
