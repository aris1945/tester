import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/api_client.dart';

class TechnicianApi {
  final Dio _dio;

  TechnicianApi(ApiClient apiClient) : _dio = apiClient.dio;

  /// Get technicians list
  Future<Map<String, dynamic>> getTechnicians({
    String? search,
    String? workzone,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (workzone != null && workzone.isNotEmpty) params['workzone'] = workzone;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response =
        await _dio.get(ApiConstants.technicians, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// Get single technician
  Future<Map<String, dynamic>> getTechnician(int id) async {
    final response = await _dio.get(ApiConstants.technicianById(id));
    return response.data as Map<String, dynamic>;
  }

  /// Get technicians by role (for assignment)
  Future<Map<String, dynamic>> getUsersByRole(
    int roleId, {
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get(
      ApiConstants.usersByRole(roleId),
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }
}
