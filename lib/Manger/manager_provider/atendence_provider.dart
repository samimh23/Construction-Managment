import 'package:flutter/material.dart';
import '../Service/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService attendanceService;
  bool isLoading = false;
  String? error;

  AttendanceProvider(this.attendanceService);

  Future<bool> checkIn(String code, {String? siteId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await attendanceService.checkIn(workerCode: code, siteId: siteId);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut(String code) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await attendanceService.checkOut(workerCode: code);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }


  /// Register worker's face
  Future<bool> registerFace(String workerCode, String photoPath) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await attendanceService.registerFace(workerCode: workerCode, photoPath: photoPath);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check in with face
  Future<bool> checkInWithFace(String photoPath, String siteId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await attendanceService.checkInWithFace(photoPath: photoPath, siteId: siteId);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check out with face
  Future<bool> checkOutWithFace(String photoPath) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await attendanceService.checkOutWithFace(photoPath: photoPath);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
