import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  // Login functionality
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Simulate API call for demo purposes (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      
      // Demo validation - replace with actual API integration
      if (request.email == 'demo@construction.com' && request.password == 'Demo123!') {
        final user = User(
          id: _generateId(),
          fullName: 'Demo User',
          email: request.email,
          phoneNumber: '+1234567890',
          company: 'Demo Construction Inc.',
          createdAt: DateTime.now(),
          isEmailVerified: true,
        );

        final accessToken = _generateToken();
        final refreshToken = _generateToken();
        
        // Save tokens and user data
        await StorageService.saveAccessToken(accessToken);
        await StorageService.saveRefreshToken(refreshToken);
        await StorageService.saveUser(user);
        await StorageService.setRememberMe(request.rememberMe);

        return AuthResponse(
          success: true,
          message: 'Login successful',
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Actual API call implementation (uncomment when backend is ready)
      /*
      final response = await ApiService.post(
        AppConstants.loginEndpoint,
        body: request.toJson(),
        includeAuth: false,
      );

      final authResponse = AuthResponse.fromJson(response);
      
      if (authResponse.success) {
        // Save authentication data
        if (authResponse.accessToken != null) {
          await StorageService.saveAccessToken(authResponse.accessToken!);
        }
        if (authResponse.refreshToken != null) {
          await StorageService.saveRefreshToken(authResponse.refreshToken!);
        }
        if (authResponse.user != null) {
          await StorageService.saveUser(authResponse.user!);
        }
        await StorageService.setRememberMe(request.rememberMe);
      }

      return authResponse;
      */
    } catch (e) {
      if (e is ApiException) {
        return AuthResponse(
          success: false,
          message: e.message,
        );
      }
      return AuthResponse(
        success: false,
        message: 'An unexpected error occurred during login',
      );
    }
  }

  // Register functionality
  static Future<AuthResponse> register(RegisterRequest request) async {
    try {
      // Simulate API call for demo purposes
      await Future.delayed(const Duration(seconds: 3)); // Simulate network delay
      
      // Demo email check
      if (request.email == 'demo@construction.com') {
        return AuthResponse(
          success: false,
          message: 'Email address is already registered',
        );
      }

      // Create demo user
      final user = User(
        id: _generateId(),
        fullName: request.fullName,
        email: request.email,
        phoneNumber: request.phoneNumber,
        company: request.company,
        createdAt: DateTime.now(),
        isEmailVerified: false,
      );

      final accessToken = _generateToken();
      final refreshToken = _generateToken();
      
      // Save tokens and user data
      await StorageService.saveAccessToken(accessToken);
      await StorageService.saveRefreshToken(refreshToken);
      await StorageService.saveUser(user);

      return AuthResponse(
        success: true,
        message: 'Registration successful. Please verify your email address.',
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // Actual API call implementation (uncomment when backend is ready)
      /*
      final response = await ApiService.post(
        AppConstants.registerEndpoint,
        body: request.toJson(),
        includeAuth: false,
      );

      final authResponse = AuthResponse.fromJson(response);
      
      if (authResponse.success) {
        // Save authentication data
        if (authResponse.accessToken != null) {
          await StorageService.saveAccessToken(authResponse.accessToken!);
        }
        if (authResponse.refreshToken != null) {
          await StorageService.saveRefreshToken(authResponse.refreshToken!);
        }
        if (authResponse.user != null) {
          await StorageService.saveUser(authResponse.user!);
        }
      }

      return authResponse;
      */
    } catch (e) {
      if (e is ApiException) {
        return AuthResponse(
          success: false,
          message: e.message,
        );
      }
      return AuthResponse(
        success: false,
        message: 'An unexpected error occurred during registration',
      );
    }
  }

  // Logout functionality
  static Future<void> logout() async {
    try {
      // Actual API call (uncomment when backend is ready)
      /*
      await ApiService.post(
        AppConstants.logoutEndpoint,
        includeAuth: true,
      );
      */
      
      // Clear all stored data
      await StorageService.clearAll();
    } catch (e) {
      // Even if logout API fails, clear local data
      await StorageService.clearAll();
    }
  }

  // Refresh token functionality
  static Future<AuthResponse> refreshToken() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null) {
        throw const ApiException(
          message: 'No refresh token available',
          statusCode: 401,
        );
      }

      // Actual API call (uncomment when backend is ready)
      /*
      final response = await ApiService.post(
        AppConstants.refreshTokenEndpoint,
        body: {'refreshToken': refreshToken},
        includeAuth: false,
        timeout: AppConstants.refreshTimeout,
      );

      final authResponse = AuthResponse.fromJson(response);
      
      if (authResponse.success && authResponse.accessToken != null) {
        await StorageService.saveAccessToken(authResponse.accessToken!);
        if (authResponse.refreshToken != null) {
          await StorageService.saveRefreshToken(authResponse.refreshToken!);
        }
      }

      return authResponse;
      */

      // Demo implementation
      await Future.delayed(const Duration(seconds: 1));
      final newAccessToken = _generateToken();
      await StorageService.saveAccessToken(newAccessToken);
      
      return AuthResponse(
        success: true,
        message: 'Token refreshed successfully',
        accessToken: newAccessToken,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    } catch (e) {
      if (e is ApiException) {
        return AuthResponse(
          success: false,
          message: e.message,
        );
      }
      return AuthResponse(
        success: false,
        message: 'Failed to refresh authentication token',
      );
    }
  }

  // Forgot password functionality
  static Future<AuthResponse> forgotPassword(String email) async {
    try {
      // Actual API call (uncomment when backend is ready)
      /*
      final response = await ApiService.post(
        AppConstants.forgotPasswordEndpoint,
        body: {'email': email},
        includeAuth: false,
      );

      return AuthResponse.fromJson(response);
      */

      // Demo implementation
      await Future.delayed(const Duration(seconds: 2));
      return AuthResponse(
        success: true,
        message: 'Password reset instructions sent to your email',
      );
    } catch (e) {
      if (e is ApiException) {
        return AuthResponse(
          success: false,
          message: e.message,
        );
      }
      return AuthResponse(
        success: false,
        message: 'Failed to send password reset email',
      );
    }
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    return StorageService.isLoggedIn();
  }

  // Get current user
  static User? getCurrentUser() {
    return StorageService.getUser();
  }

  // Check if email exists (for registration)
  static Future<bool> checkEmailExists(String email) async {
    try {
      // Actual API call (uncomment when backend is ready)
      /*
      final response = await ApiService.get(
        '/auth/check-email',
        queryParams: {'email': email},
        includeAuth: false,
      );

      return response['exists'] ?? false;
      */

      // Demo implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return email == 'demo@construction.com';
    } catch (e) {
      return false;
    }
  }

  // Helper methods for demo
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  static String _generateToken() {
    final bytes = utf8.encode(DateTime.now().millisecondsSinceEpoch.toString() + 
                             Random().nextInt(10000).toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}