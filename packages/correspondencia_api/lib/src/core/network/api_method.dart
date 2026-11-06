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

  /// GET returning a JSON array (e.g. `/document-types`, `/movements`).
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? operation,
  }) {
    final tag = operation ?? path;
    return _sendJsonList(
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

  /// POST multipart/form-data (e.g. file uploads).
  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required FormData data,
    String? operation,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.post<dynamic>(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      ),
      requestBody: 'multipart/form-data',
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

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    String? operation,
    bool allowEmptyBody = false,
  }) {
    final tag = operation ?? path;
    return _sendJson(
      tag: tag,
      send: () => dio.delete<dynamic>(path, data: data),
      requestBody: data,
      allowEmptyBody: allowEmptyBody,
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
      ApiLogger.logSave(
          'EXCEPTION $tag ===> FormatException ${DateTime.now()}');
      throw RequestException('Formato inválido: ${e.message}');
    }
  }

  /// GET returning raw bytes (PDF, exports, etc.).
  Future<List<int>> downloadBytes({
    required String path,
    Map<String, dynamic>? queryParameters,
    String? operation,
  }) async {
    final tag = operation ?? path;
    try {
      ApiLogger.logSave('REQUEST $tag ===> Done ${DateTime.now()}');
      final response = await dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      final code = response.statusCode ?? 0;
      final data = response.data ?? const <int>[];

      ApiLogger.logSave(
        'RESPONSE $tag ===> ${data.length} bytes ${DateTime.now()}',
      );

      if (code >= 200 && code < 300) {
        return data;
      }

      final exception = _exceptionForStatus(code, null);
      _logHandledFailure(tag, exception);
      throw exception;
    } on SocketException {
      throw const SocketException('');
    } on DioException catch (e) {
      ApiLogger.logSave(
        'DIO EXCEPTION $tag ===> ${ApiLogger.formatDioException(e)} '
        '${DateTime.now()}',
      );
      throw _mapDioException(e);
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
      ApiLogger.logSave(
          'EXCEPTION $tag ===> FormatException ${DateTime.now()}');
      throw RequestException('Formato inválido: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> _sendJsonList({
    required String tag,
    required Future<Response<dynamic>> Function() send,
  }) async {
    try {
      ApiLogger.logSave('REQUEST $tag ===> Done ${DateTime.now()}');
      final response = await send();
      final code = response.statusCode ?? 0;
      final data = response.data;

      ApiLogger.logSave(
        'RESPONSE $tag ===> ${ApiLogger.encodeResponse(data)} ${DateTime.now()}',
      );

      if (code >= 200 && code < 300) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
        }
      }

      final exception = _exceptionForStatus(code, data);
      _logHandledFailure(tag, exception);
      throw exception;
    } on DioException catch (e) {
      ApiLogger.logSave(
        'DIO EXCEPTION $tag ===> ${ApiLogger.formatDioException(e)} '
        '${DateTime.now()}',
      );
      throw _mapDioException(e);
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
    } on ValidationException {
      rethrow;
    } on FormatException catch (e) {
      ApiLogger.logSave(
          'EXCEPTION $tag ===> FormatException ${DateTime.now()}');
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
      case 409:
        return ConflictException(
          message ?? 'El registro ingresado ya existe.',
          statusCode: statusCode,
        );
      case 400:
      case 422:
        return ValidationException(
          message ?? 'Datos inválidos.',
        );
      default:
        if (statusCode >= 500) {
          return ServerException(
            message: 'Error del servidor. Intente nuevamente.',
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
    if (exception is ValidationException) {
      ApiLogger.logSave(
        'MESSAGE $tag ===> ${exception.message} ${DateTime.now()}',
      );
      return;
    }
    if (exception is RequestException) {
      ApiLogger.logSave(
        'MESSAGE $tag ===> ${exception.message ?? 'Solicitud inválida'} '
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
        if (status == 409) {
          return ConflictException(
            backendMessage ?? 'El registro ingresado ya existe.',
            statusCode: status,
          );
        }
        if (status == 400 || status == 422) {
          return ValidationException(
            backendMessage ?? 'Datos inválidos.',
          );
        }
        if (status != null && status >= 500) {
          return ServerException(
            message: 'Error del servidor. Intente nuevamente.',
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
        return detail
            .whereType<Map>()
            .map(_validationMessage)
            .toSet()
            .take(5)
            .join('\n');
      }
      final message = data['message'] ?? data['Message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }

  String _validationMessage(Map error) {
    const labels = <String, String>{
      'username': 'Usuario',
      'password': 'Contraseña',
      'initial_password': 'Contraseña inicial',
      'new_password': 'Nueva contraseña',
      'current_password': 'Contraseña actual',
      'confirm_password': 'Confirmación de contraseña',
      'email': 'Correo',
      'first_name': 'Nombre',
      'last_name': 'Apellido',
      'subject': 'Asunto',
      'reference': 'Referencia',
      'document_number': 'Documento',
      'document_type_id': 'Tipo de documento',
      'initial_to_unit_id': 'Unidad destino',
      'to_unit_id': 'Unidad destino',
      'initial_to_user_id': 'Funcionario destino',
      'to_user_id': 'Funcionario destino',
      'employee_id': 'Funcionario',
      'origin_employee_id': 'Funcionario de origen',
      'sender_name': 'Remitente',
      'code': 'Código',
      'name': 'Nombre',
      'role_codes': 'Roles',
      'mayor_display_name': 'Nombre del titular ejecutivo',
      'institutional_email': 'Correo institucional',
      'sender_document': 'Documento del solicitante',
      'sender_contact': 'Contacto del solicitante',
      'origin_description': 'Descripción del origen',
      'description': 'Descripción',
      'content': 'Contenido',
      'instruction': 'Instrucción',
      'initial_instruction': 'Instrucción inicial',
      'observation': 'Observación',
      'unit_id': 'Unidad',
      'position_id': 'Cargo',
      'hierarchy_id': 'Jerarquía',
      'role_ids': 'Roles',
      'direct_permission_ids': 'Permisos',
      'first_recipient_employee_id': 'Receptor inicial',
      'initial_recipient_employee_ids': 'Receptores iniciales',
      'intake_unit_id': 'Unidad de Ventanilla',
      'page_count': 'Número de hojas',
      'emission_date': 'Fecha de emisión',
      'emission_time': 'Hora de emisión',
      'route_sheet_number': 'Número de Hoja de Ruta',
      'priority': 'Prioridad',
      'correspondence_type': 'Tipo de correspondencia',
    };
    final location = error['loc'];
    final field = location is List
        ? location.reversed
            .map((key) => labels[key])
            .whereType<String>()
            .firstOrNull
        : null;
    final context = error['ctx'];
    num? limit(String key) {
      final value = context is Map ? context[key] : null;
      return value is num && value.isFinite ? value : null;
    }

    final minimum = limit('min_length');
    final maximum = limit('max_length');
    String characters(num count) => count == 1 ? 'carácter' : 'caracteres';
    final message = switch (error['type']) {
      'missing' => 'Este campo es obligatorio.',
      'string_too_long' => maximum != null
          ? 'Debe tener como máximo $maximum ${characters(maximum)}.'
          : 'Reduzca el contenido a la longitud máxima permitida.',
      'string_too_short' => minimum != null
          ? 'Debe tener al menos $minimum ${characters(minimum)}.'
          : 'Complete el campo con la longitud mínima requerida.',
      'too_short' => minimum != null
          ? 'Seleccione al menos $minimum ${minimum == 1 ? 'opción' : 'opciones'}.'
          : 'Seleccione las opciones requeridas.',
      'too_long' => maximum != null
          ? 'Seleccione como máximo $maximum ${maximum == 1 ? 'opción' : 'opciones'}.'
          : 'Reduzca la cantidad de opciones seleccionadas.',
      'uuid_parsing' || 'uuid_type' => 'Seleccione una opción válida.',
      'literal_error' || 'enum' => 'Seleccione una opción válida.',
      'string_type' => 'Ingrese un texto válido.',
      'date_parsing' ||
      'date_from_datetime_parsing' =>
        'Ingrese una fecha válida.',
      'time_parsing' => 'Ingrese una hora válida.',
      'int_parsing' ||
      'int_type' ||
      'float_parsing' =>
        'Ingrese un número válido.',
      'greater_than' => limit('gt') != null
          ? 'Debe ser mayor que ${limit('gt')}.'
          : 'Ingrese un número mayor al mínimo permitido.',
      'greater_than_equal' => limit('ge') != null
          ? 'Debe ser mayor o igual a ${limit('ge')}.'
          : 'Ingrese un número igual o mayor al mínimo permitido.',
      'less_than' => limit('lt') != null
          ? 'Debe ser menor que ${limit('lt')}.'
          : 'Ingrese un número menor al máximo permitido.',
      'less_than_equal' => limit('le') != null
          ? 'Debe ser menor o igual a ${limit('le')}.'
          : 'Ingrese un número igual o menor al máximo permitido.',
      'value_error' when field == 'Correo' || field == 'Correo institucional' =>
        'Ingrese un correo electrónico válido.',
      _ => 'Revise el valor ingresado.',
    };
    return '${field ?? 'Datos'}: $message';
  }

  String _bodyAsString(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map || data is List) return jsonEncode(data);
    return data.toString();
  }
}
