import 'package:equatable/equatable.dart';

/// Base Failure type.
///
/// Concrete failures live in the packages that produce them
/// (e.g. correspondencia_repository defines AuthFailure variants).
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType($message)';
}

/// Generic catch-all when no specific failure applies.
class GenericFailure extends Failure {
  const GenericFailure(super.message);
}

/// Network-level failure (no connectivity, DNS, etc.).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión con el servidor']);
}

/// Request timeout (connection/send/receive).
class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'La conexión tardó demasiado. Intente nuevamente.',
  ]);
}

/// Unauthorized / token rejected.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesión inválida o expirada']);
}

/// Forbidden / permission denied.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Permiso insuficiente']);
}

/// Server-side validation failure (HTTP 4xx with structured message).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Not found (HTTP 404).
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado']);
}

/// Server error (HTTP 5xx).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

/// Generic unexpected error.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Error inesperado']);
}
