import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null 
        ? DateTime.parse(json['expiresAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user?.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String company;
  final String password;
  final String confirmPassword;
  final bool acceptTerms;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.company,
    required this.password,
    required this.confirmPassword,
    required this.acceptTerms,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'company': company,
      'password': password,
      'confirmPassword': confirmPassword,
      'acceptTerms': acceptTerms,
    };
  }
}