import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/api_client.dart';
import 'package:dompis_app/data/api/token_storage.dart';

class AuthApi {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthApi(ApiClient apiClient, this._tokenStorage) : _dio = apiClient.dio;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;

    if (data['success'] == true) {
      // Store tokens
      final accessToken = data['accessToken'] as String;
      await _tokenStorage.saveAccessToken(accessToken);

      // Store role
      final role = data['role'] as String? ?? '';
      await _tokenStorage.saveRole(role);
    }

    return data;
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiConstants.usersMe);
    return response.data as Map<String, dynamic>;
  }
}
