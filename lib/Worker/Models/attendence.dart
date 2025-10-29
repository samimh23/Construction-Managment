class AttendanceSession {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;

  AttendanceSession({this.checkIn, this.checkOut, required this.status});

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      AttendanceSession(
        checkIn:
            json['checkIn'] != null ? DateTime.parse(json['checkIn']) : null,
        checkOut:
            json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
        status: json['status'] as String? ?? 'Unknown',
      );
}

class Attendance {
  final String status;
  final List<AttendanceSession> sessions;

  Attendance({required this.status, required this.sessions});

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final sessionsList = json['sessions'] as List?;
    final sessions =
        sessionsList
            ?.map((s) => AttendanceSession.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return Attendance(status: json['status'] as String, sessions: sessions);
  }

  // Helper getters for backward compatibility
  DateTime? get checkIn => sessions.isNotEmpty ? sessions.first.checkIn : null;
  DateTime? get checkOut => sessions.isNotEmpty ? sessions.last.checkOut : null;
  bool get hasMultipleSessions => sessions.length > 1;
}
