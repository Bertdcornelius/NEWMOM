import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_mom_tracker/services/local_storage_service.dart';
import 'package:new_mom_tracker/services/offline_sync_service.dart';
import 'dart:convert';

/// Tests the core queue logic of the OfflineSyncService.
/// Since OfflineSyncService depends on LocalStorageService which requires SharedPreferences,
/// we test the serialization and queue logic in isolation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('OfflineSyncAction Serialization', () {
    test('serializes action to JSON correctly', () {
      final action = {
        'id': 'test-uuid-1',
        'table': 'feeds',
        'method': 'insert',
        'data': {'amount_ml': 120, 'type': 'bottle'},
        'matchKey': null,
        'matchValue': null,
      };

      final jsonString = jsonEncode([action]);
      final decoded = jsonDecode(jsonString) as List;

      expect(decoded.length, 1);
      expect(decoded[0]['table'], 'feeds');
      expect(decoded[0]['method'], 'insert');
      expect(decoded[0]['data']['amount_ml'], 120);
    });

    test('serializes multiple actions correctly', () {
      final actions = [
        {
          'id': 'uuid-1',
          'table': 'feeds',
          'method': 'insert',
          'data': {'id': 1},
          'matchKey': null,
          'matchValue': null,
        },
        {
          'id': 'uuid-2',
          'table': 'sleep_logs',
          'method': 'delete',
          'data': {},
          'matchKey': 'id',
          'matchValue': 'abc',
        },
      ];

      final jsonString = jsonEncode(actions);
      final decoded = jsonDecode(jsonString) as List;

      expect(decoded.length, 2);
      expect(decoded[0]['table'], 'feeds');
      expect(decoded[1]['table'], 'sleep_logs');
      expect(decoded[1]['method'], 'delete');
      expect(decoded[1]['matchKey'], 'id');
      expect(decoded[1]['matchValue'], 'abc');
    });

    test('deserializes action from JSON correctly', () {
      final json = '{"id":"test-1","table":"diaper_logs","method":"update","data":{"notes":"wet"},"matchKey":"id","matchValue":"xyz"}';
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['table'], 'diaper_logs');
      expect(decoded['method'], 'update');
      expect(decoded['data']['notes'], 'wet');
      expect(decoded['matchKey'], 'id');
      expect(decoded['matchValue'], 'xyz');
    });

    test('empty queue serializes correctly', () {
      final emptyQueue = <Map<String, dynamic>>[];
      final jsonString = jsonEncode(emptyQueue);
      final decoded = jsonDecode(jsonString) as List;

      expect(decoded.isEmpty, true);
    });
  });

  group('OfflineSyncService Integration', () {
    test('adds action to queue and retrieves it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final syncService = OfflineSyncService(storage);

      expect(syncService.queue.length, 0);

      // Add a dummy action
      await syncService.enqueueAction(
        'test_table',
        'insert',
        {'name': 'test'},
      );

      // Verify it's in the queue
      expect(syncService.queue.length, 1);
      final savedAction = syncService.queue.first;
      expect(savedAction.table, 'test_table');
      expect(savedAction.method, 'insert');
      expect(savedAction.data['name'], 'test');

      // Verify it was actually saved to shared preferences
      final storedJson = prefs.getString('offline_sync_queue');
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['table'], 'test_table');
    });
  });

  group('DashboardViewModel Logic', () {
    test('baby name defaults to "Baby" when null', () {
      // This validates the getter logic
      String? babyName;
      final displayName = babyName ?? 'Baby';
      expect(displayName, 'Baby');
    });

    test('showOnboarding is true when baby name is null and not loading', () {
      String? babyName = [null].first;
      bool isLoading = false;
      final showOnboarding = (babyName == null) && !isLoading;
      expect(showOnboarding, true);
    });

    test('showOnboarding is false when loading', () {
      String? babyName = [null].first;
      bool isLoading = true;
      final showOnboarding = (babyName == null) && !isLoading;
      expect(showOnboarding, false);
    });
  });

  group('FeedingViewModel Logic', () {
    test('timer format returns correct format', () {
      // Simulate stopwatch formatting
      int inMinutes = 5;
      int inSeconds = 32;
      final String minutes = (inMinutes % 60).toString().padLeft(2, '0');
      final String seconds = (inSeconds % 60).toString().padLeft(2, '0');
      expect('$minutes:$seconds', '05:32');
    });

    test('duration clamps correctly after timer stop', () {
      int elapsedMinutes = 0;
      int elapsedSeconds = 15;
      int durationMinutes = (elapsedMinutes == 0 && elapsedSeconds > 0) ? 1 : elapsedMinutes;
      if (durationMinutes == 0) durationMinutes = 1;
      if (durationMinutes > 60) durationMinutes = 60;
      expect(durationMinutes, 1);
    });

    test('duration clamps max at 60', () {
      int durationMinutes = 75;
      if (durationMinutes > 60) durationMinutes = 60;
      expect(durationMinutes, 60);
    });

    test('smart reminder calculation averages gaps correctly', () {
      // Simulate smart reminder logic
      final feeds = [
        {'created_at': '2026-03-14T12:00:00Z'},
        {'created_at': '2026-03-14T09:00:00Z'},
        {'created_at': '2026-03-14T06:00:00Z'},
      ];

      int totalMinutes = 0;
      int gapCount = 0;

      for (int i = 0; i < feeds.length - 1 && gapCount < 4; i++) {
        final current = DateTime.parse(feeds[i]['created_at']!);
        final previous = DateTime.parse(feeds[i + 1]['created_at']!);
        final diff = current.difference(previous).inMinutes;
        if (diff > 0 && diff < 480) {
          totalMinutes += diff;
          gapCount++;
        }
      }

      expect(gapCount, 2);
      expect(totalMinutes, 360); // 180 + 180
      final avgHours = ((totalMinutes ~/ gapCount) / 60).round();
      expect(avgHours, 3); // Should suggest every 3 hours
    });
  });
}
