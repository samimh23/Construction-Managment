import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/auth_models.dart';
import '../../Models/user.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/app_exceptions.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _sharedPreferences;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  AuthService({
    required Dio dio,
    required SharedPreferences sharedPreferences,
  })  : _dio = dio,
        _sharedPreferences = sharedPreferences {
    _setupDio();
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
            final refreshed = await _refreshToken();
            if (refreshed) {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } else {
              await _clearAuthData();
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

  Future<String?> getToken() async {
    return _sharedPreferences.getString(_tokenKey);
  }

  Future<User?> getCurrentUser() async {
    try {
      final userDataString = _sharedPreferences.getString(_userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        return User.fromJson(userData);
      }
    } catch (e) {
      await _sharedPreferences.remove(_userKey);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _sharedPreferences.getString(_refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storeAuthData(authResponse);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _sharedPreferences.setString(_tokenKey, authResponse.token);
    await _sharedPreferences.setString(_refreshTokenKey, authResponse.refreshToken);
    await _sharedPreferences.setString(_userKey, jsonEncode(authResponse.user.toJson()));
  }

  Future<void> _clearAuthData() async {
    await _sharedPreferences.remove(_tokenKey);
    await _sharedPreferences.remove(_refreshTokenKey);
    await _sharedPreferences.remove(_userKey);
  }

  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppException('Connection timeout. Please try again.');
      case DioExceptionType.connectionError:
        return AppException('No internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Something went wrong';

        switch (statusCode) {
          case ApiConstants.statusBadRequest:
            return ValidationException(message);
          case ApiConstants.statusUnauthorized:
            return UnauthorizedException(message);
          case ApiConstants.statusUnprocessableEntity:
            return ValidationException(message);
          default:
            return AppException(message);
        }
      default:
        return AppException('Something went wrong. Please try again.');
    }
  }
}