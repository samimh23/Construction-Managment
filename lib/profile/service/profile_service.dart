import 'package:dio/dio.dart';
import 'package:constructionproject/auth/models/user.dart';
import 'package:constructionproject/core/constants/api_constants.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';

class ProfileService {
  final Dio _dio;
  final AuthService _authService; // <-- inject AuthService

  ProfileService(this._dio, this._authService);

  Future<User> fetchProfile() async {
    final token = await _authService.getToken();
    final response = await _dio.get(
      ApiConstants.userProfileEndpoint,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return User.fromJson(response.data);
  }

  Future<User> updateProfile(Map<String, dynamic> updateFields) async {
    final token = await _authService.getToken();
    final response = await _dio.put(
      ApiConstants.updateProfileEndpoint,
      data: updateFields,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return User.fromJson(response.data);
  }
}