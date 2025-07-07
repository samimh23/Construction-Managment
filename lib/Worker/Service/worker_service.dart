import 'package:constructionproject/Worker/Models/worker.dart';
import 'package:dio/dio.dart';
import 'package:constructionproject/services/auth/auth_service.dart';

class WorkerService {
  final Dio dio;
  final AuthService authService;

  WorkerService(this.dio, this.authService);

  Future<List<Worker>> fetchWorkersByOwner() async {
    print("fetchWorkersByOwner STARTED");
    String? token = await authService.getToken();
    print("Token: $token");
    if (token == null) throw Exception('No auth token found.');

    dio.options.headers['Authorization'] = 'Bearer $token';
    print("Header set. About to call Dio.get");
    final response = await dio.get('/users/by-owner');
    print('Dio.get complete');
    print('Status: ${response.statusCode}');
    print('Data: ${response.data}');
    final data = response.data;
    if (data is List) {
      print("Parsing worker list...");
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => Worker.fromJson(json))
          .toList();
    } else {
      print("API did not return a list");
      throw Exception('API did not return a list');
    }
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
    required String siteId,
  }) async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');

    final response = await dio.post(
      '/users/create-worker',
      data: {
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "jobTitle": jobTitle,
        "siteId": siteId,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    // Optionally handle response or errors here
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
}