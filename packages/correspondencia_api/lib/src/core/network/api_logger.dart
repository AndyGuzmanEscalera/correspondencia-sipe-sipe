import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging helpers for [ApiMethod].
///
/// Same spirit as Capturador's `ApiMethod.logSave`: every request/response
/// is traced in debug so you can see exactly what goes out and what comes back.
/// Sensitive fields are redacted before printing.
class ApiLogger {
  ApiLogger._();

  static const _secretKeys = {
    'password',
    'contrasena',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'cookie',
  };

  static void logSave(String message) {
    if (kDebugMode) {
      log('ApiMethod: $message', name: 'ApiMethod');
    }
  }

  static String encodePayload(Object? data) {
    if (data == null) return '';
    if (data is String) return redactString(data);
    if (data is Map || data is List) {
      return jsonEncode(redact(data));
    }
    return data.toString();
  }

  static String redactString(String value) {
    try {
      final decoded = jsonDecode(value);
      return jsonEncode(redact(decoded));
    } catch (_) {
      return value;
    }
  }

  static dynamic redact(dynamic value) {
    if (value is Map) {
      return value.map((key, v) {
        if (_secretKeys.contains(key.toString().toLowerCase())) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, redact(v));
      });
    }
    if (value is List) {
      return value.map(redact).toList();
    }
    return value;
  }

  static String encodeResponse(dynamic data) {
    if (data == null) return '';
    if (data is Map || data is List) {
      return jsonEncode(redact(data));
    }
    if (data is String) {
      return redactString(data);
    }
    return data.toString();
  }

  /// Safe DioException summary — never logs headers, cookies, or raw payload.
  static String formatDioException(DioException error) {
    final parts = <String>[
      'method=${error.requestOptions.method}',
      'path=${error.requestOptions.path}',
      'type=${error.type.name}',
    ];
    final status = error.response?.statusCode;
    if (status != null) {
      parts.add('statusCode=$status');
    }
    final message = error.message;
    if (message != null && message.isNotEmpty) {
      parts.add('message=${redactString(message)}');
    }
    return parts.join(' ');
  }
}
