import 'package:get_it/get_it.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';

import '../../features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import '../../features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart';
import '../../features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import '../../features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart';
import '../../features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import '../../features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import '../../features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import '../../features/administration/basic_data/units/upsert_units/cubit/upsert_units_cubit.dart';
import '../../features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import '../../features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart';
import '../../features/app/cubit/app_session_cubit.dart';
import '../../features/authentication/sign_in/cubit/sign_in_cubit.dart';
import '../../features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import '../../features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import '../../features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import '../../features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import '../../features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import '../../features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import '../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../features/home/side_menu/cubit/side_menu_cubit.dart';
import '../../features/inbox/cubit/inbox_entry_cubit.dart';
import '../../features/inbox/cubit/sent_entry_cubit.dart';
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
  getIt.registerFactory<SideMenuCubit>(
    () => SideMenuCubit(
      correspondenceRepository: getIt<CorrespondenceRepository>(),
    ),
  );

  getIt.registerFactory<InboxEntryCubit>(
    () => InboxEntryCubit(getIt<CorrespondenceRepository>()),
  );
  getIt.registerFactory<SentEntryCubit>(
    () => SentEntryCubit(getIt<CorrespondenceRepository>()),
  );
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(getIt<CorrespondenceRepository>()),
  );
  getIt.registerFactory<SplashCubit>(
    () => SplashCubit(authRepository: getIt<AuthenticationRepository>()),
  );
  getIt.registerFactory<SignInCubit>(
    () => SignInCubit(authRepository: getIt<AuthenticationRepository>()),
  );

  getIt.registerFactory<CorrespondenceCubit>(
    () => CorrespondenceCubit(getIt<CorrespondenceRepository>()),
  );

  getIt.registerFactory<UpsertCorrespondenceCubit>(
    () => UpsertCorrespondenceCubit(
      correspondenceRepository: getIt<CorrespondenceRepository>(),
      organizationRepository: getIt<OrganizationRepository>(),
    ),
  );

  getIt.registerFactoryParam<CorrespondenceDetailCubit, String, String?>(
    (correspondenceId, viewerUnitId) => CorrespondenceDetailCubit(
      repository: getIt<CorrespondenceRepository>(),
      correspondenceId: correspondenceId,
      viewerUnitId: viewerUnitId,
    ),
  );

  getIt.registerFactoryParam<DeriveCorrespondenceCubit, String, void>(
    (correspondenceId, _) => DeriveCorrespondenceCubit(
      correspondenceRepository: getIt<CorrespondenceRepository>(),
      organizationRepository: getIt<OrganizationRepository>(),
      correspondenceId: correspondenceId,
    ),
  );

  getIt.registerFactoryParam<CorrespondenceAttachmentsCubit, String, void>(
    (correspondenceId, _) => CorrespondenceAttachmentsCubit(
      repository: getIt<CorrespondenceRepository>(),
      correspondenceId: correspondenceId,
    ),
  );

  getIt.registerFactoryParam<CorrespondenceDocumentActionsCubit, String, void>(
    (correspondenceId, _) => CorrespondenceDocumentActionsCubit(
      repository: getIt<CorrespondenceRepository>(),
      correspondenceId: correspondenceId,
    ),
  );

  getIt.registerFactory<UnitsCubit>(
    () => UnitsCubit(getIt<OrganizationalUnitsAdminRepository>()),
  );

  getIt.registerFactory<UpsertUnitsCubit>(
    () => UpsertUnitsCubit(getIt<OrganizationalUnitsAdminRepository>()),
  );

  getIt.registerFactory<PositionsCubit>(
    () => PositionsCubit(getIt<PositionsAdminRepository>()),
  );

  getIt.registerFactory<UpsertPositionsCubit>(
    () => UpsertPositionsCubit(getIt<PositionsAdminRepository>()),
  );

  getIt.registerFactory<EmployeesCubit>(
    () => EmployeesCubit(getIt<EmployeesAdminRepository>()),
  );

  getIt.registerFactory<UpsertEmployeesCubit>(
    () => UpsertEmployeesCubit(
      employeesRepository: getIt<EmployeesAdminRepository>(),
      unitsRepository: getIt<OrganizationalUnitsAdminRepository>(),
      positionsRepository: getIt<PositionsAdminRepository>(),
    ),
  );

  getIt.registerFactory<UsersCubit>(
    () => UsersCubit(getIt<UsersAdminRepository>()),
  );

  getIt.registerFactory<UpsertUsersCubit>(
    () => UpsertUsersCubit(
      usersRepository: getIt<UsersAdminRepository>(),
      employeesRepository: getIt<EmployeesAdminRepository>(),
    ),
  );

  getIt.registerFactory<DocumentTypesCubit>(
    () => DocumentTypesCubit(getIt<DocumentTypesAdminRepository>()),
  );

  getIt.registerFactory<UpsertDocumentTypesCubit>(
    () => UpsertDocumentTypesCubit(getIt<DocumentTypesAdminRepository>()),
  );
}
