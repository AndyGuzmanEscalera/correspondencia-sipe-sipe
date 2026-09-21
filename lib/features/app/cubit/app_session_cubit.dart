import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSessionState extends Equatable implements StatusState {
  const AppSessionState({
    this.userSession,
  });

  final UserSession? userSession;

  bool get isAuthenticated => userSession != null;

  AppSessionState copyWith({
    UserSession? userSession,
    bool clearSession = false,
  }) {
    return AppSessionState(
      userSession:
          clearSession ? null : (userSession ?? this.userSession),
    );
  }

  @override
  GeneralStatus get generalStatus => GeneralStatus.initial;

  @override
  DialogMessage get dialogMessage => const DialogMessage.empty();

  @override
  List<Object?> get props => [userSession];
}

/// Sesión global en memoria. La navegación la maneja GoRouter.
class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit({required AuthenticationRepository authRepository})
      : _authRepository = authRepository,
        super(const AppSessionState());

  final AuthenticationRepository _authRepository;

  void onSessionRestored(UserSession session) {
    emit(AppSessionState(userSession: session));
  }

  void onSignedIn(UserSession session) {
    emit(AppSessionState(userSession: session));
  }

  void onNoSession() {
    emit(const AppSessionState());
  }

  void onAuthCleared() {
    emit(const AppSessionState());
  }

  Future<bool> tryRestoreSession() async {
    final result = await _authRepository.restoreSession();
    return result.when(
      ok: (session) {
        if (session != null) {
          onSessionRestored(session);
          return true;
        }
        onNoSession();
        return false;
      },
      err: (_) {
        onNoSession();
        return false;
      },
    );
  }

  Future<void> logout() async {
    final result = await _authRepository.logout();
    result.when(ok: (_) {}, err: (_) {});
    onAuthCleared();
  }
}
