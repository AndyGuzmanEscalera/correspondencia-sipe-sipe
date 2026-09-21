part of 'sign_in_cubit.dart';

class SignInState extends Equatable implements StatusState {
  const SignInState({
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
    this.userSession,
  });

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  final UserSession? userSession;

  SignInState copyWith({
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
    UserSession? userSession,
    bool clearUserSession = false,
  }) {
    return SignInState(
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      userSession:
          clearUserSession ? null : (userSession ?? this.userSession),
    );
  }

  @override
  List<Object?> get props => [generalStatus, dialogMessage, userSession];
}
