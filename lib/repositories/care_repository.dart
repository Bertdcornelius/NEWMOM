import 'dart:typed_data';
import '../core/result.dart';
import '../services/local_database_service.dart';
import '../services/offline_sync_service.dart';
import 'base_repository.dart';

/// Handles all miscellaneous baby care tracking features.
class CareRepository extends BaseRepository {
  final LocalDatabaseService _localDb;
  final OfflineSyncService? _offlineSync;

  CareRepository(this._localDb, {OfflineSyncService? offlineSync}) : _offlineSync = offlineSync;

  // --- Generic Fetcher ---
  Future<Result<List<Map<String, dynamic>>>> _fetchWithCache(String table, String cacheKey, {String? orderBy, bool ascending = false, int? limit, DateTime? startDate, String dateColumn = 'created_at'}) async {
    try {
      dynamic query = supabase.from(table).select();
      if (startDate != null) query = query.gte(dateColumn, startDate.toUtc().toIso8601String());
      if (orderBy != null) query = query.order(orderBy, ascending: ascending);
      if (limit != null) query = query.limit(limit);
      
      final data = await query;
      await _localDb.cacheData(cacheKey, data);
      return Success(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      final cached = await _localDb.getCachedData(cacheKey);
      if (cached != null) return Success(List<Map<String, dynamic>>.from(cached));
      return Failure('Network unavailable for $table', e as Exception);
    }
  }

  // --- Generic Writer ---
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

  // --- Generic Streamer ---
  Stream<List<Map<String, dynamic>>> _stream(String table, String cacheKey, {String? orderBy, bool ascending = false, int? limit}) {
    dynamic s = supabase.from(table).stream(primaryKey: ['id']);
    if (orderBy != null) s = s.order(orderBy, ascending: ascending);
    if (limit != null) s = s.limit(limit);
    return (s as Stream<List<Map<String, dynamic>>>).map((data) {
      _localDb.cacheData(cacheKey, data);
      return data;
    });
  }

  // --- Methods ---

  // Notes
  Future<Result<List<Map<String, dynamic>>>> getNotes() => _fetchWithCache('mom_notes', 'notes_cache', orderBy: 'created_at');
  Stream<List<Map<String, dynamic>>> streamNotes() => _stream('mom_notes', 'notes_cache', orderBy: 'created_at');
  Future<Result<void>> saveNote(Map<String, dynamic> data) => _insertWithCache('mom_notes', 'notes_cache', data);
  Future<Result<void>> deleteNote(String id) => _deleteWithCache('mom_notes', id, 'notes_cache');
  Future<Result<void>> updateNote(String id, Map<String, dynamic> up) => _updateWithCache('mom_notes', id, up, 'notes_cache');

  // Diapers
  Future<Result<List<Map<String, dynamic>>>> getDiaperLogs({int limit = 100, DateTime? startDate}) => _fetchWithCache('diaper_logs', 'diapers_cache', orderBy: 'created_at', limit: limit, startDate: startDate);
  Stream<List<Map<String, dynamic>>> streamDiaperLogs({int limit = 100}) => _stream('diaper_logs', 'diapers_cache', orderBy: 'created_at', ascending: false).map((data) => data.take(limit).toList());
  Future<Result<void>> saveDiaperLog(Map<String, dynamic> data) => _insertWithCache('diaper_logs', 'diapers_cache', data);
  Future<Result<void>> deleteDiaperLog(String id) => _deleteWithCache('diaper_logs', id, 'diapers_cache');
  Future<Result<void>> updateDiaperLog(String id, Map<String, dynamic> up) => _updateWithCache('diaper_logs', id, up, 'diapers_cache');

  // Routines
  Future<Result<List<Map<String, dynamic>>>> getRoutines() => _fetchWithCache('routines', 'routines_cache', orderBy: 'time', ascending: true);
  Stream<List<Map<String, dynamic>>> streamRoutines() => _stream('routines', 'routines_cache', orderBy: 'time', ascending: true);
  Future<Result<void>> saveRoutine(Map<String, dynamic> data) => _insertWithCache('routines', 'routines_cache', data);
  Future<Result<void>> deleteRoutine(String id) => _deleteWithCache('routines', id, 'routines_cache');
  Future<Result<void>> updateRoutine(String id, Map<String, dynamic> up) => _updateWithCache('routines', id, up, 'routines_cache');

  // Vaccines
  Future<Result<List<Map<String, dynamic>>>> getVaccines() => _fetchWithCache('vaccines', 'vaccines_cache', orderBy: 'due_date', ascending: true);
  Stream<List<Map<String, dynamic>>> streamVaccines() => _stream('vaccines', 'vaccines_cache', orderBy: 'due_date', ascending: true);
  Future<Result<void>> saveVaccine(Map<String, dynamic> data) => _insertWithCache('vaccines', 'vaccines_cache', data);
  Future<Result<void>> deleteVaccine(String id) => _deleteWithCache('vaccines', id, 'vaccines_cache');
  Future<Result<void>> updateVaccine(String id, Map<String, dynamic> up) => _updateWithCache('vaccines', id, up, 'vaccines_cache');

  // Prescriptions
  Future<Result<List<Map<String, dynamic>>>> getPrescriptions() => _fetchWithCache('prescriptions', 'prescriptions_cache', orderBy: 'created_at', ascending: true);
  Stream<List<Map<String, dynamic>>> streamPrescriptions() => _stream('prescriptions', 'prescriptions_cache', orderBy: 'created_at', ascending: true);
  Future<Result<void>> savePrescription(Map<String, dynamic> data) => _insertWithCache('prescriptions', 'prescriptions_cache', data);
  Future<Result<void>> deletePrescription(String id) => _deleteWithCache('prescriptions', id, 'prescriptions_cache');
  Future<Result<void>> updatePrescription(String id, Map<String, dynamic> up) => _updateWithCache('prescriptions', id, up, 'prescriptions_cache');

  // Growth
  Future<Result<List<Map<String, dynamic>>>> getGrowthEntries() => _fetchWithCache('growth_entries', 'growth_cache', orderBy: 'timestamp');
  Stream<List<Map<String, dynamic>>> streamGrowthEntries() => _stream('growth_entries', 'growth_cache', orderBy: 'timestamp');
  Future<Result<void>> saveGrowthEntry(Map<String, dynamic> data) => _insertWithCache('growth_entries', 'growth_cache', data);
  Future<Result<void>> deleteGrowthEntry(String id) => _deleteWithCache('growth_entries', id, 'growth_cache');

  // Pumping
  Future<Result<List<Map<String, dynamic>>>> getPumpingSessions({int limit = 100, DateTime? startDate}) => _fetchWithCache('pumping_sessions', 'pumping_cache', orderBy: 'timestamp', limit: limit, startDate: startDate, dateColumn: 'timestamp');
  Stream<List<Map<String, dynamic>>> streamPumpingSessions({int limit = 100}) => _stream('pumping_sessions', 'pumping_cache', orderBy: 'timestamp').map((data) => data.take(limit).toList());
  Future<Result<void>> savePumpingSession(Map<String, dynamic> data) => _insertWithCache('pumping_sessions', 'pumping_cache', data);
  Future<Result<void>> deletePumpingSession(String id) => _deleteWithCache('pumping_sessions', id, 'pumping_cache');

  // Tummy Time
  Future<Result<List<Map<String, dynamic>>>> getTummyTimeSessions({int limit = 100, DateTime? startDate}) => _fetchWithCache('tummy_time_sessions', 'tummy_time_cache', orderBy: 'timestamp', limit: limit, startDate: startDate, dateColumn: 'timestamp');
  Stream<List<Map<String, dynamic>>> streamTummyTimeSessions({int limit = 100}) => _stream('tummy_time_sessions', 'tummy_time_cache', orderBy: 'timestamp').map((data) => data.take(limit).toList());
  Future<Result<void>> saveTummyTimeSession(Map<String, dynamic> data) => _insertWithCache('tummy_time_sessions', 'tummy_time_cache', data);
  Future<Result<void>> deleteTummyTimeSession(String id) => _deleteWithCache('tummy_time_sessions', id, 'tummy_time_cache');

  // Teething
  Future<Result<List<Map<String, dynamic>>>> getTeethingData() => _fetchWithCache('teething_data', 'teething_cache');
  Stream<List<Map<String, dynamic>>> streamTeethingData() => _stream('teething_data', 'teething_cache');
  Future<Result<void>> saveTeethingData(Map<String, dynamic> data) => _insertWithCache('teething_data', 'teething_cache', data);
  Future<Result<void>> deleteTeethingData(String id) => _deleteWithCache('teething_data', id, 'teething_cache');

  // Photo Gallery
  Future<Result<List<Map<String, dynamic>>>> getGalleryPhotos({int start = 0, int limit = 15}) async {
    try {
      final data = await supabase.from('photo_gallery').select().order('timestamp', ascending: false).range(start, start + limit - 1);
      if (start == 0) await _localDb.cacheData('gallery_cache', data);
      return Success(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (start == 0) {
        final cached = await _localDb.getCachedData('gallery_cache');
        if (cached != null) return Success(List<Map<String, dynamic>>.from(cached));
      }
      return Failure('Failed to load photos', e as Exception);
    }
  }
  Stream<List<Map<String, dynamic>>> streamGalleryPhotos() => _stream('photo_gallery', 'gallery_cache', orderBy: 'timestamp');
  
  Future<Result<void>> saveGalleryPhoto(Map<String, dynamic> data) => _insertWithCache('photo_gallery', 'gallery_cache', data);
  Future<Result<void>> deleteGalleryPhoto(String id) => _deleteWithCache('photo_gallery', id, 'gallery_cache');

  // Milestones
  Future<Result<List<Map<String, dynamic>>>> getMilestones() => _fetchWithCache('milestones', 'milestones_cache', orderBy: 'date');
  Stream<List<Map<String, dynamic>>> streamMilestones() => _stream('milestones', 'milestones_cache', orderBy: 'date');
  Future<Result<void>> saveMilestone(Map<String, dynamic> data) => _insertWithCache('milestones', 'milestones_cache', data);
  Future<Result<void>> deleteMilestone(String id) => _deleteWithCache('milestones', id, 'milestones_cache');
  Future<Result<void>> updateMilestone(String id, Map<String, dynamic> up) => _updateWithCache('milestones', id, up, 'milestones_cache');

  // Mom Care Checklist
  Future<Result<List<Map<String, dynamic>>>> getMomCareChecklist() => _fetchWithCache('mom_care_checklist', 'mom_care_cache', orderBy: 'created_at');
  Stream<List<Map<String, dynamic>>> streamMomCareChecklist() => _stream('mom_care_checklist', 'mom_care_cache', orderBy: 'created_at');
  Future<Result<void>> saveMomCareChecklist(Map<String, dynamic> data) => _insertWithCache('mom_care_checklist', 'mom_care_cache', data);
  Future<Result<void>> deleteMomCareChecklist(String id) => _deleteWithCache('mom_care_checklist', id, 'mom_care_cache');
  Future<Result<void>> updateMomCareChecklist(String id, Map<String, dynamic> up) => _updateWithCache('mom_care_checklist', id, up, 'mom_care_cache');

  // Menstrual Cycles
  Future<Result<List<Map<String, dynamic>>>> getMenstrualCycles() => _fetchWithCache('menstrual_cycles', 'menstrual_cache', orderBy: 'start_date', ascending: false);
  Stream<List<Map<String, dynamic>>> streamMenstrualCycles() => _stream('menstrual_cycles', 'menstrual_cache', orderBy: 'start_date', ascending: false);
  Future<Result<void>> saveMenstrualCycle(Map<String, dynamic> data) => _insertWithCache('menstrual_cycles', 'menstrual_cache', data);
  Future<Result<void>> deleteMenstrualCycle(String id) => _deleteWithCache('menstrual_cycles', id, 'menstrual_cache');
  Future<Result<void>> updateMenstrualCycle(String id, Map<String, dynamic> up) => _updateWithCache('menstrual_cycles', id, up, 'menstrual_cache');

  // Milk Stash
  Future<Result<List<Map<String, dynamic>>>> getMilkStash() => _fetchWithCache('milk_stash', 'milk_stash_cache', orderBy: 'expiration_date');
  Stream<List<Map<String, dynamic>>> streamMilkStash() => _stream('milk_stash', 'milk_stash_cache', orderBy: 'expiration_date');
  Future<Result<void>> saveMilkStash(Map<String, dynamic> data) => _insertWithCache('milk_stash', 'milk_stash_cache', data);
  Future<Result<void>> deleteMilkStash(String id) => _deleteWithCache('milk_stash', id, 'milk_stash_cache');
  Future<Result<void>> updateMilkStash(String id, Map<String, dynamic> up) => _updateWithCache('milk_stash', id, up, 'milk_stash_cache');

  // Mood Logs (Postpartum Wellness)
  Future<Result<List<Map<String, dynamic>>>> getMoodLogs() => _fetchWithCache('mood_logs', 'mood_logs_cache', orderBy: 'created_at');
  Stream<List<Map<String, dynamic>>> streamMoodLogs() => _stream('mood_logs', 'mood_logs_cache', orderBy: 'created_at');
  Future<Result<void>> saveMoodLog(Map<String, dynamic> data) => _insertWithCache('mood_logs', 'mood_logs_cache', data);
  Future<Result<void>> deleteMoodLog(String id) => _deleteWithCache('mood_logs', id, 'mood_logs_cache');

  // Food Introductions
  Future<Result<List<Map<String, dynamic>>>> getFoodIntroductions() => _fetchWithCache('food_introductions', 'food_intro_cache', orderBy: 'created_at');
  Stream<List<Map<String, dynamic>>> streamFoodIntroductions() => _stream('food_introductions', 'food_intro_cache', orderBy: 'created_at');
  Future<Result<void>> saveFoodIntroduction(Map<String, dynamic> data) => _insertWithCache('food_introductions', 'food_intro_cache', data);
  Future<Result<void>> deleteFoodIntroduction(String id) => _deleteWithCache('food_introductions', id, 'food_intro_cache');

  // Image Upload
  Future<Result<String>> uploadImage(String userId, String filePath, Uint8List fileBytes) async {
    return execute(() async {
      final fileName = '${DateTime.now().toIso8601String()}_${filePath.split('/').last}';
      final path = '$userId/$fileName';
      await supabase.storage.from('images').uploadBinary(path, fileBytes);
      return supabase.storage.from('images').getPublicUrl(path);
    }, errorMessage: 'Failed to upload image');
  }
}
