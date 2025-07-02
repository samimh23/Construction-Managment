import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      await StorageService.init();
      
      if (AuthService.isAuthenticated()) {
        _user = AuthService.getCurrentUser();
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = 'Failed to initialize authentication';
    }
    notifyListeners();
  }

  // Login functionality
  Future<bool> login(LoginRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.login(request);
      
      if (response.success && response.user != null) {
        _user = response.user;
        _state = AuthState.authenticated;
        _setLoading(false);
        return true;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Login failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Register functionality
  Future<bool> register(RegisterRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.register(request);
      
      if (response.success && response.user != null) {
        _user = response.user;
        _state = AuthState.authenticated;
        _setLoading(false);
        return true;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Registration failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Logout functionality
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await AuthService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout error: $e');
    }
    
    _user = null;
    _state = AuthState.unauthenticated;
    _clearError();
    _setLoading(false);
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await AuthService.refreshToken();
      
      if (response.success) {
        // Token refreshed successfully, maintain current state
        return true;
      } else {
        // Refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      // Refresh failed, logout user
      await logout();
      return false;
    }
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.forgotPassword(email);
      
      if (response.success) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to send password reset email: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      return await AuthService.checkEmailExists(email);
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      // In a real app, this would make an API call to update the user profile
      await StorageService.saveUser(updatedUser);
      _user = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Verify email
  Future<bool> verifyEmail(String verificationCode) async {
    _setLoading(true);
    _clearError();

    try {
      // In a real app, this would make an API call to verify the email
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (_user != null) {
        final updatedUser = _user!.copyWith(isEmailVerified: true);
        await StorageService.saveUser(updatedUser);
        _user = updatedUser;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to verify email: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      // In a real app, this would make an API call to change the password
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to change password: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Force logout (for session timeout or security reasons)
  void forceLogout({String? reason}) {
    _user = null;
    _state = AuthState.unauthenticated;
    _errorMessage = reason ?? 'Session expired. Please login again.';
    StorageService.clearAll();
    notifyListeners();
  }

  // Check if user needs to verify email
  bool get needsEmailVerification {
    return _user != null && !_user!.isEmailVerified;
  }

  // Get user display name
  String get userDisplayName {
    if (_user == null) return '';
    return _user!.fullName.isNotEmpty ? _user!.fullName : _user!.email;
  }

  // Get user initials for avatar
  String get userInitials {
    if (_user == null || _user!.fullName.isEmpty) return '';
    final names = _user!.fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else {
      return names[0][0].toUpperCase();
    }
  }
}