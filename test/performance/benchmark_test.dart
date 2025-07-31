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
  group('Performance Benchmarks', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
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

    testWidgets('Screen initialization benchmark', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      stopwatch.stop();

      // More realistic expectation for initialization
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('✅ Screen initialization time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Text input performance benchmark', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));

      final stopwatch = Stopwatch()..start();

      // Type a long email
      await tester.enterText(emailField, 'verylongemailaddress@exampledomainname.com');
      await tester.pump();

      stopwatch.stop();

      // More realistic expectation for text input
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      print('✅ Text input time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('State change performance benchmark', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final stopwatch = Stopwatch()..start();

      // Change loading state
      when(mockAuthProvider.isLoading).thenReturn(true);
      mockAuthProvider.notifyListeners();
      await tester.pump();

      // Change error state
      when(mockAuthProvider.errorMessage).thenReturn('Error message');
      mockAuthProvider.notifyListeners();
      await tester.pump();

      // Reset states
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      mockAuthProvider.notifyListeners();
      await tester.pump();

      stopwatch.stop();

      // Should handle state changes quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
      print('✅ State change time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Widget tree depth performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createTestWidget());

      // Find widgets to ensure they're rendered
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.byType(ElevatedButton), findsOneWidget);

      stopwatch.stop();

      print('✅ Widget tree rendering time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}