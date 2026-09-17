import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin Dio wrapper: base URL, bearer token, language header and error mapping.
class ApiClient {
  ApiClient({required this._tokens, required String Function() locale, void Function()? onUnauthorized, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          options.headers['Accept-Language'] = locale();
          handler.next(options);
        },
        onError: (error, handler) {
          final path = error.requestOptions.path;
          if (error.response?.statusCode == 401 && !path.startsWith('/auth/')) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokens;
  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<Map<String, dynamic>>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send(() => _dio.post<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> patch(String path, [Object? body]) =>
      _send(() => _dio.patch<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send(() => _dio.put<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> delete(String path, [Object? body]) =>
      _send(() => _dio.delete<Map<String, dynamic>>(path, data: body));

  /// Raw bytes for file downloads (reports).
  Future<List<int>> download(String path) async {
    try {
      final response = await _dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
      return response.data ?? const [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _send(Future<Response<Map<String, dynamic>>> Function() request) async {
    try {
      final response = await request();
      return response.data ?? const {};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
