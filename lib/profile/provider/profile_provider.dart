import 'package:constructionproject/profile/service/profile_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:constructionproject/auth/models/user.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;
  User? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileProvider(this._service);

  User? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.fetchProfile();
    } catch (e) {
      if (e is DioError) {
        _error = e.response?.data['message'] ?? e.message;
      } else {
        _error = e.toString();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updateFields) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.updateProfile(updateFields);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}