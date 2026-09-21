/// Domain exception types thrown inside data sources / repositories.
/// The handleExceptions wrapper converts these into [Failure] values.
library;

class RequestException implements Exception {
  RequestException(this.message, {this.statusCode, this.safeData});

  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? safeData;
}

class ServerException implements Exception {
  ServerException({this.message, this.statusCode, this.safeData});

  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? safeData;
}

class NotFoundException implements Exception {
  NotFoundException({this.statusCode = 404, this.safeData});

  final int? statusCode;
  final Map<String, dynamic>? safeData;
}

class UnauthorizedException implements Exception {
  UnauthorizedException(this.message, {this.statusCode = 401, this.safeData});

  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? safeData;
}

class ForbiddenException implements Exception {
  ForbiddenException(this.message, {this.statusCode = 403, this.safeData});

  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? safeData;
}

class NetworkException implements Exception {
  const NetworkException(this.message, {this.safeData});

  final String? message;
  final Map<String, dynamic>? safeData;
}

class TimeoutException implements Exception {
  TimeoutException({this.safeData});
  final Map<String, dynamic>? safeData;
}

class ValidationException implements Exception {
  ValidationException(this.message, {this.safeData});

  final String message;
  final Map<String, dynamic>? safeData;
}

class UnexpectedException implements Exception {
  UnexpectedException(this.message, {this.safeData});

  final String message;
  final Map<String, dynamic>? safeData;
}
