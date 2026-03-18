import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/auth_interceptor.dart';
import 'package:dompis_app/data/api/token_storage.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient._internal(this.tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio, tokenStorage));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ));
  }

  factory ApiClient(TokenStorage tokenStorage) {
    _instance ??= ApiClient._internal(tokenStorage);
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }
}
