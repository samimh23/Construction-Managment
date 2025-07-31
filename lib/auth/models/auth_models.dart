import 'package:equatable/equatable.dart';
import 'user.dart';

class LoginRequest extends Equatable {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      rememberMe: json['rememberMe'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    };
  }

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class RegisterRequest extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String company;
  final String password;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.company,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      company: json['company'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'company': company,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [fullName, email, phone, company, password];
}

class AuthResponse extends Equatable {
  final User user;
  final String token;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(
      Map<String, dynamic> json, {
        User? previousUser,
        String? previousRefreshToken,
      }) {
    final token = json['access_token'] ?? json['token'];
    final refreshToken = json['refresh_token'] ?? json['refreshToken'] ?? previousRefreshToken;
    final userJson = json['user'];
    final user = userJson != null
        ? User.fromJson(userJson as Map<String, dynamic>)
        : previousUser;

    if (token == null) {
      throw Exception("Missing 'access_token' in response: $json");
    }
    if (refreshToken == null) {
      throw Exception("Missing 'refresh_token' in response and no fallback provided: $json");
    }
    if (user == null) {
      throw Exception("Missing 'user' in response and no fallback provided: $json");
    }
    return AuthResponse(
      user: user,
      token: token as String,
      refreshToken: refreshToken as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': token,
      'refresh_token': refreshToken,
    };
  }

  @override
  List<Object?> get props => [user, token, refreshToken];
}