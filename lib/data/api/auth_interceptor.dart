import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio, this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login and refresh endpoints
    final path = options.path;
    if (path.contains('/auth/login') || path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    // Don't retry refresh or login endpoints
    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
      await _tokenStorage.clearAll();
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      // Attempt token refresh
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.clearAll();
        return handler.next(err);
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['accessToken'] as String;
        await _tokenStorage.saveAccessToken(newAccessToken);

        // Retry the original request
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _dio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } else {
        await _tokenStorage.clearAll();
        return handler.next(err);
      }
    } catch (_) {
      await _tokenStorage.clearAll();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
