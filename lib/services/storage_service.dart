import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class StorageService {
  static late SharedPreferences _prefs;
  
  // Initialize the storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveAccessToken(String token) async {
    await _prefs.setString(AppConstants.accessTokenKey, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(AppConstants.refreshTokenKey, token);
  }

  static String? getAccessToken() {
    return _prefs.getString(AppConstants.accessTokenKey);
  }

  static String? getRefreshToken() {
    return _prefs.getString(AppConstants.refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
  }

  // User data management
  static Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(AppConstants.userDataKey, userJson);
  }

  static User? getUser() {
    final userJson = _prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        // If there's an error parsing user data, remove it
        _prefs.remove(AppConstants.userDataKey);
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUser() async {
    await _prefs.remove(AppConstants.userDataKey);
  }

  // Remember me functionality
  static Future<void> setRememberMe(bool remember) async {
    await _prefs.setBool(AppConstants.rememberMeKey, remember);
  }

  static bool getRememberMe() {
    return _prefs.getBool(AppConstants.rememberMeKey) ?? false;
  }

  // Biometric settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.biometricEnabledKey, enabled);
  }

  static bool getBiometricEnabled() {
    return _prefs.getBool(AppConstants.biometricEnabledKey) ?? false;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    final token = getAccessToken();
    final user = getUser();
    return token != null && token.isNotEmpty && user != null;
  }

  // Clear all authentication data
  static Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await _prefs.remove(AppConstants.rememberMeKey);
    await _prefs.remove(AppConstants.biometricEnabledKey);
  }

  // Generic storage methods
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}