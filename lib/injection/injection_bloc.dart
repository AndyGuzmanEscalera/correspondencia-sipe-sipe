import 'package:get_it/get_it.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';

import '../../features/administration/basic_data/document_types/list/cubit/document_types_list_cubit.dart';
import '../../features/administration/basic_data/employees/list/cubit/employees_list_cubit.dart';
import '../../features/administration/basic_data/positions/list/cubit/positions_list_cubit.dart';
import '../../features/administration/basic_data/units/list/cubit/units_list_cubit.dart';
import '../../features/administration/basic_data/users/list/cubit/users_list_cubit.dart';
import '../../features/app/cubit/app_session_cubit.dart';
import '../../features/authentication/sign_in/cubit/sign_in_cubit.dart';
import '../../features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import '../../features/correspondence/list/cubit/correspondence_list_cubit.dart';
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

  getIt.registerFactory<CorrespondenceListCubit>(
    () => CorrespondenceListCubit(
      repository: getIt<CorrespondenceRepository>(),
      organizationRepository: getIt<OrganizationRepository>(),
    ),
  );

  getIt.registerFactoryParam<CorrespondenceDetailCubit, String, void>(
    (correspondenceId, _) => CorrespondenceDetailCubit(
      repository: getIt<CorrespondenceRepository>(),
      organizationRepository: getIt<OrganizationRepository>(),
      correspondenceId: correspondenceId,
    ),
  );

  getIt.registerFactory<UnitsListCubit>(
    () => UnitsListCubit(
      repository: getIt<OrganizationalUnitsAdminRepository>(),
    ),
  );

  getIt.registerFactory<PositionsListCubit>(
    () => PositionsListCubit(repository: getIt<PositionsAdminRepository>()),
  );

  getIt.registerFactory<EmployeesListCubit>(
    () => EmployeesListCubit(
      employeesRepository: getIt<EmployeesAdminRepository>(),
      unitsRepository: getIt<OrganizationalUnitsAdminRepository>(),
      positionsRepository: getIt<PositionsAdminRepository>(),
    ),
  );

  getIt.registerFactory<UsersListCubit>(
    () => UsersListCubit(
      usersRepository: getIt<UsersAdminRepository>(),
      employeesRepository: getIt<EmployeesAdminRepository>(),
    ),
  );

  getIt.registerFactory<DocumentTypesListCubit>(
    () => DocumentTypesListCubit(
      repository: getIt<DocumentTypesAdminRepository>(),
    ),
  );
}
