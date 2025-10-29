import 'package:constructionproject/Worker/Models/attendence.dart';
import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:dio/dio.dart';

class MonthlySalary {
  final int year;
  final int month;
  final double totalHours;
  final double fullDays;
  final double dailyWage;
  final double salary;

  MonthlySalary({
    required this.year,
    required this.month,
    required this.totalHours,
    required this.fullDays,
    required this.dailyWage,
    required this.salary,
  });

  factory MonthlySalary.fromJson(Map<String, dynamic> json) => MonthlySalary(
    year: json['year'],
    month: json['month'],
    totalHours: (json['totalHours'] as num).toDouble(),
    fullDays: (json['fullDays'] as num).toDouble(),
    dailyWage: (json['dailyWage'] as num).toDouble(),
    salary: (json['salary'] as num).toDouble(),
  );
}

class WorkSummary {
  final String date;
  final double totalHours;

  WorkSummary({required this.date, required this.totalHours});

  factory WorkSummary.fromJson(Map<String, dynamic> json) => WorkSummary(
    date: json['date'] as String,
    totalHours: (json['totalHours'] as num).toDouble(),
  );
}

class WorkerService {
  final Dio dio;
  final AuthService authService;

  WorkerService(this.dio, this.authService);

  Future<List<Worker>> fetchWorkersByOwner() async {
    String? token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');

    dio.options.headers['Authorization'] = 'Bearer $token';
    final response = await dio.get('/users/by-owner');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => Worker.fromJson(json))
          .toList();
    } else {
      throw Exception('API did not return a list');
    }
  }

  Future<void> depromoteManagerToWorker({required String managerId}) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    await dio.put(
      '/users/depromote-manager/$managerId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> promoteWorkerToManager({
    required String workerId,
    required String siteId,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    await dio.put(
      '/users/promote/$workerId/site/$siteId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> addCredentialsToWorker({
    required String workerId,
    required String email,
    required String password,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    await dio.put(
      '/users/add-credentials/$workerId',
      data: {'email': email, 'password': password},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> createWorker({
    required String firstName,
    required String lastName,
    required String phone,
    required String jobTitle,
    String? siteId, // Optional
    required double dailyWage,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');

    final data = {
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "jobTitle": jobTitle,
      "dailyWageTND": dailyWage,
      // Only add siteId if it's not null and not empty
      if (siteId != null && siteId.isNotEmpty) "siteId": siteId, // only add if not null
    };

    // Debug: Show request data
    print("Request data: $data"); // <-- Debug, check console output!


    final response = await dio.post(
      '/users/create-worker',
      data: data,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    print("createWorker: response: ${response.data}");
    // Optionally handle errors here
  }

  Future<void> editWorker({
    required String workerId,
    String? firstName,
    String? lastName,
    String? phone,
    String? jobTitle,
    double? dailyWage,
    bool? isActive,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    final updateData = <String, dynamic>{};
    if (firstName != null) updateData['firstName'] = firstName;
    if (lastName != null) updateData['lastName'] = lastName;
    if (phone != null) updateData['phone'] = phone;
    if (jobTitle != null) updateData['jobTitle'] = jobTitle;
    if (dailyWage != null) updateData['dailyWageTND'] = dailyWage;
    if (isActive != null) updateData['isActive'] = isActive;

    await dio.put(
      '/users/edit-worker/$workerId',
      data: updateData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> deleteWorker({
    required String workerId,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    await dio.delete(
      '/users/delete-worker/$workerId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> assignWorkerToSite({
    required String workerId,
    required String siteId,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');

    await dio.put(
      '/users/assign-worker/$workerId/site/$siteId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<List<WorkSummary>> fetchDailySummary({
    required String workerId,
    String? from, // format: 'YYYY-MM-DD'
    String? to,   // format: 'YYYY-MM-DD'
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    dio.options.headers['Authorization'] = 'Bearer $token';

    final queryParameters = {
      'workerId': workerId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };

    final response = await dio.get(
      '/attendance/daily-summary',
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => WorkSummary.fromJson(json))
          .toList();
    } else {
      throw Exception('API did not return a list');
    }
  }

  Future<MonthlySalary> fetchMonthlySalary({
    required String workerId,
    required int year,
    required int month,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await dio.get(
      '/attendance/monthly-salary',
      queryParameters: {
        'workerId': workerId,
        'year': year,
        'month': month,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MonthlySalary.fromJson(data);
    } else {
      throw Exception('API did not return salary object');
    }
  }

  Future<Attendance> fetchTodayAttendance({
    required String workerId,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');
    dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await dio.get('/attendance/today/$workerId');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Attendance.fromJson(data);
    } else {
      throw Exception('API did not return attendance object');
    }
  }

  double calculateMonthlySalaryLocally({
    required List<WorkSummary> summaries,
    required double dailyWage,
  }) {
    final totalHours = summaries.fold(0.0, (sum, ws) => sum + ws.totalHours);
    final fullDays = totalHours / 8.0;
    return fullDays * dailyWage;
  }
}