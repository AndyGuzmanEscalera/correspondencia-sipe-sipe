# Separación de Autorización/Correspondencia y WIP RR.HH.

Fecha: 2026-10-27. Repositorio C:\dev\correspondencia_sipe_sipe. Rama develop.
HEAD antes/después: 59c19192e1b27520c4d7269a42793ad834848801. Índice vacío.
Sin commit, push, deploy ni migración de la base habitual.

## Resultado y alcance del cambio

La última revisión Alembic committeada en HEAD es g2b3c4d5e6f7.
Se confirmó leyendo el árbol de migraciones del commit, además de git log --oneline -10.

Antes, el working tree tenía una sola head k1 pero la ruta incluía h1:

```text
g2b3c4d5e6f7 -> h1b2c3d4e5f6 -> i1b2c3d4e5f6 -> j1b2c3d4e5f6 -> k1b2c3d4e5f6
```

Se cambió únicamente una línea funcional: down_revision de i1.
J1, k1 y h1 conservan exactamente sus bytes originales.

| Revisión | down_revision final | depends_on |
|---|---|---|
| i1b2c3d4e5f6 | g2b3c4d5e6f7 | None |
| j1b2c3d4e5f6 | i1b2c3d4e5f6 | None |
| k1b2c3d4e5f6 | j1b2c3d4e5f6 | None |

La cadena lista para versionar queda:

```text
g2b3c4d5e6f7
  |
i1b2c3d4e5f6
  |
j1b2c3d4e5f6
  |
k1b2c3d4e5f6  (unica head del conjunto versionable)
```

Se actualizó documentación para reflejar la cadena, corregir el catálogo versionable y
distinguir las pruebas históricas con WIP de esta nueva validación independiente.
Los informes anteriores conservan su evidencia original; esta revalidación la complementa.

## Distinción necesaria: árbol local frente al conjunto versionable

H1 permanece físicamente intacto, fuera del commit. Como también cuelga de g2,
el árbol local completo presenta dos heads: h1 y k1. Esto es esperado:

```text
                 +--> h1b2c3d4e5f6       WIP no incluido
g2b3c4d5e6f7 ----+
                 +--> i1 --> j1 --> k1   conjunto versionable
```

No se forzó una única head local modificando h1, añadiendo dependencias artificiales o borrando el WIP.
La copia de prueba que contiene exactamente el conjunto versionable tiene una sola head: k1.
No debe usarse alembic upgrade head sobre el árbol mezclado como si fuera el release limpio.
No se ejecutó stamp, downgrade, reconciliación ni upgrade en la base habitual.

## Independencia real de RR.HH.

No se encontró dependencia de las Fases 1–3 sobre tablas/modelos/código RR.HH.

Los únicos cuatro archivos de integración modificados por ese WIP son:
backend/Dockerfile, backend/alembic/env.py, backend/app/main.py y backend/requirements.txt.
No contienen cambios funcionales de las Fases 1–3 y se excluyen íntegramente del manifiesto de commit.
La versión ya committeada de esos archivos es suficiente para iniciar la aplicación y registrar
los modelos/routers nuevos mediante sus paquetes administrativos existentes.

Para probarlo se construyó una copia temporal desde git archive HEAD y se superpusieron solamente
los archivos del manifiesto, excluyendo los 30 archivos del WIP.
La copia usa los cuatro archivos de integración de HEAD, no los modificados del working tree.
No contiene h1, app/modules/rrhh, tests_rrhh, tests_startup ni requirements-biometric.txt.
No se borró ni movió ninguno de esos archivos reales.

La igualdad de los cuatro archivos con HEAD se comprobó normalizando solo LF/CRLF:
git archive aplica finales CRLF en este entorno. No hay diferencias de contenido.
Los restantes archivos base trackeados no cambiaron después de las herramientas Flutter.

La comprobación de arranque mostró:
- zk_present = False;
- rrhh_imports = [];
- rrhh_routes = [].

Se desinstalaron pyzk y future exclusivamente del contenedor temporal de pruebas.
python-dotenv sigue siendo una dependencia común de uvicorn[standard], sin relación de dependencia
hacia el módulo RR.HH. de la aplicación.
El literal rrhh.read de un test de clasificación genérica de permisos no importa RR.HH.,
no exige registrar ese permiso y pasa también en la instalación limpia.

El catálogo limpio tiene 26 Permission. Los dos rrhh.* pertenecen a h1 y no aparecen.
La base no contiene tablas biometric_*, attendance_* ni work_shifts/work_shift_segments.

## Validación en base temporal vacía

Contenedores exclusivos de QA, sin puertos publicados:
sipe_auth_separation_db_20261027 y sipe_auth_separation_tests_20261027.
El backend se montó en solo lectura desde la copia limpia.
DATABASE_URL apunta al PostgreSQL temporal, nunca a la base habitual.

Base auth_release:
alembic upgrade head recorrió la cadena committeada hasta g2 y luego i1 -> j1 -> k1.
Alembic heads/history confirman una sola head k1 y ausencia de h1.
No se reutilizaron bases antiguas que hubieran pasado por h1.

## Upgrade g2 con datos históricos sintéticos

Base independiente auth_legacy_g2:
1. Upgrade solo hasta g2b3c4d5e6f7.
2. Insertar tres usuarios ADMIN/MANAGER/OPERATOR con contexto institucional y distintos flags de unidad.
3. Insertar seis documentos EDIE, NOTA, INFORME, MEMORANDUM, CIRCULAR y CARTA.
4. Insertar seis movimientos y seis adjuntos, con snapshots de autoridad previos.
5. Upgrade mediante g2 -> i1 -> j1 -> k1.
6. Comparar todas las columnas anteriores, IDs y referencias.

Resultado exacto:
- 6/6 documentos idénticos en sus columnas originales;
- 6/6 movimientos idénticos;
- 6/6 adjuntos idénticos;
- 3/3 usuarios idénticos;
- Employee/Position anteriores conservados;
- roles de usuarios sin cambios;
- 6/6 IDs documentales históricos conservados;
- institutional_authority_snapshot conservado y document_snapshot nuevo null para históricos;
- grants de transición correctos, sin read.all automático para roles legacy;
- sin tablas ni permisos RR.HH.;
- alembic_version = k1b2c3d4e5f6.

## Suites completas, ejecutadas sobre la copia SIN h1

| Validación | Resultado exacto |
|---|---|
| python -m pytest tests/ -q --tb=short -p no:cacheprovider | 561 passed, 0 failed; 2 DeprecationWarning de librerías |
| flutter test --no-pub --reporter expanded | 576 passed, 0 failed |
| correspondencia_api | 50 passed |
| correspondencia_repository | 39 passed |
| failures | 6 passed |
| flutter analyze --no-pub | 0 errors / 0 warnings / 98 infos previos |
| alembic heads, copia limpia | k1b2c3d4e5f6, una sola head |
| git diff --check, working tree real | OK |
| SHA-256 WIP antes/después | 30/30 idénticos |

El analizador mantiene su exit 1 por los 98 infos preexistentes.
No se suprimieron errores, no se excluyeron tests de las suites solicitadas y no se redujeron conteos.

Copia verificada:
C:\Users\ANDY\AppData\Local\Temp\sipe-auth-separation-20261027\release

Los logs de cada suite y del upgrade legacy están en la carpeta temporal superior.
Las dependencias Flutter se resolvieron con pub get --offline solo en esa copia.
Se verificó que las herramientas no alteraran archivos base trackeados ajenos al manifiesto.

## Hashes antes/después del WIP

AUTHORIZATION_RRHH_WIP_SHA256.json contiene, por archivo, path, sha256_before,
sha256_after y unchanged. Los 30 pares coinciden, incluido el contenido funcional de h1.
La lista siguiente contiene los archivos exactos que deben quedar fuera del commit:

```text
backend/.env.biometric.example
backend/Dockerfile
backend/README_BIOMETRIC.md
backend/VERIFICACION_BIOMETRIC.md
backend/alembic/env.py
backend/alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py
backend/app/main.py
backend/app/modules/rrhh/__init__.py
backend/app/modules/rrhh/biometric_service.py
backend/app/modules/rrhh/errors.py
backend/app/modules/rrhh/models.py
backend/app/modules/rrhh/periods.py
backend/app/modules/rrhh/reader/__init__.py
backend/app/modules/rrhh/reader/config.py
backend/app/modules/rrhh/reader/connection.py
backend/app/modules/rrhh/reader/monitor.py
backend/app/modules/rrhh/reader/records.py
backend/app/modules/rrhh/reader/storage.py
backend/app/modules/rrhh/router.py
backend/app/modules/rrhh/schemas.py
backend/app/modules/rrhh/storage.py
backend/app/modules/rrhh/worker.py
backend/requirements-biometric.txt
backend/requirements.txt
backend/tests_rrhh/__init__.py
backend/tests_rrhh/conftest.py
backend/tests_rrhh/test_integration.py
backend/tests_rrhh/test_migration.py
backend/tests_rrhh/test_reader.py
backend/tests_startup/test_optional_biometric_dependency.py
```

## Manifiesto exacto de archivos elegibles para commit Fases 1–3

AUTHORIZATION_PHASES_COMMIT_FILES.txt contiene exactamente 142 rutas relativas.
Su intersección con la lista WIP es vacía. El manifiesto incluye los archivos de evidencia de esta separación.
Los cuatro archivos de integración del WIP deben quedar sin stagear; el commit conservará sus versiones de HEAD.

No se stageó ningún archivo. No se creó commit. No se cambió de rama.

```text
backend/alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py
backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py
backend/alembic/versions/k1b2c3d4e5f6_correspondence_operation_scopes.py
backend/app/modules/auth/dependencies.py
backend/app/modules/auth/institutional_context.py
backend/app/modules/auth/router.py
backend/app/modules/auth/schemas.py
backend/app/modules/correspondence/attachment_service.py
backend/app/modules/correspondence/authorization.py
backend/app/modules/correspondence/correspondence.py
backend/app/modules/correspondence/creation_policy.py
backend/app/modules/correspondence/document_creation_authorization.py
backend/app/modules/correspondence/document_snapshot.py
backend/app/modules/correspondence/document_type.py
backend/app/modules/correspondence/document_type_admin_service.py
backend/app/modules/correspondence/document_type_profiles.py
backend/app/modules/correspondence/insights.py
backend/app/modules/correspondence/pdf/operational_document_pdf.py
backend/app/modules/correspondence/router.py
backend/app/modules/correspondence/schemas.py
backend/app/modules/correspondence/service.py
backend/app/modules/correspondence/visibility.py
backend/app/modules/identity/__init__.py
backend/app/modules/identity/admin_router.py
backend/app/modules/identity/admin_schemas.py
backend/app/modules/identity/administrative_continuity.py
backend/app/modules/identity/permission_admin.py
backend/app/modules/identity/rbac_service.py
backend/app/modules/identity/role_transition.py
backend/app/modules/identity/user_admin_service.py
backend/app/modules/identity/user_permission.py
backend/app/modules/notifications/service.py
backend/app/modules/organization/__init__.py
backend/app/modules/organization/admin_router.py
backend/app/modules/organization/admin_schemas.py
backend/app/modules/organization/hierarchy_admin.py
backend/app/modules/organization/position.py
backend/app/modules/organization/position_admin_service.py
backend/app/modules/organization/position_hierarchy.py
backend/scripts/migrate_authorization_roles.py
backend/tests/c4/test_role_assignment.py
backend/tests/conftest.py
backend/tests/historical_documents.py
backend/tests/test_chaining_catalog_code.py
backend/tests/test_configured_authority.py
backend/tests/test_correspondence.py
backend/tests/test_correspondence_derive_authorization.py
backend/tests/test_correspondence_inbox.py
backend/tests/test_correspondence_lifecycle.py
backend/tests/test_correspondence_sent.py
backend/tests/test_correspondence_tracking_visibility.py
backend/tests/test_correspondence_visibility.py
backend/tests/test_correspondence_workflow.py
backend/tests/test_creation_profile_routing.py
backend/tests/test_edie_first_recipients.py
backend/tests/test_edie_unit_only_derivation.py
backend/tests/test_encadenamiento_pdf.py
backend/tests/test_final_blocks.py
backend/tests/test_institutional_mayor.py
backend/tests/test_logical_deactivation.py
backend/tests/test_master_data_logical_delete_guards.py
backend/tests/test_phase1_authorization.py
backend/tests/test_phase2_operational_documents.py
backend/tests/test_phase3_authorization.py
backend/tests/test_qa_smoke.py
backend/tests/visibility_helpers.py
docs/AUTHORIZATION_PERMISSION_CATALOG.md
docs/AUTHORIZATION_PHASES_COMMIT_FILES.txt
docs/AUTHORIZATION_RRHH_SEPARATION.md
docs/AUTHORIZATION_RRHH_WIP_SHA256.json
docs/FINAL_AUTHORIZATION_ARCHITECTURE.md
docs/PHASE1_AUTHORIZATION.md
docs/PHASE2_DOCUMENTS.md
docs/PHASE3_QA_REPORT.md
lib/core/auth/permissions.dart
lib/features/administration/basic_data/document_types/list_document_types/tables/document_types_table.dart
lib/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart
lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart
lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_state.dart
lib/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart
lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart
lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart
lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_state.dart
lib/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart
lib/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart
lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart
lib/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart
lib/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart
lib/features/correspondence/detail/views/correspondence_detail_body.dart
lib/features/correspondence/detail/widgets/correspondence_detail_header.dart
lib/features/correspondence/detail/widgets/correspondence_lifecycle_section.dart
lib/features/correspondence/domain/document_type_profiles.dart
lib/features/correspondence/domain/entities/correspondence_entity.dart
lib/features/correspondence/domain/mappers/correspondence_entity_mapper.dart
lib/features/correspondence/list_correspondence/views/correspondence_body.dart
lib/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart
lib/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart
lib/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart
lib/features/correspondence/upsert_correspondence/widgets/origin_section.dart
lib/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart
lib/features/dashboard/views/dashboard_page.dart
lib/shared/widgets/form/app_text_field.dart
packages/correspondencia_api/lib/src/features/authentication/models/me_employee_response.dart
packages/correspondencia_api/lib/src/features/correspondence/api/correspondence_api.dart
packages/correspondencia_api/lib/src/features/correspondence/models/correspondence_response.dart
packages/correspondencia_api/lib/src/features/correspondence/models/document_type_admin_response.dart
packages/correspondencia_api/lib/src/features/correspondence/models/document_type_response.dart
packages/correspondencia_api/lib/src/features/identity/api/users_admin_api.dart
packages/correspondencia_api/lib/src/features/identity/models/user_admin_response.dart
packages/correspondencia_api/lib/src/features/organization/api/positions_admin_api.dart
packages/correspondencia_api/lib/src/features/organization/models/position_admin_response.dart
packages/correspondencia_api/test/phase1_contract_test.dart
packages/correspondencia_api/test/phase2_contract_test.dart
packages/correspondencia_api/test/phase3_capabilities_test.dart
packages/correspondencia_repository/lib/src/features/authentication/entities/institutional_context.dart
packages/correspondencia_repository/lib/src/features/authentication/mappers/user_response_mapper.dart
packages/correspondencia_repository/lib/src/features/correspondence/entities/correspondence.dart
packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type.dart
packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type_admin.dart
packages/correspondencia_repository/lib/src/features/correspondence/mappers/correspondence_mapper.dart
packages/correspondencia_repository/lib/src/features/correspondence/mappers/document_type_admin_mapper.dart
packages/correspondencia_repository/lib/src/features/correspondence/repository/correspondence_repository.dart
packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart
packages/correspondencia_repository/lib/src/features/identity/mappers/identity_admin_mapper.dart
packages/correspondencia_repository/lib/src/features/identity/repository/users_admin_repository.dart
packages/correspondencia_repository/lib/src/features/organization/entities/position_admin.dart
packages/correspondencia_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart
packages/correspondencia_repository/lib/src/features/organization/repository/positions_admin_repository.dart
packages/correspondencia_repository/test/phase1_mapper_test.dart
packages/correspondencia_repository/test/phase2_mapper_test.dart
packages/correspondencia_repository/test/phase3_capabilities_test.dart
test/correspondence_creation_permission_test.dart
test/features/administration/basic_data/positions/upsert_positions_view_test.dart
test/features/administration/basic_data/users/upsert_users_view_test.dart
test/features/administration/position_correspondence_scope_test.dart
test/features/administration/user_permissions_section_test.dart
test/features/correspondence/correspondence_document_actions_cubit_test.dart
test/features/correspondence/detail/correspondence_detail_body_test.dart
test/features/correspondence/detail/correspondence_detail_header_test.dart
test/features/correspondence/detail/detail_test_fixtures.dart
test/features/correspondence/phase2_creation_test.dart
test/features/dashboard/dashboard_final_test.dart
```

## Precaución para cualquier paso posterior

Esta entrega identifica el conjunto seguro para revisión y commit; no autoriza push, deploy
ni migración de la base habitual. Las bases antiguas que ya tengan h1 necesitan una revisión
separada de reconciliación antes de aplicar esta cadena independiente.
No se modificó su alembic_version ni se intentó ocultar la rama WIP con stamp.
