import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? company;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.company,
    this.phone,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      company: json['company'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
            (e) => e.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'company': company,
      'phone': phone,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    company,
    phone,
    role,
    createdAt,
    updatedAt,
  ];
}

enum UserRole {
  admin,
  manager,
  employee,
}