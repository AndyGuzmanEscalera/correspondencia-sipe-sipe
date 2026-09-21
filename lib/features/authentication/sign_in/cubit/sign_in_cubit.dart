import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit({required AuthenticationRepository authRepository})
      : _authRepository = authRepository,
        super(const SignInState());

  final AuthenticationRepository _authRepository;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Validando credenciales...'),
      ),
    );

    final result = await _authRepository.signIn(
      username: username.trim(),
      password: password,
    );

    result.when(
      ok: (user) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            userSession: user,
            dialogMessage: const DialogMessage(
              title: 'Bienvenido',
              message: 'Inicio de sesión exitoso.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Acceso denegado',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo iniciar sesión.',
              ),
            ),
          ),
        );
      },
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }
}
