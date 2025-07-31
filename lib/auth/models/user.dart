import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final int v;
  final String? refreshToken; // User's refreshToken (optional, can be null)

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      v: json['__v'] as int,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
      'refreshToken': refreshToken,
    };
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    role,
    isActive,
    createdAt,
    updatedAt,
    v,
    refreshToken,
  ];
}