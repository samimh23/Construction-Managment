import 'dart:convert';
import 'package:constructionproject/auth/models/user.dart';
import 'package:constructionproject/auth/models/auth_models.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/core/exceptions/app_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _sharedPreferences;

  // Token caching for performance
  String? _cachedToken;
  String? _cachedRefreshToken;
  User? _cachedUser;

  // Prevent multiple refresh attempts
  bool _isRefreshing = false;

  // Request deduplication
  final Map<String, Future<Response>> _pendingRequests = {};

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  AuthService({
    required Dio dio,
    required SharedPreferences sharedPreferences,
  })  : _dio = dio,
        _sharedPreferences = sharedPreferences {
    _setupDio();
    _loadCachedData();
  }

  /// Load cached data on initialization
  void _loadCachedData() {
    _cachedToken = _sharedPreferences.getString(_tokenKey);
    _cachedRefreshToken = _sharedPreferences.getString(_refreshTokenKey);

    try {
      final userDataString = _sharedPreferences.getString(_userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _cachedUser = User.fromJson(userData);
      }
    } catch (e) {
      // Invalid user data, remove it
      _sharedPreferences.remove(_userKey);
    }
  }

  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = Duration(milliseconds: ApiConstants.connectTimeout);
    _dio.options.receiveTimeout = Duration(milliseconds: ApiConstants.receiveTimeout);
    _dio.options.sendTimeout = Duration(milliseconds: ApiConstants.sendTimeout);
    _dio.options.headers.addAll(ApiConstants.defaultHeaders);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == ApiConstants.statusUnauthorized) {
            // Prevent multiple refresh attempts
            if (!_isRefreshing) {
              _isRefreshing = true;
              final refreshed = await _refreshToken();
              _isRefreshing = false;

              if (refreshed) {
                // Update the request with new token
                final newToken = await getToken();
                if (newToken != null) {
                  error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  try {
                    final response = await _dio.fetch(error.requestOptions);
                    handler.resolve(response);
                    return;
                  } catch (retryError) {
                    // If retry fails, continue with original error
                  }
                }
              } else {
                await _clearAuthData();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: request.toJson(),
      );
      // Defensive: check for token before parsing
      if (response.data == null || (response.data['access_token'] ?? response.data['token']) == null) {
        final message = response.data?['message'] ?? 'Login failed. Please check your credentials.';
        throw ValidationException(message);
      }
      final authResponse = AuthResponse.fromJson(response.data);
      await _storeAuthData(authResponse);
      return authResponse;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw AppException('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storeAuthData(authResponse);

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw AppException('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          ApiConstants.logoutEndpoint,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _clearAuthData();
    }
  }

  /// Optimized token retrieval with caching
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = _sharedPreferences.getString(_tokenKey);
    return _cachedToken;
  }

  /// Optimized user retrieval with caching
  Future<User?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;

    try {
      final userDataString = _sharedPreferences.getString(_userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _cachedUser = User.fromJson(userData);
        return _cachedUser;
      }
    } catch (e) {
      await _sharedPreferences.remove(_userKey);
    }
    return null;
  }

  /// Check if user is logged in with token validation
  Future<bool> isLoggedIn() async {
    return await isTokenValid();
  }

  /// Validate token expiration (JWT)
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Basic JWT expiration check
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      // Normalize base64 padding
      String normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = utf8.decode(base64Decode(normalized));
      final payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'];
      if (exp != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isBefore(expiryDate.subtract(const Duration(minutes: 5))); // 5 min buffer
      }
    } catch (e) {
      // If JWT parsing fails, assume token is valid and let server decide
    }

    return true;
  }

  /// Optimized refresh token with correct userId extraction
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _cachedRefreshToken ?? _sharedPreferences.getString(_refreshTokenKey);

      String? userId = _cachedUser?.id;
      if (userId == null) {
        final userDataString = _sharedPreferences.getString(_userKey);
        if (userDataString != null) {
          try {
            final userData = jsonDecode(userDataString) as Map<String, dynamic>;
            userId = userData['_id']?.toString() ?? userData['id']?.toString();
          } catch (e) {
            print('[AuthService] Failed to parse userDataString: $e');
          }
        }
      }

      print('[AuthService] Attempting refresh with userId: $userId, refreshToken: $refreshToken');

      if (refreshToken == null || userId == null) {
        print('[AuthService] Refresh failed: missing userId or refreshToken');
        return false;
      }

      final response = await _dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {
          'userId': userId,
          'refreshToken': refreshToken,
        },
      );

      final data = response.data;
      print('[AuthService] Refresh response: $data');
      if (data['access_token'] != null) {
        data['token'] = data['access_token'];
      }
      // Pass cached user and refresh token!
      final authResponse = AuthResponse.fromJson(
        data,
        previousUser: _cachedUser,
        previousRefreshToken: refreshToken,
      );
      await _storeAuthData(authResponse);

      print('[AuthService] Refresh succeeded, new token: ${authResponse.token}');
      return true;
    } catch (e, stack) {
      print('[AuthService] Refresh failed with exception: $e\n$stack');
      await _clearAuthData();
      return false;
    }
  }

  /// Optimized storage with batch operations and caching
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    // Cache in memory first for immediate access
    _cachedToken = authResponse.token;
    _cachedRefreshToken = authResponse.refreshToken;
    _cachedUser = authResponse.user;

    // Batch write to SharedPreferences for better performance
    await Future.wait([
      _sharedPreferences.setString(_tokenKey, authResponse.token),
      _sharedPreferences.setString(_refreshTokenKey, authResponse.refreshToken),
      _sharedPreferences.setString(_userKey, jsonEncode(authResponse.user.toJson())),
    ]);
  }

  /// Optimized clear with batch operations and cache clearing
  Future<void> _clearAuthData() async {
    // Clear cache first
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;

    // Batch remove from SharedPreferences
    await Future.wait([
      _sharedPreferences.remove(_tokenKey),
      _sharedPreferences.remove(_refreshTokenKey),
      _sharedPreferences.remove(_userKey),
    ]);
  }
  // ... (existing AuthService code above)

  /// Send a password reset code to the user's email
  Future<void> requestPasswordResetCode(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPasswordEndpoint,
        data: {'email': email},
      );
      // Optionally, handle the response if needed
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw AppException('Failed to send reset code: ${e.toString()}');
    }
  }

  /// Reset the password using the code sent to email
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPasswordWithCodeEndpoint,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
      // Optionally, handle the response if needed
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw AppException('Failed to reset password: ${e.toString()}');
    }
  }

  /// Enhanced error handling with specific exception types
  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return AppException('Connection timeout. Please check your internet connection and try again.');
      case DioExceptionType.receiveTimeout:
        return AppException('Server response timeout. Please try again.');
      case DioExceptionType.sendTimeout:
        return AppException('Request timeout. Please try again.');
      case DioExceptionType.connectionError:
        return AppException('No internet connection. Please check your network settings.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Something went wrong';

        switch (statusCode) {
          case ApiConstants.statusBadRequest:
            return ValidationException(message);
          case ApiConstants.statusUnauthorized:
            return UnauthorizedException('Session expired. Please login again.');
          case ApiConstants.statusForbidden:
            return UnauthorizedException('Access denied. You don\'t have permission to perform this action.');
          case ApiConstants.statusNotFound:
            return AppException('Requested resource not found.');
          case ApiConstants.statusUnprocessableEntity:
            return ValidationException(message);
            // case ApiConstants.statusTooManyRequests:
            return AppException('Too many requests. Please wait and try again.');
          case ApiConstants.statusInternalServerError:
            return AppException('Server error. Please try again later.');
          default:
            return AppException('Error $statusCode: $message');
        }
      case DioExceptionType.cancel:
        return AppException('Request was cancelled.');
      case DioExceptionType.unknown:
        return AppException('An unexpected error occurred. Please try again.');
      default:
        return AppException('Something went wrong. Please try again.');
    }
  }

  /// Clear all cached data (useful for testing or forced logout)
  void clearCache() {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
  }

  /// Get cached refresh token
  String? getCachedRefreshToken() {
    return _cachedRefreshToken ?? _sharedPreferences.getString(_refreshTokenKey);
  }

  /// Check if user data is cached
  bool get hasUserCached => _cachedUser != null;

  /// Get user ID quickly from cache
  String? get userId => _cachedUser?.id;

  /// Get user role quickly from cache
  String? get userRole => _cachedUser?.role;
}