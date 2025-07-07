class Worker {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;              // <<-- Add this
  final String? email;
  final String? phone;
  final String? workerCode;         // Optional: add any other backend fields
  final String? assignedSite;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,         // <<-- Add this
    this.email,
    this.phone,
    this.workerCode,
    this.assignedSite,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
      isActive: json['isActive'] ?? false,          // <<-- Add this
      email: json['email'],
      phone: json['phone'],
      workerCode: json['workerCode'],
      assignedSite: json['assignedSite'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}