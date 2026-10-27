# Fase 2: documentos operativos y autorización institucional

Fecha: 2026-10-26. Repositorio: `C:\dev\correspondencia_sipe_sipe`. Rama: `develop`.
Este lote está sin commit. No se ejecutaron push, despliegue ni migraciones sobre la base habitual o producción.

## 1. HEAD inicial y final

Ambos: `59c19192e1b27520c4d7269a42793ad834848801`.
El índice permanece vacío. Se preservaron las modificaciones previas de Fase 1.

## 2. Estado inicial del repositorio

El árbol ya contenía Fase 1 y WIP de RR.HH./biométrico. Se capturaron hashes de 77 archivos modificados/no versionados antes de Fase 2.
Comprobación final por SHA-256: los 30 archivos de WIP previos a Fase 1 y la migración i1 permanecen idénticos (31/31).

```text
 M backend/Dockerfile
 M backend/alembic/env.py
 M backend/app/main.py
 M backend/app/modules/auth/dependencies.py
 M backend/app/modules/auth/router.py
 M backend/app/modules/correspondence/creation_policy.py
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
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart
 M lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_state.dart
 M lib/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart
 M lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart
 M lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_state.dart
 M lib/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart
 M lib/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart
 M lib/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart
 M packages/correspondencia_api/lib/src/features/identity/api/users_admin_api.dart
 M packages/correspondencia_api/lib/src/features/identity/models/user_admin_response.dart
 M packages/correspondencia_api/lib/src/features/organization/api/positions_admin_api.dart
 M packages/correspondencia_api/lib/src/features/organization/models/position_admin_response.dart
 M packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart
 M packages/correspondencia_repository/lib/src/features/identity/mappers/identity_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/identity/repository/users_admin_repository.dart
 M packages/correspondencia_repository/lib/src/features/organization/entities/position_admin.dart
 M packages/correspondencia_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/organization/repository/positions_admin_repository.dart
 M test/features/administration/basic_data/positions/upsert_positions_view_test.dart
 M test/features/administration/basic_data/users/upsert_users_view_test.dart
?? backend/.env.biometric.example
?? backend/README_BIOMETRIC.md
?? backend/VERIFICACION_BIOMETRIC.md
?? backend/alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py
?? backend/alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py
?? backend/app/modules/identity/permission_admin.py
?? backend/app/modules/identity/user_permission.py
?? backend/app/modules/organization/hierarchy_admin.py
?? backend/app/modules/organization/position_hierarchy.py
?? backend/app/modules/rrhh/
?? backend/requirements-biometric.txt
?? backend/tests/test_phase1_authorization.py
?? backend/tests_rrhh/
?? backend/tests_startup/
?? docs/PHASE1_AUTHORIZATION.md
?? lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart
?? packages/correspondencia_api/test/phase1_contract_test.dart
?? packages/correspondencia_repository/test/phase1_mapper_test.dart
?? test/features/administration/user_permissions_section_test.dart

```

## 3. Alembic inicial

Una sola head: `i1b2c3d4e5f6`. No se modificaron i1 ni h1.

## 4. Migración nueva

`backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py`.
Cadena: `i1b2c3d4e5f6 -> j1b2c3d4e5f6`; una sola head final.

Agrega al catálogo `profile`, `is_operational`, `creation_permission` y
`minimum_hierarchy_id` (FK RESTRICT). Agrega `correspondences.document_snapshot` JSONB nullable.
No importa modelos de RR.HH. ni necesita Turnos para su propia lógica.

La semilla reutiliza IDs y nombres existentes, rechaza catálogos ambiguos y usa inserciones sin duplicar permisos/asignaciones.
La prueba ejecuta la semilla dos veces y verifica IDs, documentos, snapshots y cardinalidad.
El downgrade se rechaza explícitamente: quitar estos campos requiere un plan que preserve los documentos emitidos.

## 5–6. Permisos y tipos operativos

| Código estable | Perfil | Permiso funcional | Jerarquía mínima |
|---|---|---|---|
| COMUNICADO_INTERNO | INTERNAL_COMMUNICATION | correspondence.create.internal_communication | Sin mínimo superior |
| INFORME | REPORT | correspondence.create.report | Sin mínimo superior |
| MEMORANDUM | MEMORANDUM | correspondence.create.memorandum | JEFE |
| CIRCULAR | CIRCULAR | correspondence.create.circular | DIRECTOR |

COMUNICADO_INTERNO se crea si falta, con UUID determinista. INFORME, MEMORANDUM y CIRCULAR
se reutilizan cuando existen; se conservan sus IDs y nombres. No se reasignan documentos antiguos.

## 7. Catálogo histórico

Se desactivan para creación los códigos distintos de los cuatro operativos:
EDIE/S, NOTA, CARTA, SOLICITUD, CERTIFICACION y demás tipos anteriores.
Se conservan filas, UUID, documentos relacionados y la posibilidad de consultarlos en reportes.
Los perfiles LEGACY_CHAINING y LEGACY_INTERNAL_NOTE siguen disponibles para históricos.

Reactivar por accidente un tipo legacy en administración no habilita CREATE: también debe ser
operativo y cumplir el contrato estructural protegido. Crear un tipo personalizado no habilita
una quinta operación de creación.

## 8. Política final de creación y transición

El backend exige: permiso específico efectivo + usuario activo + funcionario/cargo/unidad activos
+ jerarquía cuando el tipo tenga mínimo + validaciones existentes de contenido, Ventanilla y destino.

Se usa el resolvedor central de Fase 1 (RolePermission UNION UserPermission).
SUPERADMIN obtiene los cuatro permisos registrados, pero no recibe funcionario, cargo ni jerarquía ficticios.

Transición elegida: la migración agrega los cuatro permisos a los roles y asignaciones directas
que ya tenían `correspondence.create`. Conserva el permiso anterior.
No hay un OR de compatibilidad en tiempo de ejecución: después de migrar,
`correspondence.create` por sí solo no habilita una nueva creación.
La migración no cambia los roles de usuarios ni los convierte a OPERADOR.
La jerarquía sigue limitando Memorándum/Circular aunque se migren los cuatro permisos.

## 9–10. Jerarquía y actor frente a origen

Se resuelve desde el usuario autenticado: User -> Employee -> Position -> PositionHierarchy.
La comparación es `actor_hierarchy.rank >= minimum_hierarchy.rank`, sin nombres de cargo ni de rol.

Un Técnico no obtiene autoridad por seleccionar un Director como origen.
Un Jefe con permiso memorandum puede registrar Memorándum por ese origen; sin permiso no puede.
Los tipos sin mínimo superior admiten cargos transitorios con hierarchy_id null.
Una jerarquía explícitamente inactiva se rechaza. Los restringidos requieren una jerarquía activa.

La FK del mínimo, el código, perfil, condición operativa y permiso son estructurales:
la API de edición del catálogo solo permite nombre visible; rechaza campos extra.
La baja/restauración sigue siendo lógica. Los rangos de PositionHierarchy siguen siendo configuración
institucional administrada de Fase 1; cambiarlos afecta la comparación y exige revisar su orden.

## 11. Backend

- `document_creation_authorization.py`: única política de creación por actor/tipo.
- `document_type_profiles.py`: perfiles de presentación independientes de autorización.
- `GET /document-types/available-for-create`: filtra activos/operativos por permisos/contexto/jerarquía.
- `POST /correspondences`: vuelve a comprobar toda la política aunque se omita Flutter.
- `GET /auth/me`: position.hierarchy con id, code, name, rank e is_active.
- La construcción conserva routing y movimientos CREATED/DERIVED existentes.
- No se sustituyeron ownership, visibilidad, alcance de unidad, derivación, conclusión, reapertura ni adjuntos.

## 12. Flutter

El selector consume el catálogo autorizado por el servidor, sin replicar comparaciones de rangos.
El formulario ofrece actualizar tipos disponibles y sustituye una selección que haya dejado de estar autorizada.
Un catálogo vacío bloquea el registro y explica que no hay tipos disponibles.
Los accesos a creación utilizan los cuatro permisos nuevos, no el permiso legacy aislado.

Comunicado/Memorándum/Circular reutilizan el formulario de contenido con asunto o referencia,
origen, contenido multilínea (máximo 10.000 caracteres), prioridad y destino actual.
Informe conserva su contenido y campos compatibles. Los cuatro envían correspondencia INTERNAL.
Los widgets/perfiles legacy se conservan. Los rechazos del backend se muestran sin éxito ficticio.

Administración muestra uso operativo/histórico, perfil, mínimo y permiso como metadatos de lectura.
El nombre visible y estado lógico siguen configurables; los campos estructurales no se editan ahí.

## 13. API y repository

DTO/entity/mapper transportan perfil, operatividad, permiso y mínimo, así como hierarchy en sesión
y has_document_pdf en detalle. Los valores predeterminados conservan compatibilidad con respuestas anteriores.
Se agregó descarga de documento institucional, separada de descarga del encadenamiento legacy.

## 14. PDF y snapshots

Los cuatro tipos nuevos generan un PDF institucional desde un snapshot versión 1,
template `institutional-document-v1`, con encabezado oficial, número/año, fecha, origen,
destinatario, asunto/referencia, contenido, actor/cargo/unidad/jerarquía y pie de hoja de ruta/página.

El snapshot guarda actor y origen por separado; también conserva el destinatario original.
El PDF no vuelve a resolver nombres, cargos o unidades actuales. La plantilla legacy no se modificó.
Detalle muestra Ver PDF y Descargar PDF si existe snapshot; los históricos EDIE conservan sus acciones anteriores.
La descarga exige sesión y visibilidad del documento; tener permiso de crear Circular no permite leer PDF ajenos.

Revisión visual: Memorándum y las cuatro páginas de una Circular extensa, sin solapamientos ni cortes.
Pruebas verifican texto completo, acentos, escape de contenido y estabilidad tras cambios en maestros.

Limitaciones deliberadas: el PDF generado es de emisión; no representa los movimientos posteriores
ni una firma digital. El emblema/plantilla visual son recursos versionados del código, no bytes congelados por documento.
No se inventa un nuevo snapshot para documentos previos.

## 15. Compatibilidad histórica y prueba de migración

Se usó una base aislada `phase2_legacy_upgrade`:
1. Migrar hasta i1.
2. Insertar cinco documentos sintéticos EDIE, NOTA, INFORME, MEMORANDUM y CIRCULAR, con cinco movimientos y snapshots previos.
3. Registrar concesión legacy tanto por rol como directamente a usuario.
4. Migrar a j1.
5. Comparar todas las columnas anteriores y UUID.

Resultado: 5/5 documentos y 5/5 movimientos idénticos; snapshots previos intactos;
IDs de los cinco tipos conservados; documento nuevo snapshot null en esos históricos.
Las asignaciones de prueba quedan con legacy + cuatro específicos (5 por rol y 5 directos).
Se probó además instalación desde base vacía hasta j1.

Las pruebas legacy preparan filas con `tests/historical_documents.py`, un constructor de fixtures
sin endpoint público; las lecturas, operaciones, reportes y descargas se verifican por HTTP real.
Los tipos operativos siempre pasan por el POST público, incluso desde ese helper.
Las pruebas nuevas confirman que el POST público rechaza tipos legacy.

## 16–17. Validaciones y resultados

| Validación | Resultado |
|---|---|
| Backend: python -m pytest tests/ -q --tb=short -p no:cacheprovider | 500 passed, 0 failed; 2 DeprecationWarning de librerías |
| Flutter: flutter test --no-pub --reporter expanded | 575 passed, 0 failed |
| correspondencia_api | 48 passed |
| correspondencia_repository | 37 passed |
| failures | 6 passed |
| flutter analyze --no-pub | 0 errors / 0 warnings / 98 infos previos |
| git diff --check | OK |
| alembic heads | j1b2c3d4e5f6, una sola head |
| Base vacía -> upgrade head | OK en base aislada |
| Base legacy sintética -> upgrade head | OK; referencias y datos previos intactos |
| Semilla repetida | OK; sin duplicación |
| Revisión visual PDF | OK; una página y flujo de cuatro páginas |
| Integridad WIP/migraciones anteriores | 31/31 hashes idénticos |

El comando analyze devuelve código 1 por los 98 infos preexistentes (el mismo conteo de Fase 1).
No hay errores ni warnings del analizador. No se modificaron archivos ajenos para suprimir esos avisos.
No se encontró una suite Chrome/E2E estable versionada en el repositorio; no se reporta un smoke Chrome realizado.
Sí se ejecutaron el smoke HTTP versionado y las pruebas de widgets y contratos.

Backend se ejecutó en el contenedor de pruebas con montaje de código de solo lectura,
sobre PostgreSQL temporal aislado (`phase2_verified`); no se usó la base local habitual.
Las pruebas nuevas cubren 24 combinaciones jerarquía/tipo, permisos específicos,
contexto inválido, actor/origen, SUPERADMIN, catálogo, sesión, PDF, históricos, reportes,
exportaciones CSV/XLSX/PDF, adjuntos y metadatos protegidos.

## 18. Riesgos y pendientes operativos

Antes de adoptar el lote en otro entorno se debe revisar asignación real de jerarquías,
aprobar la transición aditiva de permisos y ejecutar una prueba visual Chrome con usuarios QA.
Los cargos sin jerarquía no podrán emitir Memorándum/Circular. Esto es una restricción deliberada.
Los rangos institucionales deben mantener el orden aprobado.
El árbol contiene Fase 1 y WIP ajeno además de Fase 2; no se preparó un commit automático.

## 19. Alcance posterior de Fase 3

Quedan fuera: migración masiva de usuarios a OPERADOR, retirada de roles/permisos legacy,
denies, sustitución de can_view_unit_correspondence y rediseño general de visibilidad/ownership.
Tampoco se modificaron RR.HH./biométrico, producción ni despliegues.

No commit. No push. No deploy.

## Estado final del working tree

?ndice vac?o; 72 archivos nuevos o modificados por Fase 2 sobre el estado inicial.

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
