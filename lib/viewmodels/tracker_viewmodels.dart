import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/care_repository.dart';

class DiaperViewModel extends ChangeNotifier {
  final CareRepository _repo;
  StreamSubscription? _sub;
  
  List<Map<String, dynamic>> logs = [];
  bool isLoading = true;
  String? errorMessage;
  
  int todayPee = 0;
  int todayPoop = 0;
  int todayTotal = 0;

  DiaperViewModel(this._repo) {
    _initStream();
  }

  void _initStream() {
    _sub = _repo.streamDiaperLogs(limit: 50).listen(
      (data) {
        logs = data;
        _calculateStats();
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      }
    );
  }

  void _calculateStats() {
    int pee = 0, poop = 0, total = 0;
    final now = DateTime.now();
    for (var l in logs) {
      try {
        final date = DateTime.parse(l['created_at']).toLocal();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          total++;
          if (l['type'] == 'pee' || l['type'] == 'both') pee++;
          if (l['type'] == 'poop' || l['type'] == 'both') poop++;
        }
      } catch (_) {}
    }
    todayPee = pee;
    todayPoop = poop;
    todayTotal = total;
  }

  // Clear errors to let UI show snacks, then reset 
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveDiaperLog(Map<String, dynamic> data) async {
    final res = await _repo.saveDiaperLog(data);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class GrowthViewModel extends ChangeNotifier {
  final CareRepository _repo;
  StreamSubscription? _sub;

  List<Map<String, dynamic>> entries = [];
  bool isLoading = true;
  String? errorMessage;

  GrowthViewModel(this._repo) {
    _initStream();
  }

  void _initStream() {
    _sub = _repo.streamGrowthEntries().listen(
      (data) {
        // Reverse to show newest first at the top of the UI
        entries = data.reversed.toList();
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      }
    );
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveEntry(Map<String, dynamic> data) async {
    final res = await _repo.saveGrowthEntry(data);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> deleteEntry(String id) async {
    final res = await _repo.deleteGrowthEntry(id);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// GENERIC TRACKER VIEWMODEL
// ============================================================================
class GenericTrackerViewModel extends ChangeNotifier {
  final CareRepository repo;
  final Stream<List<Map<String, dynamic>>> Function(CareRepository) streamDelegate;
  final Future<dynamic> Function(CareRepository, Map<String, dynamic>) saveDelegate;
  final Future<dynamic> Function(CareRepository, String)? deleteDelegate;
  final Future<dynamic> Function(CareRepository, String, Map<String, dynamic>)? updateDelegate;
  final bool reverseSort;

  StreamSubscription? _sub;
  List<Map<String, dynamic>> entries = [];
  bool isLoading = true;
  String? errorMessage;

  GenericTrackerViewModel({
    required this.repo,
    required this.streamDelegate,
    required this.saveDelegate,
    this.deleteDelegate,
    this.updateDelegate,
    this.reverseSort = false,
  }) {
    _initStream();
  }

  void _initStream() {
    _sub = streamDelegate(repo).listen(
      (data) {
        entries = reverseSort ? data.reversed.toList() : data;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      }
    );
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveEntry(Map<String, dynamic> data) async {
    final res = await saveDelegate(repo, data);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> deleteEntry(String id) async {
    if (deleteDelegate == null) return false;
    final res = await deleteDelegate!(repo, id);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> updateEntry(String id, Map<String, dynamic> updates) async {
    if (updateDelegate == null) return false;
    final res = await updateDelegate!(repo, id, updates);
    if (!res.isSuccess) {
      errorMessage = res.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// FEATURE-SPECIFIC VIEWMODELS
// ============================================================================

class PumpingViewModel extends GenericTrackerViewModel {
  PumpingViewModel(CareRepository repo) : super(
    repo: repo, reverseSort: true,
    streamDelegate: (r) => r.streamPumpingSessions(),
    saveDelegate: (r, data) => r.savePumpingSession(data),
    deleteDelegate: (r, id) => r.deletePumpingSession(id),
  );
}

class TummyTimeViewModel extends GenericTrackerViewModel {
  TummyTimeViewModel(CareRepository repo) : super(
    repo: repo, reverseSort: true,
    streamDelegate: (r) => r.streamTummyTimeSessions(),
    saveDelegate: (r, data) => r.saveTummyTimeSession(data),
    deleteDelegate: (r, id) => r.deleteTummyTimeSession(id),
  );
}

class TeethingViewModel extends GenericTrackerViewModel {
  TeethingViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamTeethingData(),
    saveDelegate: (r, data) => r.saveTeethingData(data),
    deleteDelegate: (r, id) => r.deleteTeethingData(id),
  );
}

class PhotoGalleryViewModel extends GenericTrackerViewModel {
  PhotoGalleryViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamGalleryPhotos(),
    saveDelegate: (r, data) => r.saveGalleryPhoto(data),
    deleteDelegate: (r, id) => r.deleteGalleryPhoto(id),
  );
}

class MilestoneViewModel extends GenericTrackerViewModel {
  MilestoneViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamMilestones(),
    saveDelegate: (r, data) => r.saveMilestone(data),
    deleteDelegate: (r, id) => r.deleteMilestone(id),
    updateDelegate: (r, id, data) => r.updateMilestone(id, data),
  );
}

class MomCareViewModel extends GenericTrackerViewModel {
  MomCareViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamMomCareChecklist(),
    saveDelegate: (r, data) => r.saveMomCareChecklist(data),
    deleteDelegate: (r, id) => r.deleteMomCareChecklist(id),
    updateDelegate: (r, id, data) => r.updateMomCareChecklist(id, data),
  );
}

class MenstrualViewModel extends GenericTrackerViewModel {
  MenstrualViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamMenstrualCycles(),
    saveDelegate: (r, data) => r.saveMenstrualCycle(data),
    deleteDelegate: (r, id) => r.deleteMenstrualCycle(id),
    updateDelegate: (r, id, data) => r.updateMenstrualCycle(id, data),
  );
}

class MilkStashViewModel extends GenericTrackerViewModel {
  MilkStashViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamMilkStash(),
    saveDelegate: (r, data) => r.saveMilkStash(data),
    deleteDelegate: (r, id) => r.deleteMilkStash(id),
    updateDelegate: (r, id, data) => r.updateMilkStash(id, data),
  );
}

class MoodViewModel extends GenericTrackerViewModel {
  MoodViewModel(CareRepository repo) : super(
    repo: repo, reverseSort: true,
    streamDelegate: (r) => r.streamMoodLogs(),
    saveDelegate: (r, data) => r.saveMoodLog(data),
    deleteDelegate: (r, id) => r.deleteMoodLog(id),
  );
}

class FoodIntroViewModel extends GenericTrackerViewModel {
  FoodIntroViewModel(CareRepository repo) : super(
    repo: repo, reverseSort: true,
    streamDelegate: (r) => r.streamFoodIntroductions(),
    saveDelegate: (r, data) => r.saveFoodIntroduction(data),
    deleteDelegate: (r, id) => r.deleteFoodIntroduction(id),
  );
}

class NotesViewModel extends GenericTrackerViewModel {
  NotesViewModel(CareRepository repo) : super(
    repo: repo, reverseSort: true,
    streamDelegate: (r) => r.streamNotes(),
    saveDelegate: (r, data) => r.saveNote(data),
    deleteDelegate: (r, id) => r.deleteNote(id),
    updateDelegate: (r, id, data) => r.updateNote(id, data),
  );
}

class RoutineViewModel extends GenericTrackerViewModel {
  RoutineViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamRoutines(),
    saveDelegate: (r, data) => r.saveRoutine(data),
    deleteDelegate: (r, id) => r.deleteRoutine(id),
    updateDelegate: (r, id, data) => r.updateRoutine(id, data),
  );
}

class VaccineViewModel extends GenericTrackerViewModel {
  VaccineViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamVaccines(),
    saveDelegate: (r, data) => r.saveVaccine(data),
    deleteDelegate: (r, id) => r.deleteVaccine(id),
    updateDelegate: (r, id, data) => r.updateVaccine(id, data),
  );
}

class PrescriptionViewModel extends GenericTrackerViewModel {
  PrescriptionViewModel(CareRepository repo) : super(
    repo: repo,
    streamDelegate: (r) => r.streamPrescriptions(),
    saveDelegate: (r, data) => r.savePrescription(data),
    deleteDelegate: (r, id) => r.deletePrescription(id),
    updateDelegate: (r, id, data) => r.updatePrescription(id, data),
  );
}
