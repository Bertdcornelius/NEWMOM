import 'package:flutter_test/flutter_test.dart';
import 'package:new_mom_tracker/core/result.dart';

void main() {
  group('Result Core Pipeline Tests', () {
    test('Success wraps value correctly and exposes it', () {
      final Result<String> result = Success('Data synced');
      
      expect(result is Success, true);
      expect((result as Success).value, 'Data synced');
    });

    test('Failure wraps error message and exception', () {
      final exception = Exception('Connection refused');
      final Result<int> result = Failure('Offline Database Error', exception);
      
      expect(result is Failure, true);
      expect((result as Failure).message, 'Offline Database Error');
      expect((result as Failure).exception, exception);
    });

    test('Pattern matching executes correct branch for Success', () {
      final Result<int> result = Success(200);
      
      String output = '';
      
      if (result is Success<int>) {
         output = 'Code: ${result.value}';
      } else if (result is Failure<int>) {
         output = 'Error: ${result.message}';
      }

      expect(output, 'Code: 200');
    });

    test('Pattern matching executes correct branch for Failure', () {
      final Result<List<String>> result = Failure('Cache Miss');
      
      String output = '';
      
      if (result is Success<List<String>>) {
         output = 'Found';
      } else if (result is Failure<List<String>>) {
         output = 'Missed';
      }

      expect(output, 'Missed');
    });
  });
}
