import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static const String _pendingRequestsKey = 'pending_attendance_requests';

  // Store a pending request
  Future<void> storePendingRequest(Map<String, dynamic> request) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRequests = await getPendingRequests();

    // Add timestamp and unique ID
    request['timestamp'] = DateTime.now().toIso8601String();
    request['id'] = DateTime.now().millisecondsSinceEpoch.toString();

    pendingRequests.add(request);
    await prefs.setString(_pendingRequestsKey, jsonEncode(pendingRequests));
  }

  // Get all pending requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingRequestsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // Remove a specific request by ID
  Future<void> removePendingRequest(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRequests = await getPendingRequests();

    pendingRequests.removeWhere((request) => request['id'] == requestId);
    await prefs.setString(_pendingRequestsKey, jsonEncode(pendingRequests));
  }

  // Clear all pending requests
  Future<void> clearPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRequestsKey);
  }

  // Get pending requests count
  Future<int> getPendingRequestsCount() async {
    final requests = await getPendingRequests();
    return requests.length;
  }
}