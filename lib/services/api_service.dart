import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  static const String _baseUrl = AppConstants.baseUrl + AppConstants.apiVersion;
  
  // Get headers with authentication
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': '${AppConstants.appName}/${AppConstants.appVersion}',
    };

    if (includeAuth) {
      final token = StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle HTTP responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
          data: data,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        message: 'Failed to parse server response',
        statusCode: response.statusCode,
      );
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl + endpoint);
      final headers = _getHeaders(includeAuth: includeAuth);
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: 0,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Failed to connect to server. Please try again.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    try {
      Uri uri = Uri.parse(_baseUrl + endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final headers = _getHeaders(includeAuth: includeAuth);
      
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout ?? AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: 0,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Failed to connect to server. Please try again.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl + endpoint);
      final headers = _getHeaders(includeAuth: includeAuth);
      
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: 0,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Failed to connect to server. Please try again.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl + endpoint);
      final headers = _getHeaders(includeAuth: includeAuth);
      
      final response = await http
          .delete(uri, headers: headers)
          .timeout(timeout ?? AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: 0,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Failed to connect to server. Please try again.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isNetworkError => statusCode == 0;
}