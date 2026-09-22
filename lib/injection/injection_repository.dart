import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';

import '../../features/app/cubit/app_session_cubit.dart';
import 'injection_bloc.dart' show getIt;

/// Registers core infrastructure (HTTP / Dio / coordinator / token store),
/// feature APIs, and repositories.
///
/// Order matters:
///   * refreshDio is built BEFORE the coordinator (which uses refreshApi).
///   * The coordinator is built BEFORE mainDio (whose interceptor needs
///     the coordinator).
///   * Repositories depend on the api package.
Future<void> registerRepositories() async {
  // ─── Core HTTP ─────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthTokenStore>(() => AuthTokenStore());

  // refreshDio + its ApiMethod (no interceptors, only login / refresh /
  // logout). This breaks the recursion cycle: AuthRefreshInterceptor on
  // mainDio never causes refreshDio to call itself.
  final refreshDio = ApiClient.buildRefresh();
  getIt.registerLazySingleton<ApiMethod>(
    () => ApiClient.apiMethodFor(refreshDio),
    instanceName: 'refreshApi',
  );

  // AuthRefreshCoordinator uses AuthApi directly (which goes through
  // refreshDio). It is created BEFORE mainDio because mainDio's
  // AuthRefreshInterceptor needs it.
  getIt.registerLazySingleton<AuthRefreshCoordinator>(
    () => AuthRefreshCoordinator(
      refreshTokens: () => getIt<AuthApi>().refresh(),
      tokenStore: getIt<AuthTokenStore>(),
      onSessionEnded: () => getIt<AppSessionCubit>().onAuthCleared(),
    ),
  );

  // mainDio + its ApiMethod (has AuthInterceptor + AuthRefreshInterceptor).
  getIt.registerLazySingleton<ApiMethod>(
    () => ApiMethod(
      dio: ApiClient.buildMain(
        tokenStore: getIt<AuthTokenStore>(),
        coordinator: getIt<AuthRefreshCoordinator>(),
      ),
    ),
    instanceName: 'mainApi',
  );

  // ─── APIs ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthApi>(
    () => AuthApi(
      mainApi: getIt<ApiMethod>(instanceName: 'mainApi'),
      refreshApi: getIt<ApiMethod>(instanceName: 'refreshApi'),
    ),
  );

  getIt.registerLazySingleton<CorrespondenceApi>(
    () => CorrespondenceApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<OrganizationApi>(
    () => OrganizationApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<OrganizationalUnitsAdminApi>(
    () => OrganizationalUnitsAdminApi(
      mainApi: getIt<ApiMethod>(instanceName: 'mainApi'),
    ),
  );

  getIt.registerLazySingleton<PositionsAdminApi>(
    () => PositionsAdminApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<EmployeesAdminApi>(
    () => EmployeesAdminApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<UsersAdminApi>(
    () => UsersAdminApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<RolesAdminApi>(
    () => RolesAdminApi(mainApi: getIt<ApiMethod>(instanceName: 'mainApi')),
  );

  getIt.registerLazySingleton<DocumentTypesAdminApi>(
    () => DocumentTypesAdminApi(
      mainApi: getIt<ApiMethod>(instanceName: 'mainApi'),
    ),
  );

  // ─── Repositories ─────────────────────────────────────────────
  getIt.registerLazySingleton<AuthenticationRepository>(
    () => AuthenticationRepository(
      authApi: getIt<AuthApi>(),
      tokenStore: getIt<AuthTokenStore>(),
    ),
  );

  getIt.registerLazySingleton<CorrespondenceRepository>(
    () => CorrespondenceRepository(
      correspondenceApi: getIt<CorrespondenceApi>(),
    ),
  );

  getIt.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepository(
      organizationApi: getIt<OrganizationApi>(),
    ),
  );

  getIt.registerLazySingleton<OrganizationalUnitsAdminRepository>(
    () => OrganizationalUnitsAdminRepository(
      api: getIt<OrganizationalUnitsAdminApi>(),
    ),
  );

  getIt.registerLazySingleton<PositionsAdminRepository>(
    () => PositionsAdminRepository(api: getIt<PositionsAdminApi>()),
  );

  getIt.registerLazySingleton<EmployeesAdminRepository>(
    () => EmployeesAdminRepository(api: getIt<EmployeesAdminApi>()),
  );

  getIt.registerLazySingleton<UsersAdminRepository>(
    () => UsersAdminRepository(
      usersApi: getIt<UsersAdminApi>(),
      rolesApi: getIt<RolesAdminApi>(),
    ),
  );

  getIt.registerLazySingleton<DocumentTypesAdminRepository>(
    () => DocumentTypesAdminRepository(api: getIt<DocumentTypesAdminApi>()),
  );
}
