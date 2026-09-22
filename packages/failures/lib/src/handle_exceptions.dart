import 'exceptions.dart';
import 'failures.dart';
import 'app_logger.dart';
import 'error_code.dart';
import 'result.dart';

/// Runs [action] and converts thrown exceptions into a [Failure] inside a
/// [Result]. Logs structured, sanitized diagnostics via [AppLogger].
Future<Result<T, Failure>> handleExceptions<T>(
  Future<T> Function() action, {
  String? operation,
  String? feature,
}) async {
  try {
    final value = await action();
    return Ok<T, Failure>(value);
  } on UnauthorizedException catch (e, stackTrace) {
    return _fail<T>(
      UnauthorizedFailure(e.message ?? 'Sesión inválida o expirada'),
      e,
      stackTrace,
      ErrorCode.unauthorized,
      feature: feature,
      operation: operation,
    );
  } on ForbiddenException catch (e, stackTrace) {
    return _fail<T>(
      ForbiddenFailure(e.message ?? 'Permiso insuficiente'),
      e,
      stackTrace,
      ErrorCode.forbidden,
      feature: feature,
      operation: operation,
    );
  } on ValidationException catch (e, stackTrace) {
    return _fail<T>(
      ValidationFailure(e.message),
      e,
      stackTrace,
      ErrorCode.validation,
      feature: feature,
      operation: operation,
    );
  } on ConflictException catch (e, stackTrace) {
    return _fail<T>(
      ValidationFailure(e.message),
      e,
      stackTrace,
      ErrorCode.validation,
      feature: feature,
      operation: operation,
      statusCode: e.statusCode ?? 409,
    );
  } on NotFoundException catch (e, stackTrace) {
    return _fail<T>(
      const NotFoundFailure(),
      e,
      stackTrace,
      ErrorCode.notFound,
      feature: feature,
      operation: operation,
    );
  } on TimeoutException catch (e, stackTrace) {
    return _fail<T>(
      const TimeoutFailure(),
      e,
      stackTrace,
      ErrorCode.timeout,
      feature: feature,
      operation: operation,
    );
  } on NetworkException catch (e, stackTrace) {
    return _fail<T>(
      NetworkFailure(e.message ?? 'Sin conexión con el servidor'),
      e,
      stackTrace,
      ErrorCode.network,
      feature: feature,
      operation: operation,
    );
  } on ServerException catch (e, stackTrace) {
    return _fail<T>(
      ServerFailure(e.message ?? 'Error del servidor'),
      e,
      stackTrace,
      ErrorCode.server,
      feature: feature,
      operation: operation,
      statusCode: e.statusCode ?? 500,
    );
  } on RequestException catch (e, stackTrace) {
    return _fail<T>(
      GenericFailure(e.message ?? 'Error de solicitud'),
      e,
      stackTrace,
      ErrorCode.request,
      feature: feature,
      operation: operation,
      statusCode: e.statusCode,
    );
  } on FormatException catch (e, stackTrace) {
    return _fail<T>(
      GenericFailure('Formato inválido: ${e.message}'),
      e,
      stackTrace,
      ErrorCode.format,
      feature: feature,
      operation: operation,
    );
  } catch (e, stackTrace) {
    return _fail<T>(
      const UnexpectedFailure(),
      e,
      stackTrace,
      ErrorCode.unexpected,
      feature: feature,
      operation: operation,
    );
  }
}

Err<T, Failure> _fail<T>(
  Failure failure,
  Object exception,
  StackTrace stackTrace,
  ErrorCode errorCode, {
  String? feature,
  String? operation,
  int? statusCode,
}) {
  final resolvedStatus = statusCode ?? _statusCodeFrom(exception);
  final safeData = _safeDataFrom(exception);
  final technicalMessage = AppLogger.sanitizeMessage(
    _technicalMessage(exception),
  );

  AppLogger.logError(
    ErrorLogRecord(
      errorId: AppLogger.generateErrorId(),
      errorCode: errorCode.code,
      exceptionType: exception.runtimeType.toString(),
      message: technicalMessage,
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now().toIso8601String(),
      feature: feature,
      operation: operation,
      statusCode: resolvedStatus,
      safeData: safeData,
    ),
  );

  return Err<T, Failure>(failure);
}

int? _statusCodeFrom(Object exception) {
  if (exception is UnauthorizedException) return exception.statusCode ?? 401;
  if (exception is ForbiddenException) return exception.statusCode ?? 403;
  if (exception is NotFoundException) return exception.statusCode ?? 404;
  if (exception is ServerException) return exception.statusCode ?? 500;
  if (exception is RequestException) return exception.statusCode;
  return null;
}

Map<String, dynamic>? _safeDataFrom(Object exception) {
  if (exception is UnauthorizedException) return exception.safeData;
  if (exception is ForbiddenException) return exception.safeData;
  if (exception is NotFoundException) return exception.safeData;
  if (exception is ServerException) return exception.safeData;
  if (exception is RequestException) return exception.safeData;
  if (exception is NetworkException) return exception.safeData;
  if (exception is ValidationException) return exception.safeData;
  if (exception is ConflictException) return exception.safeData;
  return null;
}

String _technicalMessage(Object exception) {
  if (exception is UnauthorizedException) {
    return exception.message ?? 'Unauthorized';
  }
  if (exception is ForbiddenException) {
    return exception.message ?? 'Forbidden';
  }
  if (exception is ValidationException) return exception.message;
  if (exception is ConflictException) return exception.message;
  if (exception is NetworkException) {
    return exception.message ?? 'Network error';
  }
  if (exception is RequestException) {
    return exception.message ?? 'Request error';
  }
  if (exception is ServerException) {
    return exception.message ?? 'Server error';
  }
  if (exception is TimeoutException) return 'Timeout';
  if (exception is NotFoundException) return 'Not found';
  return exception.runtimeType.toString();
}
