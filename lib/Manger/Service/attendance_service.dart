import 'package:dio/dio.dart';

class AttendanceService {
  final Dio dio;

  AttendanceService(this.dio);

  Future<void> checkIn({required String workerCode, String? siteId}) async {
    final data = {'workerCode': workerCode};
    if (siteId != null) data['siteId'] = siteId;
    await dio.post('/attendance/check-in', data: data);
  }

  Future<void> checkOut({required String workerCode}) async {
    final data = {'workerCode': workerCode};
    await dio.post('/attendance/check-out', data: data);
  }

  /// Register a face for a worker
  Future<void> registerFace({
    required String workerCode,
    required String photoPath,
  }) async {
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
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photoPath, filename: 'face.jpg'),
    });
    await dio.post('/attendance/checkout-face', data: formData);
  }


}