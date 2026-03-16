import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'offline_sync_service.dart';
import 'dart:convert';
import '../utils/global_keys.dart';
import 'package:flutter/material.dart';

class BabyDataRepository extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final OfflineSyncService _offlineSyncService;
  final SupabaseClient _client = Supabase.instance.client;
  
  RealtimeChannel? _feedsChannel;
  RealtimeChannel? _sleepsChannel;
  RealtimeChannel? _diapersChannel;

  BabyDataRepository(this._localStorageService, this._offlineSyncService) {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _initRealtime();
      } else {
        _feedsChannel?.unsubscribe();
        _sleepsChannel?.unsubscribe();
        _diapersChannel?.unsubscribe();
        _feedsChannel = null;
        _sleepsChannel = null;
        _diapersChannel = null;
      }
    });
  }

  void _initRealtime() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Only init if not already active
    if (_feedsChannel != null) return;

    try {
      final filterStr = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId);

      _feedsChannel = _client.channel('public:feeds').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'feeds',
        filter: filterStr,
        callback: (payload) async {
          await _invalidateCache('feeds_cache');
          notifyListeners();
        }
      ).subscribe();

      _sleepsChannel = _client.channel('public:sleep_logs').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sleep_logs',
        filter: filterStr,
        callback: (payload) async {
          await _invalidateCache('sleep_cache');
          notifyListeners();
        }
      ).subscribe();

      _diapersChannel = _client.channel('public:diaper_logs').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'diaper_logs',
        filter: filterStr,
        callback: (payload) async {
          await _invalidateCache('diaper_cache');
          notifyListeners();
        }
      ).subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('Error connecting Realtime: $e');
    }
  }

  @override
  void dispose() {
    _feedsChannel?.unsubscribe();
    _sleepsChannel?.unsubscribe();
    _diapersChannel?.unsubscribe();
    super.dispose();
  }

  User? get currentUser => _client.auth.currentUser;

  // --- Offline & Error Handling ---
  void _handleError(String actionName, dynamic error) {
    if (kDebugMode) debugPrint('Offline Queue: $actionName - $error');
    globalMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(actionName)),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _invalidateCache(String key) async {
    await _localStorageService.remove(key);
  }

  Future<void> _cacheData(String key, dynamic data) async {
    final payload = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
    await _localStorageService.saveString(key, jsonEncode(payload));
  }

  Future<dynamic> _getCachedData(String key) async {
    final String? jsonString = _localStorageService.getString(key);
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic> && decoded.containsKey('timestamp')) {
          final time = DateTime.parse(decoded['timestamp']);
          if (DateTime.now().toUtc().difference(time).inHours < 24) {
            return decoded['data'];
          } else {
            await _invalidateCache(key);
            return null; // Expired
          }
        }
        return decoded; // Fallback for old cache format
      } catch (e) {
         return null;
      }
    }
    return null;
  }

  // --- Feeds ---
  Future<void> saveFeed(Map<String, dynamic> feedData) async {
    try {
      await _client.from('feeds').insert(feedData);
      await _invalidateCache('feeds_cache');
    } catch (e) {
      _handleError('Saved offline. Will sync when connected.', e);
      _offlineSyncService.enqueueAction('feeds', 'insert', feedData);
    }
  }

  Future<void> updateFeed(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('feeds').update(updates).eq('id', id);
      await _invalidateCache('feeds_cache');
    } catch (e) {
      _handleError('Error updating feed, saving locally', e);
      _offlineSyncService.enqueueAction('feeds', 'update', updates, matchKey: 'id', matchValue: id);
    }
  }

  Future<void> deleteFeed(String id) async {
    try {
      await _client.from('feeds').delete().eq('id', id);
      await _invalidateCache('feeds_cache');
    } catch (e) {
      _handleError('Error deleting feed, saving locally', e);
      _offlineSyncService.enqueueAction('feeds', 'delete', {}, matchKey: 'id', matchValue: id);
    }
  }

  Future<List<Map<String, dynamic>>> getFeeds() async {
    const String cacheKey = 'feeds_cache';
    try {
      final data = await _client.from('feeds').select().order('created_at');
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (kDebugMode) debugPrint('Offline: Fetching feeds from cache. Error: $e');
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastFeed() async {
    try {
      return await _client.from('feeds').select().order('created_at', ascending: false).limit(1).maybeSingle();
    } catch (e) {
      final all = await getFeeds();
      if (all.isNotEmpty) {
        all.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
        return all.first;
      }
      return null;
    }
  }

  // --- Sleep Logs ---
  Future<void> saveSleepLog(Map<String, dynamic> sleepData) async {
    try {
      await _client.from('sleep_logs').insert(sleepData);
      await _invalidateCache('sleep_logs_cache');
    } catch (e) {
      _handleError('Error saving sleep log, saving locally', e);
      _offlineSyncService.enqueueAction('sleep_logs', 'insert', sleepData);
    }
  }

  Future<void> updateSleepLog(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('sleep_logs').update(updates).eq('id', id);
      await _invalidateCache('sleep_logs_cache');
    } catch (e) {
      _handleError('Error updating sleep log, saving locally', e);
      _offlineSyncService.enqueueAction('sleep_logs', 'update', updates, matchKey: 'id', matchValue: id);
    }
  }

  Future<void> deleteSleepLog(String id) async {
    try {
      await _client.from('sleep_logs').delete().eq('id', id);
      await _invalidateCache('sleep_logs_cache');
    } catch (e) {
      _handleError('Error deleting sleep log, saving locally', e);
      _offlineSyncService.enqueueAction('sleep_logs', 'delete', {}, matchKey: 'id', matchValue: id);
    }
  }

  Future<List<Map<String, dynamic>>> getSleepLogs() async {
    const String cacheKey = 'sleep_logs_cache';
    try {
      final data = await _client.from('sleep_logs').select().order('created_at', ascending: false).limit(100);
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Diaper Logs ---
  Future<void> saveDiaperLog(Map<String, dynamic> data) async {
    try {
      await _client.from('diaper_logs').insert(data);
      await _invalidateCache('diapers_cache');
    } catch (e) {
      _handleError('Error saving diaper log, saving locally', e);
      _offlineSyncService.enqueueAction('diaper_logs', 'insert', data);
    }
  }

  Future<void> updateDiaperLog(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('diaper_logs').update(updates).eq('id', id);
      await _invalidateCache('diapers_cache');
    } catch (e) {
      _handleError('Error updating diaper log, saving locally', e);
      _offlineSyncService.enqueueAction('diaper_logs', 'update', updates, matchKey: 'id', matchValue: id);
    }
  }

  Future<void> deleteDiaperLog(String id) async {
    try {
      await _client.from('diaper_logs').delete().eq('id', id);
      await _invalidateCache('diapers_cache');
    } catch (e) {
      _handleError('Error deleting diaper log, saving locally', e);
       _offlineSyncService.enqueueAction('diaper_logs', 'delete', {}, matchKey: 'id', matchValue: id);
    }
  }

  Future<List<Map<String, dynamic>>> getDiaperLogs() async {
    const String cacheKey = 'diapers_cache';
    try {
      final data = await _client.from('diaper_logs').select().order('created_at', ascending: false).limit(100);
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Milestones ---
  Future<void> saveMilestone(Map<String, dynamic> data) async {
    try {
      await _client.from('milestones').insert(data);
      await _invalidateCache('milestones_cache');
    } catch (e) {
      _handleError('Error saving milestone, saving locally', e);
      _offlineSyncService.enqueueAction('milestones', 'insert', data);
    }
  }

  Future<void> updateMilestone(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('milestones').update(updates).eq('id', id);
      await _invalidateCache('milestones_cache');
    } catch (e) {
      _handleError('Error updating milestone', e);
      _offlineSyncService.enqueueAction('milestones', 'update', updates, matchKey: 'id', matchValue: id);
    }
  }

  Future<void> deleteMilestone(String id) async {
    try {
      await _client.from('milestones').delete().eq('id', id);
      await _invalidateCache('milestones_cache');
    } catch (e) {
      _handleError('Error deleting milestone', e);
      _offlineSyncService.enqueueAction('milestones', 'delete', {}, matchKey: 'id', matchValue: id);
    }
  }

  Future<List<Map<String, dynamic>>> getMilestones() async {
    const String cacheKey = 'milestones_cache';
    try {
      final data = await _client.from('milestones').select().order('date').limit(100);
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Notes ---
  Future<void> saveNote(Map<String, dynamic> data) async {
    try {
      await _client.from('mom_notes').insert(data);
      await _invalidateCache('notes_cache');
    } catch (e) {
      _handleError('Error saving note, saving locally', e);
      _offlineSyncService.enqueueAction('mom_notes', 'insert', data);
    }
  }

  Future<void> updateNote(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('mom_notes').update(updates).eq('id', id);
      await _invalidateCache('notes_cache');
    } catch (e) {
      _handleError('Error updating note', e);
      _offlineSyncService.enqueueAction('mom_notes', 'update', updates, matchKey: 'id', matchValue: id);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _client.from('mom_notes').delete().eq('id', id);
      await _invalidateCache('notes_cache');
    } catch (e) {
      _handleError('Error deleting note', e);
      _offlineSyncService.enqueueAction('mom_notes', 'delete', {}, matchKey: 'id', matchValue: id);
    }
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    const String cacheKey = 'notes_cache';
    try {
      final data = await _client.from('mom_notes').select().order('created_at', ascending: false).limit(100);
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Routines ---
  Future<void> saveRoutine(Map<String, dynamic> data) async {
    try {
      await _client.from('routines').insert(data);
      await _invalidateCache('routines_cache');
    } catch (e) {
      _handleError('Error saving routine', e);
      rethrow;
    }
  }

  Future<void> updateRoutine(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('routines').update(updates).eq('id', id);
      await _invalidateCache('routines_cache');
    } catch (e) {
      _handleError('Error updating routine', e);
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      await _client.from('routines').delete().eq('id', id);
      await _invalidateCache('routines_cache');
    } catch (e) {
      _handleError('Error deleting routine', e);
    }
  }

  Future<List<Map<String, dynamic>>> getRoutines() async {
    const String cacheKey = 'routines_cache';
    try {
      final userId = _client.auth.currentUser?.id;
      var query = _client.from('routines').select();
      if (userId != null) query = query.eq('user_id', userId);
      final data = await query.order('time');
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _handleError('Error fetching routines', e);
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Vaccines ---
  Future<void> saveVaccine(Map<String, dynamic> data) async {
    try {
      await _client.from('vaccines').insert(data);
      await _invalidateCache('vaccines_cache');
    } catch (e) {
      _handleError('Error saving vaccine', e);
      _offlineSyncService.enqueueAction('vaccines', 'insert', data);
    }
  }

  Future<void> updateVaccine(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('vaccines').update(updates).eq('id', id);
      await _invalidateCache('vaccines_cache');
    } catch (e) {
      _handleError('Error updating vaccine', e);
    }
  }

  Future<void> deleteVaccine(String id) async {
    try {
      await _client.from('vaccines').delete().eq('id', id);
      await _invalidateCache('vaccines_cache');
    } catch (e) {
      _handleError('Error deleting vaccine', e);
    }
  }

  Future<List<Map<String, dynamic>>> getVaccines() async {
    const String cacheKey = 'vaccines_cache';
    try {
      final data = await _client.from('vaccines').select().order('due_date');
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Prescriptions ---
  Future<void> savePrescription(Map<String, dynamic> data) async {
    try {
      await _client.from('prescriptions').insert(data);
      await _invalidateCache('prescriptions_cache');
    } catch (e) {
      _handleError('Error saving prescription', e);
      _offlineSyncService.enqueueAction('prescriptions', 'insert', data);
    }
  }

  Future<void> updatePrescription(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('prescriptions').update(updates).eq('id', id);
      await _invalidateCache('prescriptions_cache');
    } catch (e) {
      _handleError('Error updating prescription', e);
    }
  }

  Future<void> deletePrescription(String id) async {
    try {
      await _client.from('prescriptions').delete().eq('id', id);
      await _invalidateCache('prescriptions_cache');
    } catch (e) {
      _handleError('Error deleting prescription', e);
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    const String cacheKey = 'prescriptions_cache';
    try {
      final data = await _client.from('prescriptions').select().order('created_at');
      await _cacheData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      final cached = await _getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // --- Profile ---
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      return await _client.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (e) {
      _handleError('Error getting profile', e);
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('profiles').upsert({'id': userId, ...updates});
    } catch (e) {
      _handleError('Error updating profile', e);
    }
  }

  // --- Image Upload ---
  Future<String?> uploadImage(String userId, String filePath, Uint8List fileBytes) async {
    try {
      final fileName = '${DateTime.now().toIso8601String()}_${filePath.split('/').last}';
      final path = '$userId/$fileName';
      await _client.storage.from('images').uploadBinary(path, fileBytes);
      return _client.storage.from('images').getPublicUrl(path);
    } catch (e) {
      _handleError('Error uploading image', e);
      return null;
    }
  }

  // --- Premium / Device ---
  Future<bool> isPremiumUser() async {
    try {
      final profile = await getProfile();
      return profile != null && profile['is_premium'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerDevice(String deviceId) async {
    try {
      final profile = await getProfile();
      if (profile == null) return true;
      if (profile['is_premium'] ?? false) return true;
      List<String> devices = List<String>.from(profile['device_ids'] ?? []);
      if (devices.contains(deviceId)) return true;
      if (devices.length >= 2) return false;
      devices.add(deviceId);
      await updateProfile({'device_ids': devices});
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Device limit check error: $e');
      return true;
    }
  }
}

