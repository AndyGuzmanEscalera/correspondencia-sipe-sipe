# Cierre Fase 3 — evidencia QA

Nota 2026-10-27: este informe conserva la evidencia histórica de la validación inicial con el WIP presente. La cadena independiente, el catálogo limpio de 26 permisos y la revalidación sin h1 están documentados en AUTHORIZATION_RRHH_SEPARATION.md.

Fecha: 2026-10-26. Repositorio C:\dev\correspondencia_sipe_sipe, rama develop.
No se ejecutaron commit, push ni deploy, ni se migró la base habitual.

## 1. HEAD inicial/final

Ambos: 59c19192e1b27520c4d7269a42793ad834848801. Índice vacío.

## 2. Git status inicial

El árbol ya contenía Fases 1/2 y WIP de RR.HH./biométrico.
Se capturaron hashes de 148 archivos modificados/no versionados antes de comenzar.
Los 30 archivos protegidos de WIP original y h1/i1/j1 se comprobaron idénticos por SHA-256 (32/32).
Tampoco se modificaron migraciones históricas versionadas.

```text
 M backend/Dockerfile
 M backend/alembic/env.py
 M backend/app/main.py
 M backend/app/modules/auth/dependencies.py
 M backend/app/modules/auth/institutional_context.py
 M backend/app/modules/auth/router.py
 M backend/app/modules/auth/schemas.py
 M backend/app/modules/correspondence/correspondence.py
 M backend/app/modules/correspondence/creation_policy.py
 M backend/app/modules/correspondence/document_type.py
 M backend/app/modules/correspondence/document_type_admin_service.py
 M backend/app/modules/correspondence/document_type_profiles.py
 M backend/app/modules/correspondence/router.py
 M backend/app/modules/correspondence/schemas.py
 M backend/app/modules/correspondence/service.py
 M backend/app/modules/identity/__init__.py
 M backend/app/modules/identity/admin_router.py
 M backend/app/modules/identity/admin_schemas.py
 M backend/app/modules/identity/administrative_continuity.py
 M backend/app/modules/identity/rbac_service.py
 M backend/app/modules/identity/user_admin_service.py
 M backend/app/modules/organization/__init__.py
 M backend/app/modules/organization/admin_router.py
 M backend/app/modules/organization/admin_schemas.py
 M backend/app/modules/organization/position.py
 M backend/app/modules/organization/position_admin_service.py
 M backend/requirements.txt
 M backend/tests/c4/test_role_assignment.py
 M backend/tests/conftest.py
 M backend/tests/test_chaining_catalog_code.py
 M backend/tests/test_configured_authority.py
 M backend/tests/test_correspondence.py
 M backend/tests/test_correspondence_derive_authorization.py
 M backend/tests/test_correspondence_inbox.py
 M backend/tests/test_correspondence_lifecycle.py
 M backend/tests/test_correspondence_sent.py
 M backend/tests/test_correspondence_tracking_visibility.py
 M backend/tests/test_correspondence_workflow.py
 M backend/tests/test_creation_profile_routing.py
 M backend/tests/test_edie_first_recipients.py
 M backend/tests/test_edie_unit_only_derivation.py
 M backend/tests/test_encadenamiento_pdf.py
 M backend/tests/test_institutional_mayor.py
 M backend/tests/test_logical_deactivation.py
 M backend/tests/test_master_data_logical_delete_guards.py
 M backend/tests/test_qa_smoke.py
 M backend/tests/visibility_helpers.py
 M lib/core/auth/permissions.dart
 M lib/features/administration/basic_data/document_types/list_document_types/tables/document_types_table.dart
 M lib/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_state.dart
 M lib/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart
 M lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_state.dart
 M lib/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart
 M lib/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart
 M lib/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart
 M lib/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart
 M lib/features/correspondence/detail/widgets/correspondence_detail_header.dart
 M lib/features/correspondence/domain/document_type_profiles.dart
 M lib/features/correspondence/domain/entities/correspondence_entity.dart
 M lib/features/correspondence/domain/mappers/correspondence_entity_mapper.dart
 M lib/features/correspondence/list_correspondence/views/correspondence_body.dart
 M lib/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart
 M lib/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart
 M lib/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart
 M lib/features/correspondence/upsert_correspondence/widgets/origin_section.dart
 M lib/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart
 M lib/features/dashboard/views/dashboard_page.dart
 M lib/shared/widgets/form/app_text_field.dart
 M packages/correspondencia_api/lib/src/features/authentication/models/me_employee_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/api/correspondence_api.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/correspondence_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_admin_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_response.dart
 M packages/correspondencia_api/lib/src/features/identity/api/users_admin_api.dart
 M packages/correspondencia_api/lib/src/features/identity/models/user_admin_response.dart
 M packages/correspondencia_api/lib/src/features/organization/api/positions_admin_api.dart
 M packages/correspondencia_api/lib/src/features/organization/models/position_admin_response.dart
 M packages/correspondencia_repository/lib/src/features/authentication/entities/institutional_context.dart
 M packages/correspondencia_repository/lib/src/features/authentication/mappers/user_response_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/correspondence.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type_admin.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/correspondence_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/document_type_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/repository/correspondence_repository.dart
 M packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart
 M packages/correspondencia_repository/lib/src/features/identity/mappers/identity_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/identity/repository/users_admin_repository.dart
 M packages/correspondencia_repository/lib/src/features/organization/entities/position_admin.dart
 M packages/correspondencia_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/organization/repository/positions_admin_repository.dart
 M test/correspondence_creation_permission_test.dart
 M test/features/administration/basic_data/positions/upsert_positions_view_test.dart
 M test/features/administration/basic_data/users/upsert_users_view_test.dart
 M test/features/correspondence/correspondence_document_actions_cubit_test.dart
 M test/features/correspondence/detail/correspondence_detail_header_test.dart
 M test/features/dashboard/dashboard_final_test.dart
?? backend/.env.biometric.example
?? backend/README_BIOMETRIC.md
?? backend/VERIFICACION_BIOMETRIC.md
?? backend/alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py
?? backend/alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py
?? backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py
?? backend/app/modules/correspondence/document_creation_authorization.py
?? backend/app/modules/correspondence/document_snapshot.py
?? backend/app/modules/correspondence/pdf/operational_document_pdf.py
?? backend/app/modules/identity/permission_admin.py
?? backend/app/modules/identity/user_permission.py
?? backend/app/modules/organization/hierarchy_admin.py
?? backend/app/modules/organization/position_hierarchy.py
?? backend/app/modules/rrhh/
?? backend/requirements-biometric.txt
?? backend/tests/historical_documents.py
?? backend/tests/test_phase1_authorization.py
?? backend/tests/test_phase2_operational_documents.py
?? backend/tests_rrhh/
?? backend/tests_startup/
?? docs/PHASE1_AUTHORIZATION.md
?? docs/PHASE2_DOCUMENTS.md
?? lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart
?? packages/correspondencia_api/test/phase1_contract_test.dart
?? packages/correspondencia_api/test/phase2_contract_test.dart
?? packages/correspondencia_repository/test/phase1_mapper_test.dart
?? packages/correspondencia_repository/test/phase2_mapper_test.dart
?? test/features/administration/user_permissions_section_test.dart
?? test/features/correspondence/phase2_creation_test.dart

```

## 3. Alembic

Inicial: j1b2c3d4e5f6, una head.
Final: k1b2c3d4e5f6, una head. h1/i1/j1 permanecen idénticas.

## 4. Archivos creados por Fase 3

- backend/alembic/versions/k1b2c3d4e5f6_correspondence_operation_scopes.py
- backend/app/modules/correspondence/authorization.py
- backend/app/modules/identity/role_transition.py
- backend/scripts/migrate_authorization_roles.py
- backend/tests/test_phase3_authorization.py
- docs/AUTHORIZATION_PERMISSION_CATALOG.md
- docs/FINAL_AUTHORIZATION_ARCHITECTURE.md
- docs/PHASE3_QA_REPORT.md
- packages/correspondencia_api/test/phase3_capabilities_test.dart
- packages/correspondencia_repository/test/phase3_capabilities_test.dart

## 5. Archivos modificados por Fase 3

Esta lista compara con el estado inicial, no con HEAD, para distinguir el WIP anterior:

- backend/app/modules/correspondence/attachment_service.py
- backend/app/modules/correspondence/insights.py
- backend/app/modules/correspondence/schemas.py
- backend/app/modules/correspondence/service.py
- backend/app/modules/correspondence/visibility.py
- backend/app/modules/identity/rbac_service.py
- backend/app/modules/identity/user_admin_service.py
- backend/app/modules/notifications/service.py
- backend/tests/conftest.py
- backend/tests/test_correspondence_derive_authorization.py
- backend/tests/test_correspondence_inbox.py
- backend/tests/test_correspondence_lifecycle.py
- backend/tests/test_correspondence_sent.py
- backend/tests/test_correspondence_tracking_visibility.py
- backend/tests/test_correspondence_visibility.py
- backend/tests/test_final_blocks.py
- backend/tests/test_master_data_logical_delete_guards.py
- backend/tests/test_phase2_operational_documents.py
- backend/tests/test_qa_smoke.py
- backend/tests/visibility_helpers.py
- lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart
- lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart
- lib/features/correspondence/detail/views/correspondence_detail_body.dart
- lib/features/correspondence/detail/widgets/correspondence_lifecycle_section.dart
- lib/features/correspondence/domain/entities/correspondence_entity.dart
- lib/features/correspondence/domain/mappers/correspondence_entity_mapper.dart
- packages/correspondencia_api/lib/src/features/correspondence/models/correspondence_response.dart
- packages/correspondencia_repository/lib/src/features/correspondence/entities/correspondence.dart
- packages/correspondencia_repository/lib/src/features/correspondence/mappers/correspondence_mapper.dart
- packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart
- test/features/administration/position_correspondence_scope_test.dart
- test/features/administration/user_permissions_section_test.dart
- test/features/correspondence/detail/correspondence_detail_body_test.dart
- test/features/correspondence/detail/detail_test_fixtures.dart

Las adaptaciones de tests asignan explícitamente los nuevos permisos a fixtures anteriores.
No se agregó un bypass de autorización de producción ni se redujo el número de pruebas.
El test anterior que atribuía scope al cambio de cargo se convirtió al contrato nuevo:
el cargo no sustituye la concesión explícita del usuario.

## 6. Migración creada

k1 agrega los siete Permission nuevos y authorization_migration_audits.
Formaliza read.own y las cuatro operaciones antes implícitas para cuentas existentes.
Copia el flag legacy de unidad a grants directos y mantiene compatibilidad de provisión de roles legacy.
No cambia documentos, movimientos, snapshots, jerarquías ni membresías de roles.
La conversión de membresías se realiza solamente con la herramienta revisada por separado.

## 7. Catálogo final

28 Permission en instalación nueva: 26 core y 2 RR.HH. preexistentes, sin duplicados.
Inventario con referencias, deprecated y observaciones en AUTHORIZATION_PERMISSION_CATALOG.md.

Nuevos: correspondence.read.own, correspondence.read.unit, correspondence.read.all,
correspondence.derive, correspondence.conclude, correspondence.reopen,
correspondence.attachments.manage. reports.view y los cuatro de creación se conservan.

## 8. Lectura final

Permisos de lectura explícitos, por unión; SQL centralizado en visibility.py.
Read.own conserva asignación en unidad y seguimiento personal de creador/derivador.
Read.unit limita a la unidad institucional actual.
Read.all permite lectura global incluso sin Employee.
Los endpoints fuera de alcance devuelven 404; un permiso de operación no concede lectura por sí solo.

## 9. Derivación final

derive AND contexto activo AND responsabilidad directa/alcance de unidad AND estado ACTIVE.
La unidad del actor debe ser la responsable vigente. Read.all no permite operar en otra unidad.
Se mantienen validación de destino, bloqueo de fila y un movimiento por acción.

## 10. Concluir/reabrir

Permiso específico AND can_operate AND estado compatible.
El lector de unidad no desplaza a otro responsable directo activo.
Una cuenta técnica sin Employee no puede operar institucionalmente.

## 11. Adjuntos

attachments.manage AND can_operate AND documento ACTIVE para agregar/eliminar.
Lectura y descarga siguen la visibilidad del documento.
La baja continúa siendo lógica; se mantiene la atomicidad existente.

## 12. Reportes/dashboard

reports.view habilita el módulo y el alcance filtra sus filas/exportaciones.
El dashboard usa la misma política central.
Read.all permite filtros globales; read.unit solamente su unidad.
Tener únicamente reports.view no da acceso global.

## 13. Flag legacy de unidad

Columna conservada, sin efecto de autorización después de k1.
Copia única a grants existentes; interruptor Flutter de solo lectura con ayuda.
La retirada física exige auditar clientes/bases y aprobar el procedimiento.

## 14. correspondence.create legacy

Permission y grants conservados; UI/documentación lo marcan deprecated.
No autoriza nuevas creaciones ni elude JEFE+/DIRECTOR+.
Retirada posterior con auditoría de consumidores/concesiones y aprobación.

## 15. Roles legacy

ADMIN/MANAGER/OPERATOR siguen existiendo y funcionando antes de la conversión.
MANAGER/OPERATOR pasan a OPERADOR con grants directos equivalentes por usuario.
ADMIN se omite; --include-admin USERNAME permite conversión explícita a OPERADOR,
nunca promoción automática a SUPERADMIN. Roles custom y grants propios se conservan.

## 16. Herramienta y dry-run

backend/scripts/migrate_authorization_roles.py:
dry-run predeterminado/READ ONLY, JSON por usuario y SHA-256 de plan.
Apply exige la huella, verifica equivalencia y continuidad, bloquea deriva del plan,
opera atómicamente en SERIALIZABLE y registra before/after por usuario y lote.

Se ejecutaron realmente CLI dry-run y CLI apply exclusivamente sobre phase3_legacy_verified:
dos usuarios sintéticos convertidos, documentos/movimientos idénticos por hash y
plan posterior vacío. Los tests también cubren ADMIN explícito, cuentas inactivas,
diferencias inesperadas del rol objetivo, plan alterado y ausencia de escrituras del dry-run.
No se aplicó sobre la base habitual.

## 17. Seguridad administrativa/SUPERADMIN

SUPERADMIN conserva expansión funcional central, sin identidad institucional ficticia.
Técnico sin Employee: administración/lectura global permitidas; emisión/mutación institucional denegadas.
OPERADOR sin capacidades administrativas no puede administrarse permisos ni asignarse SUPERADMIN.
Delegados no pueden conceder más de lo que poseen ni consolidar nuevos grants administrativos directos en sí mismos.
Se mantienen protección y pruebas de continuidad del último administrador, incluida concurrencia.

## 18. Flutter

DTO/entity/mapper/copyWith transportan can_conclude/can_reopen/can_manage_attachments;
campos ausentes cierran permisos en false. Se conserva has_document_pdf en copyWith.
Los controles de detalle usan capacidades backend, independientemente de can_operate.
Se agrupan permisos de lectura/creación/operación y se conserva reports.view como módulo.
El cargo ya no habilita el scope desde su interruptor.

## 19–20. Validaciones y resultados exactos

| Ejecución | Resultado |
|---|---|
| Backend python -m pytest tests/ -q --tb=short -p no:cacheprovider | 561 passed, 0 failed; 2 DeprecationWarning de librerías |
| Flutter flutter test --no-pub --reporter expanded | 576 passed, 0 failed |
| correspondencia_api | 50 passed |
| correspondencia_repository | 39 passed |
| failures | 6 passed |
| flutter analyze --no-pub | 0 errors / 0 warnings / 98 infos previos |
| git diff --check | OK |
| alembic heads | k1b2c3d4e5f6, una sola head |
| Base vacía -> k1 | OK, PostgreSQL temporal aislado |
| Base histórica j1 -> k1 | OK; 5 documentos y 5 movimientos idénticos |
| CLI roles dry-run/apply en base sintética | OK; 2 conversiones, historia intacta, replan vacío |
| WIP/migraciones protegidas | 32/32 hashes idénticos |

El analizador devuelve exit 1 por los mismos 98 infos preexistentes; no hay errores ni warnings.
Backend se ejecutó sobre phase3_final, con código montado de solo lectura en el contenedor QA.
Las 61 pruebas nuevas cubren scopes, mutaciones, contexto, permisos, SUPERADMIN, estado,
adjuntos, notificaciones y migración. Se conservaron las 500 pruebas anteriores.
No existe una suite Chrome/E2E estable versionada; no se afirma un smoke Chrome realizado.

Los cuatro PDF operativos fueron renderizados y revisados visualmente tras la suite.
Se ejecutaron los tests legacy y de inmutabilidad de snapshots, sin modificar renderers.
La migración j1 -> k1 preservó también snapshots ya existentes y las referencias DocumentType.

## 21. Hardcodes restantes

SUPERADMIN se conserva en el resolvedor y protección de asignación, por diseño.
ADMIN/MANAGER/OPERATOR permanecen en semillas y herramienta de transición, no en reglas de documentos.
can_view_unit_correspondence permanece en DTO/columna y como nombre compatible de capacidad calculada.
correspondence.create permanece como dato legacy/etiquetado deprecated y en migraciones anteriores.
No hay comparaciones del nombre del cargo/rol para permisos operativos ni para scope.
Detalle del inventario en AUTHORIZATION_PERMISSION_CATALOG.md.

## 22. Riesgos pendientes

Los PDF legacy pueden resolver nombres de origen/movimientos desde maestros actuales cuando no
existe un snapshot suficiente. No se reconstruyeron históricos ni se cambió ese renderer.
Los cuatro PDF nuevos conservan sus datos de emisión; recursos visuales/plantilla siguen versionados en código.

El traslado de cargos/unidades requiere revisar grants explícitos del usuario.
La semilla de transición k1 no debe ejecutarse como sincronización periódica.
OPERADOR debe mantenerse sin una unión indiscriminada de capacidades; el migrador bloquea ampliaciones.
Los roles legacy permanecen por compatibilidad hasta aplicar y auditar la conversión aprobada.
El árbol contiene todavía Fases 1/2 y WIP ajeno: no se preparó un commit automático.

## 23. Antes de producción

Revisar usuarios reales, posiciones y jerarquías; respaldar DB/adjuntos; probar migración con copia aprobada;
revisar dry-run y ADMIN por identidad; comprobar equivalencia; ejecutar smoke visual QA;
autorizar por separado aplicación de datos y despliegue.
Rollback conceptual y diagrama final en FINAL_AUTHORIZATION_ARCHITECTURE.md.

No commit. No push. No deploy. No migración de la base habitual.

## Git status final

Indice vacio. Se conserva el WIP anterior.

```text
 M backend/Dockerfile
 M backend/alembic/env.py
 M backend/app/main.py
 M backend/app/modules/auth/dependencies.py
 M backend/app/modules/auth/institutional_context.py
 M backend/app/modules/auth/router.py
 M backend/app/modules/auth/schemas.py
 M backend/app/modules/correspondence/attachment_service.py
 M backend/app/modules/correspondence/correspondence.py
 M backend/app/modules/correspondence/creation_policy.py
 M backend/app/modules/correspondence/document_type.py
 M backend/app/modules/correspondence/document_type_admin_service.py
 M backend/app/modules/correspondence/document_type_profiles.py
 M backend/app/modules/correspondence/insights.py
 M backend/app/modules/correspondence/router.py
 M backend/app/modules/correspondence/schemas.py
 M backend/app/modules/correspondence/service.py
 M backend/app/modules/correspondence/visibility.py
 M backend/app/modules/identity/__init__.py
 M backend/app/modules/identity/admin_router.py
 M backend/app/modules/identity/admin_schemas.py
 M backend/app/modules/identity/administrative_continuity.py
 M backend/app/modules/identity/rbac_service.py
 M backend/app/modules/identity/user_admin_service.py
 M backend/app/modules/notifications/service.py
 M backend/app/modules/organization/__init__.py
 M backend/app/modules/organization/admin_router.py
 M backend/app/modules/organization/admin_schemas.py
 M backend/app/modules/organization/position.py
 M backend/app/modules/organization/position_admin_service.py
 M backend/requirements.txt
 M backend/tests/c4/test_role_assignment.py
 M backend/tests/conftest.py
 M backend/tests/test_chaining_catalog_code.py
 M backend/tests/test_configured_authority.py
 M backend/tests/test_correspondence.py
 M backend/tests/test_correspondence_derive_authorization.py
 M backend/tests/test_correspondence_inbox.py
 M backend/tests/test_correspondence_lifecycle.py
 M backend/tests/test_correspondence_sent.py
 M backend/tests/test_correspondence_tracking_visibility.py
 M backend/tests/test_correspondence_visibility.py
 M backend/tests/test_correspondence_workflow.py
 M backend/tests/test_creation_profile_routing.py
 M backend/tests/test_edie_first_recipients.py
 M backend/tests/test_edie_unit_only_derivation.py
 M backend/tests/test_encadenamiento_pdf.py
 M backend/tests/test_final_blocks.py
 M backend/tests/test_institutional_mayor.py
 M backend/tests/test_logical_deactivation.py
 M backend/tests/test_master_data_logical_delete_guards.py
 M backend/tests/test_qa_smoke.py
 M backend/tests/visibility_helpers.py
 M lib/core/auth/permissions.dart
 M lib/features/administration/basic_data/document_types/list_document_types/tables/document_types_table.dart
 M lib/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_state.dart
 M lib/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart
 M lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_state.dart
 M lib/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart
 M lib/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart
 M lib/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart
 M lib/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart
 M lib/features/correspondence/detail/views/correspondence_detail_body.dart
 M lib/features/correspondence/detail/widgets/correspondence_detail_header.dart
 M lib/features/correspondence/detail/widgets/correspondence_lifecycle_section.dart
 M lib/features/correspondence/domain/document_type_profiles.dart
 M lib/features/correspondence/domain/entities/correspondence_entity.dart
 M lib/features/correspondence/domain/mappers/correspondence_entity_mapper.dart
 M lib/features/correspondence/list_correspondence/views/correspondence_body.dart
 M lib/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart
 M lib/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart
 M lib/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart
 M lib/features/correspondence/upsert_correspondence/widgets/origin_section.dart
 M lib/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart
 M lib/features/dashboard/views/dashboard_page.dart
 M lib/shared/widgets/form/app_text_field.dart
 M packages/correspondencia_api/lib/src/features/authentication/models/me_employee_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/api/correspondence_api.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/correspondence_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_admin_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_response.dart
 M packages/correspondencia_api/lib/src/features/identity/api/users_admin_api.dart
 M packages/correspondencia_api/lib/src/features/identity/models/user_admin_response.dart
 M packages/correspondencia_api/lib/src/features/organization/api/positions_admin_api.dart
 M packages/correspondencia_api/lib/src/features/organization/models/position_admin_response.dart
 M packages/correspondencia_repository/lib/src/features/authentication/entities/institutional_context.dart
 M packages/correspondencia_repository/lib/src/features/authentication/mappers/user_response_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/correspondence.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type_admin.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/correspondence_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/document_type_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/repository/correspondence_repository.dart
 M packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart
 M packages/correspondencia_repository/lib/src/features/identity/mappers/identity_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/identity/repository/users_admin_repository.dart
 M packages/correspondencia_repository/lib/src/features/organization/entities/position_admin.dart
 M packages/correspondencia_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/organization/repository/positions_admin_repository.dart
 M test/correspondence_creation_permission_test.dart
 M test/features/administration/basic_data/positions/upsert_positions_view_test.dart
 M test/features/administration/basic_data/users/upsert_users_view_test.dart
 M test/features/administration/position_correspondence_scope_test.dart
 M test/features/correspondence/correspondence_document_actions_cubit_test.dart
 M test/features/correspondence/detail/correspondence_detail_body_test.dart
 M test/features/correspondence/detail/correspondence_detail_header_test.dart
 M test/features/correspondence/detail/detail_test_fixtures.dart
 M test/features/dashboard/dashboard_final_test.dart
?? backend/.env.biometric.example
?? backend/README_BIOMETRIC.md
?? backend/VERIFICACION_BIOMETRIC.md
?? backend/alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py
?? backend/alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py
?? backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py
?? backend/alembic/versions/k1b2c3d4e5f6_correspondence_operation_scopes.py
?? backend/app/modules/correspondence/authorization.py
?? backend/app/modules/correspondence/document_creation_authorization.py
?? backend/app/modules/correspondence/document_snapshot.py
?? backend/app/modules/correspondence/pdf/operational_document_pdf.py
?? backend/app/modules/identity/permission_admin.py
?? backend/app/modules/identity/role_transition.py
?? backend/app/modules/identity/user_permission.py
?? backend/app/modules/organization/hierarchy_admin.py
?? backend/app/modules/organization/position_hierarchy.py
?? backend/app/modules/rrhh/
?? backend/requirements-biometric.txt
?? backend/scripts/migrate_authorization_roles.py
?? backend/tests/historical_documents.py
?? backend/tests/test_phase1_authorization.py
?? backend/tests/test_phase2_operational_documents.py
?? backend/tests/test_phase3_authorization.py
?? backend/tests_rrhh/
?? backend/tests_startup/
?? docs/AUTHORIZATION_PERMISSION_CATALOG.md
?? docs/FINAL_AUTHORIZATION_ARCHITECTURE.md
?? docs/PHASE1_AUTHORIZATION.md
?? docs/PHASE2_DOCUMENTS.md
?? docs/PHASE3_QA_REPORT.md
?? lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart
?? packages/correspondencia_api/test/phase1_contract_test.dart
?? packages/correspondencia_api/test/phase2_contract_test.dart
?? packages/correspondencia_api/test/phase3_capabilities_test.dart
?? packages/correspondencia_repository/test/phase1_mapper_test.dart
?? packages/correspondencia_repository/test/phase2_mapper_test.dart
?? packages/correspondencia_repository/test/phase3_capabilities_test.dart
?? test/features/administration/user_permissions_section_test.dart
?? test/features/correspondence/phase2_creation_test.dart
```
