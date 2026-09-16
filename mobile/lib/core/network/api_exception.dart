import 'package:dio/dio.dart';

enum ApiErrorKind { network, unauthorized, forbidden, notFound, conflict, validation, rateLimited, server, unknown }

/// Normalized API failure with localized server messages when available.
class ApiException implements Exception {
  const ApiException(this.kind, {this.message, this.fieldErrors = const {}, this.statusCode});

  final ApiErrorKind kind;
  final String? message;
  final Map<String, List<String>> fieldErrors;
  final int? statusCode;

  bool get isNetwork => kind == ApiErrorKind.network;

  String? firstError(String field) => fieldErrors[field]?.firstOrNull;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiException(ApiErrorKind.network);
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    String? message;
    var fields = <String, List<String>>{};
    if (data is Map) {
      message = data['message'] as String?;
      final errors = data['errors'];
      if (errors is Map) {
        fields = errors.map(
          (key, value) => MapEntry(key.toString(), (value as List).map((e) => e.toString()).toList()),
        );
      }
    }

    final kind = switch (status) {
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      422 => ApiErrorKind.validation,
      429 => ApiErrorKind.rateLimited,
      >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };

    return ApiException(kind, message: message, fieldErrors: fields, statusCode: status);
  }

  @override
  String toString() => 'ApiException($kind, $statusCode, $message)';
}
