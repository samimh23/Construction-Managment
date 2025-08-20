class Worker {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final String? workerCode;
  final String? assignedSite; // <-- always nullable!
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool faceRegistered;
  final List<double>? faceEmbedding;
  final double? dailyWage;

  Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.email,
    this.phone,
    this.jobTitle,
    this.workerCode,
    this.assignedSite,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.faceRegistered = false,
    this.faceEmbedding,
    this.dailyWage,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? 'worker',
      isActive: json['isActive'] ?? false,
      email: json['email'],
      jobTitle: json['jobTitle'],
      phone: json['phone'],
      workerCode: json['workerCode'],
      assignedSite: json['assignedSite'] is String ? json['assignedSite'] : null,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      faceRegistered: json['faceRegistered'] ?? false,
      faceEmbedding: json['faceEmbedding'] != null
          ? List<double>.from((json['faceEmbedding'] as List).map((x) => x.toDouble()))
          : null,
      dailyWage: json['dailyWage'] != null
          ? (json['dailyWage'] is int
          ? (json['dailyWage'] as int).toDouble()
          : (json['dailyWage'] as num).toDouble())
          : null,
    );
  }
}