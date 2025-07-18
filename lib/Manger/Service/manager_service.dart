import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:dio/dio.dart';

class ManagerService {
  final Dio dio;
  final AuthService authService;

  ManagerService(this.dio, this.authService);

  Future<Map<String, dynamic>> fetchSiteAndWorkers() async {
    final token = await authService.getToken();
    if (token == null) throw Exception('No auth token found.');

    dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await dio.get('/users/manager/site-and-workers');
    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to fetch site and workers');
    }
  }
}