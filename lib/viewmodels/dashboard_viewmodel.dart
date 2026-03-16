import 'package:flutter/foundation.dart';
import '../services/baby_data_repository.dart';
import '../services/local_storage_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final BabyDataRepository _babyDataRepo;
  final LocalStorageService _localStorage;

  String? _babyName;
  String? _dob;
  Map<String, dynamic>? _lastFeed;
  Map<String, dynamic>? _lastSleep;
  List<Map<String, dynamic>> _diaperLogs = [];
  bool _isLoading = true;

  // Getters
  String get babyName => _babyName ?? 'Baby';
  String? get dob => _dob;
  Map<String, dynamic>? get lastFeed => _lastFeed;
  Map<String, dynamic>? get lastSleep => _lastSleep;
  List<Map<String, dynamic>> get diaperLogs => _diaperLogs;
  bool get isLoading => _isLoading;
  bool get showOnboarding => (_babyName == null || _babyName == 'Baby') && !isLoading;

  DashboardViewModel(this._babyDataRepo, this._localStorage) {
    loadData();
    _babyDataRepo.addListener(_onRepoChanged);
  }

  void _onRepoChanged() {
    loadData(silent: true);
  }

  @override
  void dispose() {
    _babyDataRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _babyName = _localStorage.getString('baby_name');
      _dob = _localStorage.getString('dob');

      final results = await Future.wait([
        _babyDataRepo.getLastFeed(),
        _babyDataRepo.getSleepLogs(),
        _babyDataRepo.getDiaperLogs(),
      ]);

      _lastFeed = results[0] as Map<String, dynamic>?;
      final sleeps = results[1] as List<Map<String, dynamic>>;
      if (sleeps.isNotEmpty) _lastSleep = sleeps.first;
      _diaperLogs = results[2] as List<Map<String, dynamic>>;
      
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading dashboard data: $e');
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBabyName(String name) async {
     _babyName = name;
     await _localStorage.saveString('baby_name', name);
     notifyListeners();
  }
}
