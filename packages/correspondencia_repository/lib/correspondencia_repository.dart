/// Repository layer for the Correspondencia app.
///
/// Currently contains the authentication feature only. Future features
/// (employees, units, correspondence, etc.) will follow the same pattern
/// under their own sub-package directory.
library correspondencia_repository;

export 'src/core/entities/admin_page.dart';
export 'src/features/authentication/authentication.dart';
export 'src/features/correspondence/correspondence.dart';
export 'src/features/identity/identity.dart';
export 'src/features/organization/organization.dart';
export 'src/features/system/system.dart';

export 'src/features/dashboard/entities.dart';
export 'src/features/dashboard/repository.dart';

export 'src/features/notifications/entities.dart';
export 'src/features/notifications/repository.dart';

export 'src/features/reports/entities.dart';
export 'src/features/reports/repository.dart';
