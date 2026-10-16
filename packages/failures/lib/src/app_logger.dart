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
    'initial_password',
    'new_password',
    'current_password',
    'confirm_password',
    'password_confirmation',
    'client_secret',
    'api_key',
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

  static bool isSensitiveKey(Object? key) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _secretKeys
        .any((name) => normalize(name) == normalize(key.toString()));
  }

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
        if (isSensitiveKey(key)) {
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
    try {
      final parsed = jsonDecode(value);
      if (parsed is Map || parsed is List) {
        return jsonEncode(sanitize(parsed));
      }
    } catch (_) {}
    // ApiMethod prefixes JSON with an operation label. Keep non-sensitive JSON
    // fields visible there too, while using the same recursive sanitization.
    final jsonStart = value.indexOf(RegExp(r'[\{\[]'));
    if (jsonStart > 0) {
      try {
        final parsed = jsonDecode(value.substring(jsonStart));
        if (parsed is Map || parsed is List) {
          return '${_sanitizeString(value.substring(0, jsonStart))}'
              '${jsonEncode(sanitize(parsed))}';
        }
      } catch (_) {}
    }
    final keys = _secretKeys
        .map((key) =>
            key.split(RegExp(r'[_-]')).map(RegExp.escape).join(r'[_-]?'))
        .join('|');
    // JSON keeps useful fields above. For unstructured text redact the rest of
    // the line, including escaped/unterminated quotes, to avoid partial leaks.
    final pattern = RegExp(
      "([\"']?\\b(?:$keys)[\"']?\\s*[:=]\\s*)[^\\r\\n]+",
      caseSensitive: false,
    );
    return value.replaceAllMapped(pattern, (match) => '${match[1]}***');
  }

  static String sanitizeMessage(String? message) {
    if (message == null || message.isEmpty) return '';
    return _sanitizeString(message);
  }
}
