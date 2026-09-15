import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppScreen {
  publicConsult,
  signIn,
  admin,
}

class AppSessionState extends Equatable {
  const AppSessionState({
    this.screen = AppScreen.publicConsult,
    this.userName = '',
    this.employeeName = 'Lic. JAIME MONTERO LOPEZ',
  });

  final AppScreen screen;
  final String userName;
  final String employeeName;

  AppSessionState copyWith({
    AppScreen? screen,
    String? userName,
    String? employeeName,
  }) {
    return AppSessionState(
      screen: screen ?? this.screen,
      userName: userName ?? this.userName,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  @override
  List<Object?> get props => [screen, userName, employeeName];
}

class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit() : super(const AppSessionState());

  void showPublicConsult() => emit(state.copyWith(screen: AppScreen.publicConsult));

  void showSignIn() => emit(state.copyWith(screen: AppScreen.signIn));

  void onSignedIn({required String userName}) {
    emit(
      state.copyWith(
        screen: AppScreen.admin,
        userName: userName,
      ),
    );
  }

  void signOut() {
    emit(
      const AppSessionState(
        screen: AppScreen.publicConsult,
      ),
    );
  }
}
