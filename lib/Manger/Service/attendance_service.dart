import 'package:constructionproject/Manger/Service/conectivty_service.dart';
import 'package:dio/dio.dart';
import 'offline_storage_service.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final Dio dio;
  final OfflineStorageService? offlineStorage;
  final ConnectivityService? connectivityService;

  AttendanceService(
      this.dio, {
        this.offlineStorage,
        this.connectivityService,
      });

  Future<void> checkIn({required String workerCode, String? siteId}) async {
    final data = {'workerCode': workerCode};
    if (siteId != null) data['siteId'] = siteId;

    if (connectivityService?.isOnline ?? true) {
      try {
        await dio.post('/attendance/check-in', data: data);
      } catch (e) {
        // If network request fails and offline storage is available, store offline
        if (offlineStorage != null) {
          await _storeOfflineRequest('check-in', data);
        }
        rethrow;
      }
    } else {
      // Store for later sync if offline storage is available
      if (offlineStorage != null) {
        await _storeOfflineRequest('check-in', data);
      } else {
        throw Exception('No internet connection');
      }
    }
  }

  Future<void> checkOut({required String workerCode, required String siteId}) async {
    final data = {'workerCode': workerCode, 'siteId': siteId};

    if (connectivityService?.isOnline ?? true) {
      try {
        await dio.post('/attendance/check-out', data: data);
      } catch (e) {
        // If network request fails and offline storage is available, store offline
        if (offlineStorage != null) {
          await _storeOfflineRequest('check-out', data);
        }
        rethrow;
      }
    } else {
      // Store for later sync if offline storage is available
      if (offlineStorage != null) {
        await _storeOfflineRequest('check-out', data);
      } else {
        throw Exception('No internet connection');
      }
    }
  }

  // Store request for offline sync
  Future<void> _storeOfflineRequest(String type, Map<String, dynamic> data) async {
    final request = {
      'type': type,
      'data': data,
    };
    await offlineStorage!.storePendingRequest(request);
  }

  // Sync all pending requests
  Future<void> syncPendingRequests() async {
    if (offlineStorage == null || connectivityService?.isOnline != true) return;

    final pendingRequests = await offlineStorage!.getPendingRequests();
    final List<String> successfulRequestIds = [];

    for (final request in pendingRequests) {
      try {
        final type = request['type'] as String;
        final data = request['data'] as Map<String, dynamic>;

        switch (type) {
          case 'check-in':
            await dio.post('/attendance/check-in', data: data);
            break;
          case 'check-out':
            await dio.post('/attendance/check-out', data: data);
            break;
        }

        successfulRequestIds.add(request['id']);
      } catch (e) {
        // Keep the request for next sync attempt
        debugPrint('Failed to sync request ${request['id']}: $e');
      }
    }

    // Remove successfully synced requests
    for (final requestId in successfulRequestIds) {
      await offlineStorage!.removePendingRequest(requestId);
    }
  }

  /// Register a face for a worker
  Future<void> registerFace({
    required String workerCode,
    required String photoPath,
  }) async {
    if (connectivityService?.isOnline == false) {
      throw Exception('Face registration requires internet connection');
    }

    final formData = FormData.fromMap({
      'workerCode': workerCode,
      'file': await MultipartFile.fromFile(photoPath, filename: 'face.jpg'),
    });
    await dio.post('/attendance/register-face', data: formData);
  }

  /// Check in with face (photo)
  Future<void> checkInWithFace({
    required String photoPath,
    required String siteId,
  }) async {
    if (connectivityService?.isOnline == false) {
      throw Exception('Face recognition requires internet connection');
    }

    final formData = FormData.fromMap({
      'siteId': siteId,
      'file': await MultipartFile.fromFile(photoPath, filename: 'face.jpg'),
    });
    await dio.post('/attendance/checkin-face', data: formData);
  }

  /// Check out with face (NO code needed)
  Future<void> checkOutWithFace({
    required String photoPath,
  }) async {
    if (connectivityService?.isOnline == false) {
      throw Exception('Face recognition requires internet connection');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photoPath, filename: 'face.jpg'),
    });
    await dio.post('/attendance/checkout-face', data: formData);
  }
  Future<Map<String, dynamic>> getSiteDailyAttendance({required String siteId}) async {
    final response = await dio.get(
      '/attendance/site-daily-attendance',
      queryParameters: {'siteId': siteId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get owner-wide dashboard attendance summary (today, month, weekly trends)
  Future<Map<String, dynamic>> getDashboardSummaryForOwner({required String ownerId}) async {
    final response = await dio.get(
      '/attendance/dashboard-summary/owner',
      queryParameters: {'ownerId': ownerId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get today's attendance status for a specific worker - NEW METHOD
  Future<Map<String, dynamic>> getTodayAttendanceForWorker({required String workerId}) async {
    final response = await dio.get('/attendance/today/$workerId');
    return response.data as Map<String, dynamic>;
  }
}