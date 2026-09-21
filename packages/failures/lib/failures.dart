/// failures package: Failure base type, Result<T, F>, handleExceptions,
/// FailureGeneric mapper.
///
/// Adapted from Capturador's failures package but simplified: no encrypted
/// payloads, no Firebase logs, no SessionEntity, no oxidized/dartz.
/// Uses a sealed-class Result instead.
library failures;

export 'src/app_logger.dart';
export 'src/error_code.dart';
export 'src/exceptions.dart';
export 'src/failure_generic.dart';
export 'src/failures.dart';
export 'src/handle_exceptions.dart';
export 'src/result.dart';
