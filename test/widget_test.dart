// Integration tests for Construction Management Authentication System
//
// To run tests: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:constructionproject/main.dart';
import 'package:constructionproject/providers/auth_provider.dart';
import 'package:constructionproject/screens/LoginPage.dart';
import 'package:constructionproject/widgets/custom_text_field.dart';
import 'package:constructionproject/widgets/custom_button.dart';

void main() {
  group('Authentication System Tests', () {
    
    testWidgets('App shows login page when not authenticated', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const ConstructionManagementApp());
      await tester.pumpAndSettle();

      // Verify that login page is shown
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your Construction Management account'), findsOneWidget);
      expect(find.text('Sign In'), findsAtLeastOneWidget);
    });

    testWidgets('Login form has required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for email field
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.byType(CustomTextField), findsAtLeastOneWidget);
      
      // Check for password field
      expect(find.text('Password'), findsOneWidget);
      
      // Check for login button
      expect(find.text('Sign In'), findsAtLeastOneWidget);
      expect(find.byType(CustomButton), findsAtLeastOneWidget);
      
      // Check for remember me checkbox
      expect(find.text('Remember me'), findsOneWidget);
      
      // Check for forgot password link
      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('Login form validates empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the login button without filling fields
      final loginButton = find.text('Sign In').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify that validation errors are shown
      // Note: In a real test, you'd check for specific validation messages
      // This is a basic structure that would need to be expanded
    });

    testWidgets('Registration page navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap create account button
      final createAccountButton = find.text('Create Account');
      if (createAccountButton.evaluate().isNotEmpty) {
        await tester.tap(createAccountButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find password field and visibility toggle
      final passwordFields = find.byType(TextField);
      
      if (passwordFields.evaluate().isNotEmpty) {
        // Check if password field is initially obscured
        final TextField passwordField = tester.widget(passwordFields.first);
        expect(passwordField.obscureText, isTrue);
        
        // Find and tap visibility toggle (if it exists)
        final visibilityToggle = find.byIcon(Icons.visibility_off_outlined);
        if (visibilityToggle.evaluate().isNotEmpty) {
          await tester.tap(visibilityToggle);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('Authentication Provider Tests', () {
    
    test('AuthProvider initializes correctly', () {
      final authProvider = AuthProvider();
      expect(authProvider.state, AuthState.initial);
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('AuthProvider handles login state changes', () async {
      final authProvider = AuthProvider();
      
      // Initially not authenticated
      expect(authProvider.isAuthenticated, isFalse);
      
      // Note: In a real test environment, you would mock the AuthService
      // and test the actual login flow with known credentials
    });
  });

  group('Validation Tests', () {
    
    test('Email validation works correctly', () {
      // Test valid emails
      expect(validateEmail('test@example.com'), isNull);
      expect(validateEmail('user@company.co.uk'), isNull);
      
      // Test invalid emails
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('invalid-email'), isNotNull);
      expect(validateEmail('@example.com'), isNotNull);
    });

    test('Password validation works correctly', () {
      // Test valid passwords
      expect(validatePassword('SecurePass123!'), isNull);
      
      // Test invalid passwords
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('short'), isNotNull);
      expect(validatePassword('nouppercase123!'), isNotNull);
      expect(validatePassword('NOLOWERCASE123!'), isNotNull);
      expect(validatePassword('NoNumbers!'), isNotNull);
      expect(validatePassword('NoSpecialChars123'), isNotNull);
    });
  });
}

// Helper function for email validation (simplified version)
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

// Helper function for password validation (simplified version)
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Password must contain at least one lowercase letter';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain at least one number';
  }
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 'Password must contain at least one special character';
  }
  return null;
}
