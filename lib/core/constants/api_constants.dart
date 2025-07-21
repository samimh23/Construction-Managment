class ApiConstants {
  // Base URLs
  static const String productionBaseUrl = 'https://your-api-url.com/api';
  static const String localBaseUrl = 'http://192.168.115.4:3000';

  // Use this to switch between environments
  static const String baseUrl = localBaseUrl; // Change to productionBaseUrl for production

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String resendVerificationEndpoint = '/auth/resend-verification';

  // User Endpoints

  static const String changePasswordEndpoint = '/user/change-password';
  static const String deleteAccountEndpoint = '/user/delete-account';

  //Profile Endpoints
  static const String userProfileEndpoint = '/users/profile';
  static const String updateProfileEndpoint = '/users/profile';

  // Request Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Request Timeouts (in milliseconds)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusUnprocessableEntity = 422;
  static const int statusInternalServerError = 500;

  // Helper methods to build full URLs
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}