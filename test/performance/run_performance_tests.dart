import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Test Suite', () {
    test('Run all performance tests', () async {
      print('Starting Performance Test Suite...');
      print('Current Time: ${DateTime.now().toUtc().toIso8601String()}');
      print('User: AyariAladine');
      print('=' * 50);

      final tests = [
        'test/performance/login_performance_test.dart',
        'test/performance/memory_performance_test.dart',
        'test/performance/benchmark_test.dart',
      ];

      for (final testFile in tests) {
        print('Running $testFile...');
        final result = await Process.run('flutter', ['test', testFile]);

        if (result.exitCode == 0) {
          print('✅ $testFile PASSED');
        } else {
          print('❌ $testFile FAILED');
          print(result.stdout);
          print(result.stderr);
        }
        print('-' * 30);
      }

      print('Performance Test Suite Complete!');
    });
  });
}