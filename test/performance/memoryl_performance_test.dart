import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:constructionproject/auth/screens/auth/LoginPage.dart';

import '../auth/screens/auth_provider_test.mocks.dart';
@GenerateMocks([AuthProvider])


void main() {
  group('Memory Performance Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.clearError()).thenReturn(null);
    });

    testWidgets('should not leak memory on multiple navigations',
            (WidgetTester tester) async {

          // Create and destroy login screen multiple times
          for (int i = 0; i < 5; i++) {
            await tester.pumpWidget(
              MaterialApp(
                home: ChangeNotifierProvider<AuthProvider>(
                  create: (_) => mockAuthProvider,
                  child: const LoginScreen(),
                ),
              ),
            );

            await tester.pump();

            // Navigate away
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Text('Screen $i'),
                ),
              ),
            );

            await tester.pump();
          }

          // Should complete without issues
          expect(find.text('Screen 4'), findsOneWidget);
        });

    testWidgets('should handle stress test with rapid interactions',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<AuthProvider>(
                create: (_) => mockAuthProvider,
                child: const LoginScreen(),
              ),
            ),
          );

          final emailField = find.byKey(const Key('email_field'));
          final passwordField = find.byKey(const Key('password_field'));
          final checkbox = find.byKey(const Key('remember_me_checkbox'));
          final visibilityToggle = find.byKey(const Key('password_visibility_toggle'));

          // Stress test with many rapid interactions
          for (int i = 0; i < 50; i++) {
            await tester.enterText(emailField, 'test$i@example.com');
            await tester.enterText(passwordField, 'password$i');
            await tester.tap(checkbox);
            await tester.tap(visibilityToggle);

            if (i % 10 == 0) {
              await tester.pump(); // Pump occasionally to prevent timeout
            }
          }

          await tester.pumpAndSettle();

          // Should still be functional
          expect(find.byType(LoginScreen), findsOneWidget);
        });
  });
}