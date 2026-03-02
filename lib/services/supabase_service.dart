import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'dart:convert';

class SupabaseService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseService(this._localStorageService);

  User? get currentUser => _client.auth.currentUser;

  // Auth
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    notifyListeners();
  }

  Future<UserResponse> updateUser(String email, String password) async {
       return await _client.auth.updateUser(
           UserAttributes(
               email: email,
               password: password,
           ),
       );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> resendConfirmationEmail(String email) async {
      await _client.auth.resend(
          type: OtpType.signup,
          email: email
      );
  }

  // Data Methods (Placeholders)
  // --- Invalidation Helpers ---
  Future<void> _invalidateCache(String key) async {
      await _localStorageService.remove(key);
  }

  // --- Methods with Cache Invalidation ---

  Future<void> saveFeed(Map<String, dynamic> feedData) async {
    try {
      await _client.from('feeds').insert(feedData);
      _invalidateCache('feeds_cache');
    } catch (e) {
      if (kDebugMode) print('Error saving feed: $e');
    }
  }
  
  Future<void> saveSleepLog(Map<String, dynamic> sleepData) async {
    try {
      await _client.from('sleep_logs').insert(sleepData);
      _invalidateCache('sleep_logs_cache');
    } catch (e) {
      if (kDebugMode) print('Error saving sleep log: $e');
    }
  }

  Future<void> saveMilestone(Map<String, dynamic> data) async {
      await _client.from('milestones').insert(data);
      _invalidateCache('milestones_cache');
  }

  // ... (Getters) ...
  Future<Map<String, dynamic>?> getProfile() async {
      try {
          final userId = _client.auth.currentUser?.id;
          if (userId == null) return null;
          final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
          return data;
      } catch (e) {
          if (kDebugMode) print('Error getting profile: $e');
          return null;
      }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('profiles').upsert({'id': userId, ...updates});
  }

  // Offline Caching Helpers
  Future<void> _cacheData(String key, dynamic data) async {
    await _localStorageService.saveString(key, jsonEncode(data));
  }

  Future<dynamic> _getCachedData(String key) async {
    final String? jsonString = _localStorageService.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  // Fetch data with Offline Support
  Future<List<Map<String, dynamic>>> getFeeds() async {
      const String cacheKey = 'feeds_cache';
      try {
          final data = await _client.from('feeds').select().order('created_at');
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          if (kDebugMode) print('Offline: Fetching feeds from cache. Error: $e');
          final cached = await _getCachedData(cacheKey);
          if (cached != null) {
              return List<Map<String, dynamic>>.from(cached);
          }
          return [];
      }
  }

  Future<Map<String, dynamic>?> getLastFeed() async {
      try {
          final data = await _client.from('feeds').select().order('created_at', ascending: false).limit(1).maybeSingle();
          return data;
      } catch (e) {
         // Fallback to cache
         final all = await getFeeds(); 
         if (all.isNotEmpty) {
             // Sort desc just in case
             all.sort((a,b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
             return all.first;
         }
         return null;
      }
  }

  Future<List<Map<String, dynamic>>> getMilestones() async {
      const String cacheKey = 'milestones_cache';
      try {
          final data = await _client.from('milestones').select().order('date');
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          final cached = await _getCachedData(cacheKey);
          if (cached != null) {
              return List<Map<String, dynamic>>.from(cached);
          }
          return [];
      }
  }

  Future<List<Map<String, dynamic>>> getSleepLogs() async {
      const String cacheKey = 'sleep_logs_cache';
      try {
          final data = await _client.from('sleep_logs').select().order('created_at', ascending: false);
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          final cached = await _getCachedData(cacheKey);
          if (cached != null) {
              return List<Map<String, dynamic>>.from(cached);
          }
          return [];
      }
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
      const String cacheKey = 'notes_cache';
      try {
          final data = await _client.from('mom_notes').select().order('created_at', ascending: false);
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          final cached = await _getCachedData(cacheKey);
          if (cached != null) {
              return List<Map<String, dynamic>>.from(cached);
          }
          return [];
      }
  }

  Future<List<Map<String, dynamic>>> getDiaperLogs() async {
      const String cacheKey = 'diapers_cache';
      try {
          // Get logs from last 24 hours ideally, or just last 50
           final data = await _client.from('diaper_logs').select().order('created_at', ascending: false).limit(50);
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          final cached = await _getCachedData(cacheKey);
          if (cached != null) return List<Map<String, dynamic>>.from(cached);
          return [];
      }
  }

  Future<List<Map<String, dynamic>>> getRoutines() async {
      const String cacheKey = 'routines_cache';
      try {
          final data = await _client.from('routines').select().order('time');
          await _cacheData(cacheKey, data);
          return List<Map<String, dynamic>>.from(data);
      } catch (e) {
          final cached = await _getCachedData(cacheKey);
          if (cached != null) return List<Map<String, dynamic>>.from(cached);
          return [];
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

  Future<String?> uploadImage(String userId, String filePath, Uint8List fileBytes) async {
    try {
        final fileName = '${DateTime.now().toIso8601String()}_${filePath.split('/').last}';
        final path = '$userId/$fileName';
        await _client.storage.from('images').uploadBinary(path, fileBytes);
        return _client.storage.from('images').getPublicUrl(path);
    } catch (e) {
        if (kDebugMode) print('Error uploading image: $e');
        return null; 
    }
  }

  Future<bool> isPremiumUser() async {
      try {
          final profile = await getProfile();
          if (profile != null && profile['is_premium'] == true) {
              return true;
          }
          return false;
      } catch (e) {
          return false; 
      }
  }

  Future<bool> registerDevice(String deviceId) async {
      try {
          final profile = await getProfile();
          if (profile == null) return true; 

          final bool isPremium = profile['is_premium'] ?? false;
          if (isPremium) return true; 

          List<String> devices = List<String>.from(profile['device_ids'] ?? []);
          
          if (devices.contains(deviceId)) {
              return true; 
          }

          if (devices.length < 2) {
              devices.add(deviceId);
              await updateProfile({'device_ids': devices});
              return true;
          }

          return false; 
      } catch (e) {
          print('Device limit check error: $e');
          return true; 
      }
  }

  Future<void> saveRoutine(Map<String, dynamic> data) async {
      await _client.from('routines').insert(data);
      _invalidateCache('routines_cache');
  }

  Future<void> saveVaccine(Map<String, dynamic> data) async {
      await _client.from('vaccines').insert(data);
      _invalidateCache('vaccines_cache');
  }
  
  Future<void> updateVaccine(String id, Map<String, dynamic> updates) async {
      await _client.from('vaccines').update(updates).eq('id', id);
      _invalidateCache('vaccines_cache');
  }

  Future<void> savePrescription(Map<String, dynamic> data) async {
      await _client.from('prescriptions').insert(data);
      _invalidateCache('prescriptions_cache');
  }

  Future<void> deleteRoutine(String id) async {
      await _client.from('routines').delete().eq('id', id);
      _invalidateCache('routines_cache');
  }

  Future<void> deleteFeed(String id) async {
      await _client.from('feeds').delete().eq('id', id);
      _invalidateCache('feeds_cache');
  }

  Future<void> deleteSleepLog(String id) async {
      await _client.from('sleep_logs').delete().eq('id', id);
      _invalidateCache('sleep_logs_cache');
  }

  Future<void> deleteMilestone(String id) async {
      await _client.from('milestones').delete().eq('id', id);
      _invalidateCache('milestones_cache');
  }

  Future<void> deleteVaccine(String id) async {
      await _client.from('vaccines').delete().eq('id', id);
      _invalidateCache('vaccines_cache');
  }

  Future<void> deletePrescription(String id) async {
      await _client.from('prescriptions').delete().eq('id', id);
      _invalidateCache('prescriptions_cache');
  }
  
  Future<void> saveNote(Map<String, dynamic> data) async {
      await _client.from('mom_notes').insert(data);
      _invalidateCache('notes_cache');
  }

  Future<void> saveDiaperLog(Map<String, dynamic> data) async {
      await _client.from('diaper_logs').insert(data);
      _invalidateCache('diapers_cache');
  }

  Future<void> deleteDiaperLog(String id) async {
      await _client.from('diaper_logs').delete().eq('id', id);
      _invalidateCache('diapers_cache');
  }

  Future<void> updateDiaperLog(String id, Map<String, dynamic> updates) async {
      await _client.from('diaper_logs').update(updates).eq('id', id);
      _invalidateCache('diapers_cache');
  }

  Future<void> updateNote(String id, Map<String, dynamic> updates) async {
      await _client.from('mom_notes').update(updates).eq('id', id);
      _invalidateCache('notes_cache');
  }

  Future<void> updateFeed(String id, Map<String, dynamic> updates) async {
      await _client.from('feeds').update(updates).eq('id', id);
      _invalidateCache('feeds_cache');
  }

  Future<void> updateSleepLog(String id, Map<String, dynamic> updates) async {
      await _client.from('sleep_logs').update(updates).eq('id', id);
      _invalidateCache('sleep_logs_cache');
  }

  Future<void> updateRoutine(String id, Map<String, dynamic> updates) async {
      await _client.from('routines').update(updates).eq('id', id);
      _invalidateCache('routines_cache');
  }

  Future<void> updatePrescription(String id, Map<String, dynamic> updates) async {
      await _client.from('prescriptions').update(updates).eq('id', id);
      _invalidateCache('prescriptions_cache');
  }

  Future<void> updateMilestone(String id, Map<String, dynamic> updates) async {
      await _client.from('milestones').update(updates).eq('id', id);
      _invalidateCache('milestones_cache');
  }

  Future<void> deleteNote(String id) async {
      await _client.from('mom_notes').delete().eq('id', id);
      _invalidateCache('notes_cache');
  }
}
