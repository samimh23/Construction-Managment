class ApiConstants {
  static const String productionBaseUrl = 'https://your-api-url.com/api';
  static const String localBaseUrl = 'http://10.181.189.19:3000/';

  static const String baseUrl = localBaseUrl;

  static const String CreateConstructionsite = 'construction-sites';
  static const String GetConstructionsites = 'construction-sites';
  static const String GetConstructionsiteById = 'construction-sites/';
  static const String UpdateConstructionsite = 'construction-sites/';
  static const String DeleteConstructionsite = 'construction-sites/';

  static const String GetConstructionsiteByowner = 'construction-sites/owner/';

  // Headers for Dio
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;


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