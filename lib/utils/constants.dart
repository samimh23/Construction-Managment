class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.constructionmanagement.com';
  static const String apiVersion = '/v1';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String rememberMeKey = 'remember_me';
  static const String biometricEnabledKey = 'biometric_enabled';
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration refreshTimeout = Duration(seconds: 15);
  
  // Password Requirements
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  
  // Form Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minCompanyLength = 2;
  static const int maxCompanyLength = 100;
  
  // Phone Number
  static const String phoneNumberPattern = r'^\+?[1-9]\d{1,14}$';
  
  // Rate Limiting
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // App Information
  static const String appName = 'Construction Management';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@constructionmanagement.com';
  static const String privacyPolicyUrl = 'https://constructionmanagement.com/privacy';
  static const String termsOfServiceUrl = 'https://constructionmanagement.com/terms';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}