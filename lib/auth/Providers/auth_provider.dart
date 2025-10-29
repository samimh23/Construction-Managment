import 'package:constructionproject/auth/models/auth_models.dart';
import 'package:constructionproject/auth/models/user.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService}) : _authService = authService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isInitialized => _status != AuthStatus.initial;

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> login(LoginRequest request) async {
    try {
      _setLoading();
      final authResponse = await _authService.login(request);
      // Role-based client-side gating: allow only managers or owners
      final role = authResponse.user.role.toLowerCase();
      const allowedRoles = ['manager', 'construction_manager', 'owner'];

      if (!allowedRoles.contains(role)) {
        // Ensure any stored auth data is cleared (logout) and reject login
        try {
          await _authService.logout();
        } catch (_) {
          // ignore
        }
        _status = AuthStatus.unauthenticated;
        _user = null;
        _errorMessage =
            'Your account is not authorized to access this application.';
        notifyListeners();
        return false;
      }

      _user = authResponse.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    try {
      _setLoading();
      final authResponse = await _authService.register(request);
      _user = authResponse.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add these to your AuthProvider class

  Future<bool> sendResetCode(String email) async {
    try {
      _setLoading();
      await _authService.requestPasswordResetCode(email);
      _errorMessage = null;
      _status = AuthStatus.unauthenticated; // or keep current
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated; // or keep current
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      _setLoading();
      await _authService.resetPasswordWithCode(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _errorMessage = null;
      _status = AuthStatus.unauthenticated; // User needs to log in after reset
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }
  // Add this method to your existing AuthProvider class

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}
