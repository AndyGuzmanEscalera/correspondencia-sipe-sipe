import 'failures.dart';

/// FailureGeneric: maps a [Failure] into a user-facing message.
///
/// Inspired by Capturador's FailureGeneric.message() but simplified.
///
/// Usage in Cubits:
/// ```dart
/// result.when(
///   ok: (user) => appSession.onSignedIn(user),
///   err: (failure) => emit(state.copyWith(
///     dialogMessage: DialogMessage(
///       message: FailureGeneric.message(
///         failure: failure,
///         messageResult: 'No se pudo iniciar sesión',
///       ),
///     ),
///   )),
/// );
/// ```
class FailureGeneric {
  const FailureGeneric._();

  static String message({
    required Failure failure,
    String messageResult = 'Error desconocido',
  }) {
    if (failure is NetworkFailure) {
      return failure.message;
    }
    if (failure is UnauthorizedFailure ||
        failure is ForbiddenFailure ||
        failure is ValidationFailure ||
        failure is NotFoundFailure ||
        failure is ServerFailure) {
      return failure.message;
    }
    return messageResult;
  }
}
