import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';

class AttendanceService {
  final Dio _client;

  AttendanceService(this._client);

  /// Fetches the current position once with high accuracy
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ServerFailure(message: 'Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const ServerFailure(message: 'Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ServerFailure(message: 'Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Calculates distance in meters between two points
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Future<Map<String, dynamic>> checkIn({
    required String employeeId,
    required double lat,
    required double lng,
    required String qrToken,
    String? note,
  }) async {
    try {
      final response = await _client.post('/attendance/check-in', data: {
        'employeeId': employeeId,
        'lat': lat,
        'lng': lng,
        'qrToken': qrToken,
        'note': note,
      });
      return response.data;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Check-in failed');
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required String employeeId,
    required double lat,
    required double lng,
    String? note,
  }) async {
    try {
      final response = await _client.post('/attendance/check-out', data: {
        'employeeId': employeeId,
        'lat': lat,
        'lng': lng,
        'note': note,
      });
      return response.data;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Check-out failed');
    }
  }

  Future<Map<String, dynamic>> getShopSettings() async {
    try {
      final response = await _client.get('/attendance/shop-settings');
      return response.data;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to get shop settings');
    }
  }

  Future<void> updateShopSettings(Map<String, dynamic> settings) async {
    try {
      await _client.post('/attendance/shop-settings', data: settings);
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to update shop settings');
    }
  }

  Future<List<dynamic>> getAttendanceHistory(String employeeId) async {
    try {
      final response = await _client.get('/attendance/employee/$employeeId');
      return response.data as List;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to get history');
    }
  }

  Future<List<dynamic>> getAllAttendance() async {
    try {
      final response = await _client.get('/attendance');
      return response.data as List;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to get records');
    }
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await _client.patch('/attendance/$id', data: data);
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to update record');
    }
  }

  Future<List<dynamic>> getAllShifts() async {
    try {
      final response = await _client.get('/attendance/shifts');
      return response.data as List;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to get shifts');
    }
  }

  Future<Map<String, dynamic>> createShift(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/attendance/shifts', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to create shift');
    }
  }

  Future<Map<String, dynamic>> updateShift(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch('/attendance/shifts/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Failed to update shift');
    }
  }

  /// Self-attendance check-in (no QR token required, GPS + role validation only)
  Future<Map<String, dynamic>> selfCheckIn({
    required String employeeId,
    required double lat,
    required double lng,
    String? note,
  }) async {
    try {
      final response = await _client.post('/attendance/check-in', data: {
        'employeeId': employeeId,
        'lat': lat,
        'lng': lng,
        'selfCheckIn': true,
        'note': note,
      });
      return response.data;
    } on DioException catch (e) {
      throw ServerFailure(message: e.response?.data['message'] ?? 'Self check-in failed');
    }
  }
}

