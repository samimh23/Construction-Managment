import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void startTimer(String operation) {
    if (kDebugMode) {
      _timers[operation] = Stopwatch()..start();
    }
  }

  static void endTimer(String operation) {
    if (kDebugMode && _timers.containsKey(operation)) {
      final elapsed = _timers[operation]!..stop();
      debugPrint('⏱️ $operation: ${elapsed.elapsedMilliseconds}ms');
      _timers.remove(operation);
    }
  }

  static Widget wrapWithMonitoring(String name, Widget child) {
    if (!kDebugMode) return child;

    return Builder(
      builder: (context) {
        startTimer('$name Build');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          endTimer('$name Build');
        });
        return child;
      },
    );
  }
}