import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:failures/failures.dart';

import 'api_logger.dart';

/// HTTP wrapper with the same logging style as Zencillo Inventario / Capturador.
///
/// Every call logs:
/// * REQUEST tag + payload (secrets redacted)
/// * RESPONSE tag + body
/// * DIO EXCEPTION / EXCEPTION on failure
///
/// Adapted for FastAPI JSON (no encryption / no resultSP).
class ApiMethod {
  ApiMethod({required this.dio});

  final Dio dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? operation,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    String? operation,
    bool allowEmptyBody = false,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.post<dynamic>(path, data: data),
      requestBody: data,
      allowEmptyBody: allowEmptyBody,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    String? operation,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.put<dynamic>(path, data: data),
      requestBody: data,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    String? operation,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.patch<dynamic>(path, data: data),
      requestBody: data,
    );
  }

  Future<void> delete(
    String path, {
    Object? data,
    String? operation,
  }) async {
    final tag = operation ?? path;
    await _sendJson(
      tag: tag,
      send: () => dio.delete<dynamic>(path, data: data),
      requestBody: data,
      allowEmptyBody: true,
    );
  }

  /// Returns status code and raw response body (Capturador `rawPost` style).
  Future<(int, String)> rawPost({
    required String path,
    Object? data,
    Options? options,
    String? operation,
  }) async {
    final tag = operation ?? path;
    try {
      ApiLogger.logSave(
        'REQUEST $tag ===> ${ApiLogger.encodePayload(data)} ${DateTime.now()}',
      );

      final response = await dio.post<String>(
        path,
        data: data,
        options: options,
      );

      final body = _bodyAsString(response.data);
      ApiLogger.logSave('RESULT $tag ===> $body ${DateTime.now()}');

      return (response.statusCode ?? 0, body);
    } on SocketException {
      throw const SocketException('');
    } on DioException catch (e) {
      ApiLogger.logSave(
        'DIO EXCEPTION $tag ===> ${ApiLogger.formatDioException(e)} '
        '${DateTime.now()}',
      );
      throw _mapDioException(e);
    } on FormatException catch (e) {
      ApiLogger.logSave('EXCEPTION $tag ===> FormatException ${DateTime.now()}');
      throw RequestException('Formato inválido: ${e.message}');
    }
  }

  /// Returns raw response body (Capturador `rawGet` style).
  Future<String> rawGet({
    required String path,
    Map<String, dynamic>? queryParameters,
    String? operation,
  }) async {
    final tag = operation ?? path;
    try {
      ApiLogger.logSave('REQUEST $tag ===> Done ${DateTime.now()}');

      final response = await dio.get<String>(
        path,
        queryParameters: queryParameters,
      );

      final body = _bodyAsString(response.data);
      ApiLogger.logSave('RESULT $tag ===> $body ${DateTime.now()}');

      return body;
    } on SocketException {
      throw const SocketException('');
    } on DioException catch (e) {
      ApiLogger.logSave(
        'DIO EXCEPTION $tag ===> ${ApiLogger.formatDioException(e)} '
        '${DateTime.now()}',
      );
      throw _mapDioException(e);
    } on FormatException catch (e) {
      ApiLogger.logSave('EXCEPTION $tag ===> FormatException ${DateTime.now()}');
      throw RequestException('Formato inválido: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> _sendJson({
    required String tag,
    required Future<Response<dynamic>> Function() send,
    Object? requestBody,
    bool allowEmptyBody = false,
  }) async {
    try {
      if (requestBody != null) {
        ApiLogger.logSave(
          'REQUEST $tag ===> ${ApiLogger.encodePayload(requestBody)} '
          '${DateTime.now()}',
        );
      } else {
        ApiLogger.logSave('REQUEST $tag ===> Done ${DateTime.now()}');
      }

      final response = await send();
      final code = response.statusCode ?? 0;
      final data = response.data;

      ApiLogger.logSave(
        'RESPONSE $tag ===> ${ApiLogger.encodeResponse(data)} ${DateTime.now()}',
      );

      if (code >= 200 && code < 300) {
        if (data is Map<String, dynamic>) {
          final message = _extractMessage(data);
          if (message != null && message.isNotEmpty) {
            ApiLogger.logSave('MESSAGE $tag ===> $message ${DateTime.now()}');
          }
          return data;
        }
        if (allowEmptyBody && (data == null || data == '')) {
          return <String, dynamic>{};
        }
      }

      final exception = _exceptionForStatus(code, data);
      _logHandledFailure(tag, exception);
      throw exception;
    } on SocketException {
      throw const SocketException('');
    } on DioException catch (e) {
      ApiLogger.logSave(
        'DIO EXCEPTION $tag ===> ${ApiLogger.formatDioException(e)} '
        '${DateTime.now()}',
      );
      if (e.response?.data != null) {
        ApiLogger.logSave(
          'RESPONSE ERROR $tag ===> '
          '${ApiLogger.encodeResponse(e.response?.data)} ${DateTime.now()}',
        );
      }
      throw _mapDioException(e);
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on RequestException {
      rethrow;
    } on FormatException catch (e) {
      ApiLogger.logSave('EXCEPTION $tag ===> FormatException ${DateTime.now()}');
      throw RequestException('Formato inválido: ${e.message}');
    }
  }

  Exception _exceptionForStatus(int statusCode, dynamic data) {
    final message = _extractMessage(data);
    switch (statusCode) {
      case 401:
        return UnauthorizedException(message, statusCode: statusCode);
      case 403:
        return ForbiddenException(message, statusCode: statusCode);
      case 404:
        return NotFoundException(statusCode: statusCode);
      default:
        if (statusCode >= 500) {
          return ServerException(
            message: message ?? 'Error del servidor',
            statusCode: statusCode,
          );
        }
        return RequestException(
          message ?? 'Error del servidor ($statusCode).',
          statusCode: statusCode,
        );
    }
  }

  void _logHandledFailure(String tag, Exception exception) {
    if (exception is UnauthorizedException) {
      ApiLogger.logSave(
        'MESSAGE $tag ===> ${exception.message ?? 'No autorizado'} '
        '${DateTime.now()}',
      );
      return;
    }
    if (exception is ForbiddenException) {
      ApiLogger.logSave(
        'MESSAGE $tag ===> ${exception.message ?? 'Acceso denegado'} '
        '${DateTime.now()}',
      );
      return;
    }
    ApiLogger.logSave(
      'EXCEPTION $tag ===> ${exception.runtimeType} ${DateTime.now()}',
    );
  }

  Exception _mapDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final backendMessage = _extractMessage(data);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        _logConnectionErrorHint(e.message);
        return const NetworkException('Sin conexión con el servidor');
      case DioExceptionType.badResponse:
        if (status == 401) {
          return UnauthorizedException(backendMessage, statusCode: status);
        }
        if (status == 403) {
          return ForbiddenException(backendMessage, statusCode: status);
        }
        if (status == 404) {
          return NotFoundException(statusCode: status);
        }
        if (status != null && status >= 500) {
          return ServerException(
            message: backendMessage ?? 'Error del servidor',
            statusCode: status,
          );
        }
        return RequestException(
          backendMessage ?? 'Solicitud inválida ($status).',
          statusCode: status,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const NetworkException('Sin conexión con el servidor');
    }
  }

  /// Debug-only hint for developers; never surfaced in UI.
  void _logConnectionErrorHint(String? dioMessage) {
    if (dioMessage == null || dioMessage.isEmpty) return;
    final lower = dioMessage.toLowerCase();
    if (lower.contains('cors') || lower.contains('preflight')) {
      ApiLogger.logSave(
        'CORS HINT ===> possible CORS/preflight issue. '
        'Check backend CORS config and origin. ${DateTime.now()}',
      );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          final msg = first['msg'] ?? first['message'];
          if (msg != null) return msg.toString();
        }
      }
      final message = data['message'] ?? data['Message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  String _bodyAsString(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map || data is List) return jsonEncode(data);
    return data.toString();
  }
}
