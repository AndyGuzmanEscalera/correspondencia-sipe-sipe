part of 'splash_cubit.dart';

class SplashState extends Equatable implements StatusState {
  const SplashState({
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
    this.hasSession = false,
    this.session,
  });

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  /// `true` si el refresh cookie devolvió una sesión válida.
  final bool hasSession;

  final UserSession? session;

  SplashState copyWith({
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
    bool? hasSession,
    UserSession? session,
    bool clearSession = false,
  }) {
    return SplashState(
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      hasSession: hasSession ?? this.hasSession,
      session: clearSession ? null : (session ?? this.session),
    );
  }

  @override
  List<Object?> get props => [generalStatus, dialogMessage, hasSession, session];
}
