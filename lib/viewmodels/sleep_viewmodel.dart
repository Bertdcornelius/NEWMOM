import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../repositories/sleep_repository.dart';
import '../repositories/auth_repository.dart';
import '../models/sleep_model.dart';
import '../services/logger_service.dart';

class SleepViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final SleepRepository _sleepRepo;

  SleepViewModel(this._authRepo, this._sleepRepo);

  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  Timer? _timer;
  
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  bool _isSleeping = false;
  bool get isSleeping => _isSleeping;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<bool> toggleSleep() async {
    if (_isSleeping) {
      // Stop Sleep
      _timer?.cancel();
      final success = await _saveSleepLog();
      
      _isSleeping = false;
      _startTime = null;
      _duration = Duration.zero;
      notifyListeners();
      
      return success;
    } else {
      // Start Sleep
      _isSleeping = true;
      _startTime = DateTime.now();
      notifyListeners();
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_startTime != null) {
          _duration = DateTime.now().difference(_startTime!);
          notifyListeners();
        }
      });
      return true;
    }
  }

  Future<bool> _saveSleepLog() async {
    _isLoading = true;
    notifyListeners();

    final user = _authRepo.currentUser;
    if (user == null) {
      LoggerService.error("Failed to save sleep log", Exception('Not logged in'), null);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final endTime = DateTime.now();
    final log = SleepLog(
      id: const Uuid().v4(),
      userId: user.id,
      startTime: _startTime!.toUtc(),
      endTime: endTime.toUtc(),
      createdAt: DateTime.now().toUtc(),
    );

    final result = await _sleepRepo.saveSleepLog(log.toJson());
    
    _isLoading = false;
    notifyListeners();

    if (result.isSuccess) {
      return true;
    } else {
      LoggerService.error("Failed to save sleep log: ${result.message}", result.message, null);
      return false;
    }
  }

  Future<bool> saveManualLog(DateTime startLocal, DateTime endLocal) async {
    _isLoading = true;
    notifyListeners();

    final user = _authRepo.currentUser;
    if (user == null) {
      LoggerService.error("Failed to save manual sleep log", Exception('Not logged in'), null);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final log = SleepLog(
      id: const Uuid().v4(),
      userId: user.id,
      startTime: startLocal.toUtc(),
      endTime: endLocal.toUtc(),
      createdAt: DateTime.now().toUtc(),
    );

    final result = await _sleepRepo.saveSleepLog(log.toJson());
    
    _isLoading = false;
    notifyListeners();

    if (result.isSuccess) {
      return true;
    } else {
      LoggerService.error("Failed to save manual sleep log: ${result.message}", result.message, null);
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
