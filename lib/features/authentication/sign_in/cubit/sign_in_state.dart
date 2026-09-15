part of 'sign_in_cubit.dart';

class SignInState extends Equatable implements StatusState {
  const SignInState({
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
    this.username = '',
  });

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  final String username;

  SignInState copyWith({
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
    String? username,
  }) {
    return SignInState(
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      username: username ?? this.username,
    );
  }

  @override
  List<Object?> get props => [generalStatus, dialogMessage, username];
}
