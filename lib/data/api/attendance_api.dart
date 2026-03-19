import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/api_client.dart';

class AttendanceApi {
  final Dio _dio;

  AttendanceApi(ApiClient apiClient) : _dio = apiClient.dio;

  /// Get today's attendance status
  Future<Map<String, dynamic>> getStatus() async {
    final response = await _dio.get(ApiConstants.attendanceStatus);
    return response.data as Map<String, dynamic>;
  }

  /// Check in
  Future<Map<String, dynamic>> checkIn(int workzoneId) async {
    final response = await _dio.post(
      ApiConstants.attendance,
      data: {
        'action': 'check_in',
        'workzone_id': workzoneId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Check out
  Future<Map<String, dynamic>> checkOut(int workzoneId) async {
    final response = await _dio.post(
      ApiConstants.attendance,
      data: {
        'action': 'check_out',
        'workzone_id': workzoneId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get user's service areas (workzones)
  Future<Map<String, dynamic>> getUserServiceAreas() async {
    final response = await _dio.get(ApiConstants.usersMeSa);
    return response.data as Map<String, dynamic>;
  }
}
