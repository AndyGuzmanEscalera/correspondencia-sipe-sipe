import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Structured error log entry produced by [handleExceptions].
class ErrorLogRecord {
  const ErrorLogRecord({
    required this.errorId,
    required this.errorCode,
    required this.exceptionType,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    this.feature,
    this.operation,
    this.statusCode,
    this.safeData,
  });

  final String errorId;
  final String errorCode;
  final String exceptionType;
  final String message;
  final String stackTrace;
  final String timestamp;
  final String? feature;
  final String? operation;
  final int? statusCode;
  final Map<String, dynamic>? safeData;

  Map<String, dynamic> toJson() => {
        'errorId': errorId,
        'errorCode': errorCode,
        'exceptionType': exceptionType,
        'message': message,
        'stackTrace': stackTrace,
        'timestamp': timestamp,
        if (feature != null) 'feature': feature,
        if (operation != null) 'operation': operation,
        if (statusCode != null) 'statusCode': statusCode,
        if (safeData != null && safeData!.isNotEmpty) 'safeData': safeData,
      };
}

/// Infra logging — no acoplado a Presentation. Debug-only via [dart:developer].
class AppLogger {
  AppLogger._();

  static const _secretKeys = {
    'password',
    'contrasena',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'cookie',
    'set-cookie',
    'jwt',
    'secret',
  };

  static String generateErrorId() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    return 'ERR${now.substring(now.length - 6)}';
  }

  static void logError(ErrorLogRecord record) {
    if (!kDebugMode) return;
    log(
      jsonEncode(sanitize(record.toJson())),
      name: 'AppLogger',
    );
  }

  static dynamic sanitize(dynamic value) {
    if (value is Map) {
      return value.map((key, v) {
        if (_secretKeys.contains(key.toString().toLowerCase())) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, sanitize(v));
      });
    }
    if (value is List) {
      return value.map(sanitize).toList();
    }
    if (value is String) {
      return _sanitizeString(value);
    }
    return value;
  }

  static String _sanitizeString(String value) {
    var result = value;
    for (final key in _secretKeys) {
      final pattern = RegExp(
        '$key=([^;\\s,]+)',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(pattern, (m) => '$key=***');
    }
    return result;
  }

  static String sanitizeMessage(String? message) {
    if (message == null || message.isEmpty) return '';
    return _sanitizeString(message);
  }
}
