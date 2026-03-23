import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../repositories/auth_repository.dart';
import '../repositories/feeding_repository.dart';
import '../services/notification_service.dart';
import '../models/feed_model.dart';
import '../services/logger_service.dart';

class FeedingViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final FeedingRepository _feedingRepo;
  final NotificationService _notificationService;

  FeedingViewModel(this._authRepo, this._feedingRepo, this._notificationService) {
    loadActiveReminders();
  }

  // --- Breast Feeding State ---
  String _selectedSide = 'L';
  String get selectedSide => _selectedSide;
  
  void setSide(String side) {
    _selectedSide = side;
    notifyListeners();
  }

  // Timer State
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  int _durationMinutes = 15;
  int get durationMinutes => _durationMinutes;

  String get formattedStopwatch {
      final elapsed = _stopwatch.elapsed;
      final String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      return "$minutes:$seconds";
  }

  void toggleTimer() {
      if (_isTimerRunning) {
          _stopwatch.stop();
          _isTimerRunning = false;
          _uiTimer?.cancel();
          _durationMinutes = (_stopwatch.elapsed.inMinutes == 0 && _stopwatch.elapsed.inSeconds > 0) ? 1 : _stopwatch.elapsed.inMinutes;
          if (_durationMinutes == 0) _durationMinutes = 1; 
          if (_durationMinutes > 60) _durationMinutes = 60;
      } else {
          _stopwatch.start();
          _isTimerRunning = true;
          _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
      }
      notifyListeners();
  }

  void setDuration(int min) {
    if (!_isTimerRunning) {
      _durationMinutes = min;
      notifyListeners();
    }
  }

  // --- Bottle Feeding ---
  int _amountMl = 120;
  int get amountMl => _amountMl;
  
  void setAmount(int ml) {
    _amountMl = ml;
    notifyListeners();
  }

  // --- Date / Time ---
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  
  void setDate(DateTime d) {
    _selectedDate = d;
    notifyListeners();
  }

  // --- Reminders ---
  bool _remindMe = false;
  bool get remindMe => _remindMe;
  
  void setRemindMe(bool val) {
    _remindMe = val;
    notifyListeners();
  }

  int _reminderInterval = 3;
  int get reminderInterval => _reminderInterval;
  
  void setReminderInterval(int hours) {
    _reminderInterval = hours;
    notifyListeners();
  }

  TimeOfDay? _customReminderTime;
  TimeOfDay? get customReminderTime => _customReminderTime;
  
  void setCustomReminderTime(TimeOfDay? time) {
    _customReminderTime = time;
    notifyListeners();
  }

  int _activeReminderCount = 0;
  int get activeReminderCount => _activeReminderCount;

  // --- Loading State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadActiveReminders() async {
    try {
      final reminders = await _notificationService.getActiveReminders();
      _activeReminderCount = reminders.length;
      notifyListeners();
    } catch (e) {
      LoggerService.warn("Failed to load active reminders: $e");
    }
  }

  // --- Save Functionality ---
  /// Returns `true` if save was successful, `false` otherwise.
  Future<bool> saveFeed(String type, String solidFoodNotes, String reminderNote) async {
    _isLoading = true;
    notifyListeners();

    final user = _authRepo.currentUser;
    if (user == null) {
      LoggerService.error("Failed to save feed", Exception('Not logged in'), null);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    DateTime? nextDue;
    if (_remindMe) {
        if (_customReminderTime != null) {
            final now = DateTime.now();
            nextDue = DateTime(now.year, now.month, now.day, _customReminderTime!.hour, _customReminderTime!.minute);
            if (nextDue.isBefore(now)) nextDue = nextDue.add(const Duration(days: 1));
        } else {
             nextDue = _selectedDate.add(Duration(hours: _reminderInterval));
        }
    }

    final feed = Feed(
      id: const Uuid().v4(),
      userId: user.id,
      type: type,
      side: type == 'breast' ? _selectedSide : null,
      amountMl: type == 'bottle' ? _amountMl : null,
      durationMin: type == 'breast' ? _durationMinutes : null,
      nextDue: nextDue,
      createdAt: _selectedDate,
      notes: type == 'solid' ? solidFoodNotes.trim() : null,
    );

    final result = await _feedingRepo.saveFeed(feed.toJson());

    if (!result.isSuccess) {
      LoggerService.error("Failed to save feed", Exception(result.message), null);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Schedule Reminder if enabled
    if (_remindMe && nextDue != null) {
        if (nextDue.isAfter(DateTime.now())) {
            final reminderId = nextDue.millisecondsSinceEpoch % 100000;
            final body = reminderNote.trim().isNotEmpty ? reminderNote.trim() : 'Time to feed your baby';
            await _notificationService.scheduleReminder(reminderId, nextDue, '🍼 Feeding Time!', body);
            await loadActiveReminders();
        }
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }
}
