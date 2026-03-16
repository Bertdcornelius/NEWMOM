import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/baby_data_repository.dart';
import '../models/feed_model.dart';

class FeedingViewModel extends ChangeNotifier {
  final BabyDataRepository _babyDataRepo;

  // Breast Feeding State
  String _selectedSide = 'L';
  int _durationMinutes = 15;

  // Timer State
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;

  // Bottle Feeding State
  int _amountMl = 120;

  // Solid Feeding State
  String _solidType = '';

  // General State
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  // Reminder State
  bool _remindMe = false;
  int _reminderInterval = 3;
  String _reminderNote = '';
  String? _smartSuggestionText;

  // Getters
  String get selectedSide => _selectedSide;
  int get durationMinutes => _durationMinutes;
  bool get isTimerRunning => _isTimerRunning;
  int get amountMl => _amountMl;
  String get solidType => _solidType;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  bool get remindMe => _remindMe;
  int get reminderInterval => _reminderInterval;
  String get reminderNote => _reminderNote;
  String? get smartSuggestionText => _smartSuggestionText;

  FeedingViewModel(this._babyDataRepo) {
    _calculateSmartReminder();
  }

  void setSelectedSide(String side) {
    _selectedSide = side;
    notifyListeners();
  }

  void setDurationMinutes(int duration) {
    if (!_isTimerRunning) {
      _durationMinutes = duration;
      notifyListeners();
    }
  }

  void setAmountMl(int amount) {
    _amountMl = amount;
    notifyListeners();
  }

  void setSolidType(String type) {
    _solidType = type;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setRemindMe(bool val) {
    _remindMe = val;
    notifyListeners();
  }

  void setReminderInterval(int hours) {
    _reminderInterval = hours;
    notifyListeners();
  }

  void setReminderNote(String note) {
    _reminderNote = note;
    notifyListeners();
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
      _stopwatch.reset();
      _stopwatch.start();
      _isTimerRunning = true;
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifyListeners();
      });
    }
    notifyListeners();
  }

  String formatStopwatch() {
    final elapsed = _stopwatch.elapsed;
    final String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _calculateSmartReminder() async {
    try {
      final feeds = await _babyDataRepo.getFeeds();
      if (feeds.length < 2) return;

      feeds.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

      int totalMinutes = 0;
      int gapCount = 0;

      for (int i = 0; i < feeds.length - 1 && gapCount < 4; i++) {
        final current = DateTime.parse(feeds[i]['created_at']).toLocal();
        final previous = DateTime.parse(feeds[i + 1]['created_at']).toLocal();
        final diff = current.difference(previous).inMinutes;
        if (diff > 0 && diff < 480) {
          totalMinutes += diff;
          gapCount++;
        }
      }

      if (gapCount > 0) {
        final avgMinutes = totalMinutes ~/ gapCount;
        final avgHours = (avgMinutes / 60).round();
        if (avgHours > 0 && avgHours <= 6) {
          _reminderInterval = avgHours;
          _smartSuggestionText = '✨ Smart Suggestion: $avgHours hours based on recent feeds';
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<bool> saveFeed(String type, String userId) async {
    _isLoading = true;
    notifyListeners();

    DateTime? nextDue;
    if (_remindMe) {
      nextDue = _selectedDate.add(Duration(hours: _reminderInterval));
    }

    final feed = Feed(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      side: type == 'breast' ? _selectedSide : null,
      amountMl: type == 'bottle' ? _amountMl : null,
      durationMin: type == 'breast' ? _durationMinutes : null,
      nextDue: nextDue,
      createdAt: _selectedDate,
      notes: type == 'solid' ? _solidType : null,
    );

    await _babyDataRepo.saveFeed(feed.toJson());

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
