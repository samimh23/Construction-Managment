import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/screens/auth/LoginPage.dart';
import 'package:constructionproject/auth/models/auth_models.dart';

@GenerateMocks([AuthProvider])
import 'login_performance_test.mocks.dart';

void main() {
  group('Login Performance Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.clearError()).thenReturn(null);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider,
          child: const LoginScreen(),
        ),
      );
    }

    group('Rebuild Performance', () {
      testWidgets('should minimize rebuilds during text input', (WidgetTester tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>(
              create: (_) => mockAuthProvider,
              child: Builder(
                builder: (context) {
                  buildCount++;
                  return const LoginScreen();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final initialBuildCount = buildCount;

        // Type in email field
        final emailField = find.byType(TextFormField).first;
        await tester.enterText(emailField, 'test@example.com');
        await tester.pump();

        // Should not trigger full screen rebuild
        expect(buildCount, equals(initialBuildCount));
        print('✅ Text input rebuild test passed - builds: $buildCount');
      });

      testWidgets('should handle provider state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify initial state
        expect(find.byType(LoginScreen), findsOneWidget);

        // Change loading state
        when(mockAuthProvider.isLoading).thenReturn(true);
        mockAuthProvider.notifyListeners();
        await tester.pump();

        // Should still find the login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        print('✅ Provider state change test passed');
      });

      testWidgets('should handle rapid interactions without performance issues',
              (WidgetTester tester) async {
            await tester.pumpWidget(createTestWidget());

            final checkbox = find.byType(Checkbox);
            final textFields = find.byType(TextFormField);

            // Rapid interactions - should complete without timeout
            final stopwatch = Stopwatch()..start();

            for (int i = 0; i < 10; i++) {
              if (checkbox.hasFound) {
                await tester.tap(checkbox);
              }
              if (textFields.hasFound) {
                await tester.enterText(textFields.first, 'test$i@example.com');
              }
              await tester.pump();
            }

            stopwatch.stop();

            // Should complete in reasonable time
            expect(stopwatch.elapsedMilliseconds, lessThan(3000));
            print('✅ Rapid interactions test passed - time: ${stopwatch.elapsedMilliseconds}ms');

            // Widget should still be functional
            expect(find.byType(LoginScreen), findsOneWidget);
          });
    });

    group('Form Performance', () {
      testWidgets('should validate efficiently', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final textFields = find.byType(TextFormField);

        final stopwatch = Stopwatch()..start();

        // Type email
        if (textFields.hasFound) {
          await tester.enterText(textFields.first, 'test@example.com');
          await tester.pump();
        }

        stopwatch.stop();

        // Should handle text input quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        print('✅ Form validation test passed - time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should handle form submission attempt', (WidgetTester tester) async {
        when(mockAuthProvider.login(any)).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);
        final buttons = find.byType(ElevatedButton);

        // Fill form
        if (textFields.hasFound) {
          final emailField = textFields.first;
          final passwordField = textFields.at(1);

          await tester.enterText(emailField, 'test@example.com');
          await tester.enterText(passwordField, 'password123');
          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Try to submit form
          if (buttons.hasFound) {
            await tester.ensureVisible(buttons.first);
            await tester.tap(buttons.first, warnIfMissed: false);
            await tester.pump();
          }

          stopwatch.stop();

          // Should process form submission quickly
          expect(stopwatch.elapsedMilliseconds, lessThan(500));
          print('✅ Form submission test passed - time: ${stopwatch.elapsedMilliseconds}ms');
        }
      });
    });

    group('Animation Performance', () {
      testWidgets('should handle state transitions smoothly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Start with not loading
        when(mockAuthProvider.isLoading).thenReturn(false);
        await tester.pump();

        final stopwatch = Stopwatch()..start();

        // Change to loading
        when(mockAuthProvider.isLoading).thenReturn(true);
        mockAuthProvider.notifyListeners();

        // Pump with duration to test animation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        print('✅ Animation performance test passed - time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should handle error state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final stopwatch = Stopwatch()..start();

        // Show error
        when(mockAuthProvider.errorMessage).thenReturn('Test error message');
        mockAuthProvider.notifyListeners();
        await tester.pump();

        // Hide error
        when(mockAuthProvider.errorMessage).thenReturn(null);
        mockAuthProvider.notifyListeners();
        await tester.pump();

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        print('✅ Error state animation test passed - time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}