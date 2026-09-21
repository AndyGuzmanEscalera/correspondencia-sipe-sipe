import 'package:get_it/get_it.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';

import '../../features/app/cubit/app_session_cubit.dart';
import '../../features/authentication/sign_in/cubit/sign_in_cubit.dart';
import '../../features/home/side_menu/cubit/side_menu_cubit.dart';
import '../../features/splash/cubit/splash_cubit.dart';

/// Global GetIt instance.
final getIt = GetIt.instance;

/// Registers application cubits in GetIt.
///
/// Global cubits (e.g. [AppSessionCubit]) are `lazySingleton` so any
/// consumer (interceptor, splash, logout flow) reaches the SAME instance.
///
/// Feature cubits ([SplashCubit], [SignInCubit]) are `factory` and created
/// per-page via `BlocProvider(create: (_) => sl<...>())`.
void registerCubits() {
  // Global session cubit. The widget tree consumes the same instance via
  // BlocProvider.value.
  getIt.registerLazySingleton<AppSessionCubit>(
    () => AppSessionCubit(authRepository: getIt<AuthenticationRepository>()),
  );

  // Per-page cubits.
  getIt.registerFactory<SideMenuCubit>(() => SideMenuCubit());
  getIt.registerFactory<SplashCubit>(
    () => SplashCubit(authRepository: getIt<AuthenticationRepository>()),
  );
  getIt.registerFactory<SignInCubit>(
    () => SignInCubit(authRepository: getIt<AuthenticationRepository>()),
  );
}
