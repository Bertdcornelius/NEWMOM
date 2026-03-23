import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/feeding_repository.dart';
import '../repositories/sleep_repository.dart';
import '../repositories/care_repository.dart';

/// Legacy Router mapping BabyDataRepository to the New Architecture Repositories
class BabyDataRepository extends ChangeNotifier {
  final AuthRepository _auth;
  final FeedingRepository _feeding;
  final SleepRepository _sleep;
  final CareRepository _care;

  BabyDataRepository(this._auth, this._feeding, this._sleep, this._care);

  User? get currentUser => _auth.currentUser;

  // --- Feeds ---
  Future<void> saveFeed(Map<String, dynamic> data) async => await _feeding.saveFeed(data);
  Future<List<dynamic>> getFeeds() async => (await _feeding.getFeeds()).data ?? [];
  Future<Map<String, dynamic>?> getLastFeed() async => (await _feeding.getLastFeed()).data;

  // --- Sleep ---
  Future<void> saveSleepLog(Map<String, dynamic> data) async => await _sleep.saveSleepLog(data);
  Future<List<dynamic>> getSleepLogs() async => (await _sleep.getSleepLogs()).data ?? [];

  // --- Diapers ---
  Future<void> saveDiaperLog(Map<String, dynamic> data) async => await _care.saveDiaperLog(data);
  Future<List<dynamic>> getDiaperLogs() async => (await _care.getDiaperLogs()).data ?? [];
  
  // --- Tummy Time ---
  Future<void> saveTummyTime(Map<String, dynamic> data) async => await _care.saveTummyTimeSession(data);
  Future<List<dynamic>> getTummyTime() async => (await _care.getTummyTimeSessions()).data ?? [];

  // --- Teething ---
  Future<void> saveTeethingData(Map<String, dynamic> data) async => await _care.saveTeethingData(data);
  Future<List<dynamic>> getTeethingData() async => (await _care.getTeethingData()).data ?? [];

  // --- Milestones ---
  Future<void> saveMilestone(Map<String, dynamic> data) async => await _care.saveMilestone(data);
  Future<List<dynamic>> getMilestones() async => (await _care.getMilestones()).data ?? [];

  // --- Profile / Auth ---
  Future<Map<String, dynamic>?> getProfile() async => (await _auth.getProfile()).data;
  
  // --- Additional pass-throughs required by legacy UI screens ---
  Future<void> saveRoutine(Map<String, dynamic> data) async => await _care.saveRoutine(data);
  Future<List<dynamic>> getRoutines() async => (await _care.getRoutines()).data ?? [];
  
  Future<void> saveVaccine(Map<String, dynamic> data) async => await _care.saveVaccine(data);
  Future<List<dynamic>> getVaccines() async => (await _care.getVaccines()).data ?? [];
  
  Future<void> saveNote(Map<String, dynamic> data) async => await _care.saveNote(data);
  Future<List<dynamic>> getNotes() async => (await _care.getNotes()).data ?? [];

  Future<void> saveGrowthEntry(Map<String, dynamic> data) async => await _care.saveGrowthEntry(data);
  Future<List<dynamic>> getGrowthEntries() async => (await _care.getGrowthEntries()).data ?? [];

  Future<void> savePrescription(Map<String, dynamic> data) async => await _care.savePrescription(data);
  Future<List<dynamic>> getPrescriptions() async => (await _care.getPrescriptions()).data ?? [];
  
  Future<void> savePumpingSession(Map<String, dynamic> data) async => await _care.savePumpingSession(data);
  Future<List<dynamic>> getPumpingSessions() async => (await _care.getPumpingSessions()).data ?? [];
}
