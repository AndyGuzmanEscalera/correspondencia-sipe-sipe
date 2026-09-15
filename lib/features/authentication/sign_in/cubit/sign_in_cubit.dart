import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit({LocalStore? store}) : _store = store ?? LocalStore.instance, super(const SignInState());

  final LocalStore _store;

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

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!_store.validateCredentials(username.trim(), password)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
            title: 'Acceso denegado',
            message: 'Usuario o contraseña incorrectos.',
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        username: username.trim(),
        dialogMessage: const DialogMessage(
          title: 'Bienvenido',
          message: 'Inicio de sesión exitoso.',
        ),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }
}
