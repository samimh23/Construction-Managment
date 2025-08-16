import 'package:constructionproject/Manger/Service/conectivty_service.dart';
import 'package:constructionproject/Manger/Service/offline_storage_service.dart';
import 'package:constructionproject/auth/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import '../Service/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService attendanceService;
  final ConnectivityService? connectivityService;
  final OfflineStorageService? offlineStorage;
  final AuthService authService; // Add AuthService as a dependency

  bool isLoading = false;
  String? error;
  int pendingRequestsCount = 0;
  bool isSyncing = false;

  double averageDailyWage = 75.0; // fallback/default

  AttendanceProvider(
      this.attendanceService, {
        required this.authService, // Require AuthService in constructor
        this.connectivityService,
        this.offlineStorage,
      }) {
    _init();
  }

  // Getters for offline capabilities
  bool get hasOfflineCapabilities =>
      connectivityService != null && offlineStorage != null;

  bool get isOffline => connectivityService?.isOnline == false;

  void _init() {
    connectivityService?.addListener(_onConnectivityChanged);
    _updatePendingRequestsCount();
  }

  void _onConnectivityChanged() {
    if (connectivityService?.isOnline == true && pendingRequestsCount > 0) {
      syncPendingRequests();
    }
    notifyListeners();
  }

  Future<void> _updatePendingRequestsCount() async {
    if (offlineStorage != null) {
      pendingRequestsCount = await offlineStorage!.getPendingRequestsCount();
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String errorMessage) {
    error = errorMessage;
    notifyListeners();
  }

  String _parseError(dynamic exception) {
    String errorString = exception.toString();
    if (errorString.contains('400')) {
      return "Worker is already checked in";
    } else if (errorString.contains('404')) {
      return "Worker is not currently checked in";
    } else if (errorString.contains('401')) {
      return "Authentication failed. Please try again";
    } else if (errorString.contains('403')) {
      return "Access denied. Check your permissions";
    } else if (errorString.contains('500')) {
      return "Server error. Please try again later";
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return "Network error. Check your connection";
    } else if (errorString.contains('timeout')) {
      return "Request timeout. Please try again";
    } else {
      return "An error occurred. Please try again";
    }
  }

  Future<bool> checkIn(String code, {String? siteId}) async {
    setLoading(true);
    clearError();

    try {
      await attendanceService.checkIn(workerCode: code, siteId: siteId);
      setLoading(false);
      await _updatePendingRequestsCount();

      if (connectivityService?.isOnline == false) {
        setError("Stored offline. Will sync when connection is restored.");
      }

      return true;
    } catch (e) {
      if (connectivityService?.isOnline == false && offlineStorage != null) {
        setError("Stored offline. Will sync when connection is restored.");
        setLoading(false);
        await _updatePendingRequestsCount();
        return true;
      } else {
        setError(_parseError(e));
        setLoading(false);
        return false;
      }
    }
  }

  Future<bool> checkOut(String code) async {
    setLoading(true);
    clearError();

    try {
      await attendanceService.checkOut(workerCode: code);
      setLoading(false);
      await _updatePendingRequestsCount();

      if (connectivityService?.isOnline == false) {
        setError("Stored offline. Will sync when connection is restored.");
      }

      return true;
    } catch (e) {
      if (connectivityService?.isOnline == false && offlineStorage != null) {
        setError("Stored offline. Will sync when connection is restored.");
        setLoading(false);
        await _updatePendingRequestsCount();
        return true;
      } else {
        setError(_parseError(e));
        setLoading(false);
        return false;
      }
    }
  }

  Map<String, dynamic>? siteDailyAttendance;
  Map<String, dynamic>? ownerDashboardSummary;

  /// Get today's present/absent workers for a specific site
  Future<bool> fetchSiteDailyAttendance(String siteId) async {
    setLoading(true);
    clearError();
    try {
      siteDailyAttendance = await attendanceService.getSiteDailyAttendance(siteId: siteId);
      if (siteDailyAttendance != null && siteDailyAttendance!['present'].isNotEmpty) {
        averageDailyWage = siteDailyAttendance!['present'][0]['dailyWage']?.toDouble() ?? averageDailyWage;
      }
      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setError(_parseError(e));
      setLoading(false);
      return false;
    }
  }

  /// Get dashboard summary for owner/manager (today, month, weekly trends)
  Future<bool> fetchOwnerDashboardSummary() async {
    setLoading(true);
    clearError();
    try {
      final currentUser = await authService.getCurrentUser();
      final managerId = currentUser?.id ?? "unknown";
      ownerDashboardSummary = await attendanceService.getDashboardSummaryForOwner(ownerId: managerId);
      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setError(_parseError(e));
      setLoading(false);
      return false;
    }
  }

  Future<void> syncPendingRequests() async {
    if (isSyncing || connectivityService?.isOnline != true || offlineStorage == null) return;

    isSyncing = true;
    notifyListeners();

    try {
      await attendanceService.syncPendingRequests();
      await _updatePendingRequestsCount();
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Register worker's face
  Future<bool> registerFace(String workerCode, String photoPath) async {
    if (connectivityService?.isOnline == false) {
      setError("Face registration requires internet connection");
      return false;
    }

    setLoading(true);
    clearError();

    try {
      await attendanceService.registerFace(workerCode: workerCode, photoPath: photoPath);
      setLoading(false);
      return true;
    } catch (e) {
      setError(_parseError(e));
      setLoading(false);
      return false;
    }
  }

  /// Check in with face
  Future<bool> checkInWithFace(String photoPath, String siteId) async {
    if (connectivityService?.isOnline == false) {
      setError("Face recognition requires internet connection");
      return false;
    }

    setLoading(true);
    clearError();

    try {
      await attendanceService.checkInWithFace(photoPath: photoPath, siteId: siteId);
      setLoading(false);
      return true;
    } catch (e) {
      setError(_parseError(e));
      setLoading(false);
      return false;
    }
  }

  /// Check out with face
  Future<bool> checkOutWithFace(String photoPath) async {
    if (connectivityService?.isOnline == false) {
      setError("Face recognition requires internet connection");
      return false;
    }

    setLoading(true);
    clearError();

    try {
      await attendanceService.checkOutWithFace(photoPath: photoPath);
      setLoading(false);
      return true;
    } catch (e) {
      setError(_parseError(e));
      setLoading(false);
      return false;
    }
  }

  @override
  void dispose() {
    connectivityService?.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}