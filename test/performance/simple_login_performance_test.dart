import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:constructionproject/auth/screens/auth/LoginPage.dart';
import 'package:constructionproject/auth/Providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../auth/screens/auth_provider_test.mocks.dart';

@GenerateMocks([AuthProvider])

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Performance Integration Tests', () {
    testWidgets('Login screen rendering performance test', (WidgetTester tester) async {
      final mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.clearError()).thenReturn(null);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Should render quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      print('✅ Login screen rendering time: ${stopwatch.elapsedMilliseconds}ms');

      // Verify form elements exist
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Form interaction performance test', (WidgetTester tester) async {
      final mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.clearError()).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final checkbox = find.byType(Checkbox);

      final stopwatch = Stopwatch()..start();

      // Interact with form elements
      if (textFields.hasFound && textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pump();

        await tester.enterText(textFields.at(1), 'password123');
        await tester.pump();
      }

      if (checkbox.hasFound) {
        await tester.tap(checkbox);
        await tester.pump();
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('✅ Form interaction time: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}