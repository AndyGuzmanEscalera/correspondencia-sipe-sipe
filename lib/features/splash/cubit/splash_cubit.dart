import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_state.dart';

/// SplashCubit — valida sesión vía [Result] del repository (como Capturador).
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({required AuthenticationRepository authRepository})
      : _authRepository = authRepository,
        super(const SplashState());

  final AuthenticationRepository _authRepository;

  static const _silentDialog = DialogMessage(
    message: '',
    showSuccess: false,
    showError: false,
    showLoading: false,
  );

  /// Valida sesión. Retorna `true` si [Result] trae [UserSession].
  Future<bool> restoreSession() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          title: 'Verificando sesión',
          message: 'Por favor espere...',
          showSuccess: false,
        ),
      ),
    );

    final result = await _authRepository.restoreSession();

    return result.when(
      ok: (session) {
        final hasSession = session != null;
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            hasSession: hasSession,
            session: session,
            clearSession: !hasSession,
            dialogMessage: _silentDialog,
          ),
        );
        return hasSession;
      },
      err: (failure) {
        if (_isInfrastructureFailure(failure)) {
          emit(
            state.copyWith(
              generalStatus: GeneralStatus.error,
              dialogMessage: DialogMessage(
                title: _friendlyTitle(failure),
                message: _friendlyMessage(failure),
                showSuccess: false,
                showError: false,
                showLoading: false,
              ),
            ),
          );
          return false;
        }

        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            hasSession: false,
            clearSession: true,
            dialogMessage: _silentDialog,
          ),
        );
        return false;
      },
    );
  }

  bool _isInfrastructureFailure(Failure failure) =>
      failure is NetworkFailure ||
      failure is TimeoutFailure ||
      failure is ServerFailure;

  String _friendlyTitle(Failure failure) {
    if (failure is TimeoutFailure) return 'Tiempo de espera agotado';
    if (failure is ServerFailure) return 'Servicio no disponible';
    return 'No pudimos conectar';
  }

  String _friendlyMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No fue posible comunicarnos con el servidor. '
          'Verifica tu conexión e inténtalo nuevamente.';
    }
    if (failure is TimeoutFailure) {
      return 'El servidor está tardando demasiado en responder. '
          'Inténtalo nuevamente.';
    }
    if (failure is ServerFailure) {
      return 'Ocurrió un problema al comunicarnos con el servidor. '
          'Inténtalo nuevamente.';
    }
    return failure.message;
  }
}
