class ApiConstants {
  static const String productionBaseUrl = 'https://your-api-url.com/api';
  static const String localBaseUrl = 'https://dfe337d7-d01d-4231-a2c1-041f7ce4e916-00-eztmonulzysw.riker.replit.dev/';
  // Switch between environments easily
  static const String baseUrl = localBaseUrl; // Change to productionBaseUrl for production

  // Endpoints (must be relative, not full URLs)
  static const String CreateConstructionsite = 'construction-sites';
  static const String GetConstructionsites = 'construction-sites';
  static const String GetConstructionsiteById = 'construction-sites/'; // +id
  static const String UpdateConstructionsite = 'construction-sites/'; // +id
  static const String DeleteConstructionsite = 'construction-sites/'; // +id

  // Headers for Dio
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts (converted to Duration in Dio)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusUnprocessableEntity = 422;
  static const int statusInternalServerError = 500;
}