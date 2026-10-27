# Fase 1: autorización y jerarquías institucionales

Implementación local sobre develop, base 59c19192e1b27520c4d7269a42793ad834848801. Sin commit, push ni deploy.

## Estado previo y aislamiento

El índice inicial estaba vacío. WIP previo, conservado por SHA-256 (30 archivos):
```text
 M backend/Dockerfile
 M backend/alembic/env.py
 M backend/app/main.py
 M backend/requirements.txt
?? backend/.env.biometric.example
?? backend/README_BIOMETRIC.md
?? backend/VERIFICACION_BIOMETRIC.md
?? backend/alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py
?? backend/app/modules/rrhh/
?? backend/requirements-biometric.txt
?? backend/tests_rrhh/
?? backend/tests_startup/
```

Head Alembic inicial: h1b2c3d4e5f6 (RR.HH./biométrico sin commit). Head versionada inicial: g2b3c4d5e6f7.
No se modificaron h1, alembic/env.py, app/main.py, Dockerfile, requirements ni funcionalidad biométrica.
Las rutas nuevas se incorporan mediante routers administrativos existentes.

## Migración

i1b2c3d4e5f6_authorization_hierarchies.py, down_revision=g2b3c4d5e6f7.
Corregido antes del commit el 2026-10-27 para excluir el WIP h1; la validación independiente está en AUTHORIZATION_RRHH_SEPARATION.md.
Agrega position_hierarchies, positions.hierarchy_id nullable y user_permissions.
Seis jerarquías iniciales (ranks 1 a 6): FUNCIONARIO, RESPONSABLE, JEFE, DIRECTOR, SECRETARIO, ALCALDE.
Code único sin distinguir mayúsculas; rank entero positivo. No se infiere jerarquía por nombre del cargo.
Seeds idempotentes: no restablecen personalizaciones ni reactivan roles/jerarquías ya existentes.
SUPERADMIN y OPERADOR se agregan sin asignar usuarios ni RolePermission al nuevo OPERADOR.
Se mantienen ADMIN, MANAGER, OPERATOR y todos los grants existentes.

El downgrade se rechaza explícitamente para evitar eliminar permisos y referencias institucionales.
No se ejecutaron downgrade, stamp ni cambios de esquema sobre bases habituales o producción.

## Permisos y seguridad

RbacService.get_effective_permission_codes es el resolvedor único:
- cuenta inactiva o inexistente: sin capacidades;
- SUPERADMIN activo: todos los Permission registrados, incluidos permisos nuevos;
- otros: RolePermission de roles activos UNION UserPermission, sin duplicados ni denies.

require_permission, creación de Correspondencia, /auth/me y continuidad administrativa consumen este resolvedor.
El alias get_user_permission_codes permanece por compatibilidad.
SUPERADMIN no fabrica Employee ni cambia ownership, alcance, estado o reglas documentales.

Administrar permisos directos exige master_data.users.manage y master_data.roles.assign.
El actor no puede conceder capacidades que no posee. Cambiar el rol reservado SUPERADMIN exige SUPERADMIN
y no se permite autoasignarlo. Los permisos de rol nuevos también se verifican contra las capacidades del actor.
La continuidad cuenta permisos heredados, directos y SUPERADMIN. Concesiones/revocaciones se serializan con
el mismo orden de bloqueo administrativo; las repeticiones conservan auditoría y la PK evita duplicados.

No se crea un SUPERADMIN automáticamente. La primera asignación requiere intervención administrativa
confiable fuera del flujo ordinario; el script de bootstrap existente puede asignar un rol a una cuenta existente.
No se ejecutó ese script ni se elevó ninguna cuenta real.

## API administrativa

| Método/ruta | Capacidad |
|---|---|
| GET /admin/positions/hierarchies | positions.read |
| GET /admin/positions/hierarchies/{id} | positions.read |
| POST /admin/positions/hierarchies | positions.manage |
| PUT /admin/positions/hierarchies/{id} | positions.manage |
| PATCH /admin/positions/hierarchies/{id}/active | positions.manage |
| GET /admin/permissions | users.manage + roles.assign |
| PUT /admin/users/{id}/permissions | users.manage + roles.assign |

Los códigos positions/users de la tabla corresponden al prefijo master_data.
No se crean permisos nuevos para jerarquías.
No puede desactivarse una jerarquía con cargos activos asignados.
Position admite null, valida jerarquías activas nuevas y preserva la asociación si un cliente omite hierarchy_id.
GET/POST/PUT Position devuelven hierarchy_id, hierarchy_code y hierarchy_name.

El PUT de permisos usa permission_ids (lista de UUID); una lista vacía limpia los grants directos.
Create/Update User también aceptan direct_permission_ids para guardado atómico con los datos/roles.
Omisión/null mantiene grants en updates; [] los limpia.
UserAdmin conserva role_codes y agrega direct_permission_ids, direct_permissions y effective_permissions.
/auth/me mantiene roles/permissions y el contrato de sesión existente.
El catálogo de roles incluye can_assign calculado en backend.

## Flutter

Cargos incluye Jerarquía institucional opcional, carga paginada del catálogo y conserva el switch de alcance.
Usuarios muestra roles compatibles y permisos directos con checkboxes agrupados en Administración,
Correspondencia, Reportes, Configuración y Otros; muestra permisos efectivos actuales.
Sin autorización se mantiene solo lectura. El backend sigue siendo autoridad final.
Los permisos directos intactos se omiten al editar; no se borran al guardar otros datos.

La sesión conserva su contrato. Como antes, los permisos de menú se actualizan al recuperar sesión:
/auth/me devuelve los permisos nuevos y el backend los comprueba en cada solicitud.

## Validación local, 26/10/2026

| Comprobación | Resultado |
|---|---|
| Backend pytest tests/ | 424 passed, 2 deprecations de dependencias |
| Flutter completo | 551 passed |
| correspondencia_api | 44 passed |
| correspondencia_repository | 33 passed |
| failures | 6 passed |
| flutter analyze | 0 errors / 0 warnings / 98 infos previos (exit 1 por infos) |
| Alembic heads | i1b2c3d4e5f6, una head |
| git diff --check | correcto |

PostgreSQL 16 temporal con tmpfs y runner dedicado. Se probó base nueva hasta head y upgrade desde h1 con
cargo/usuario legacy sintéticos: rol OPERATOR conservado, hierarchy_id null y cero permisos directos añadidos.
Ninguna migración se aplicó a la base habitual. No se hicieron pruebas de comunicación con biométricos.
No se realizó smoke visual Chrome en este lote; se verificaron formularios mediante widget tests.

## Archivos creados

- `backend/alembic/versions/i1b2c3d4e5f6_authorization_hierarchies.py`
- `backend/app/modules/identity/permission_admin.py`
- `backend/app/modules/identity/user_permission.py`
- `backend/app/modules/organization/hierarchy_admin.py`
- `backend/app/modules/organization/position_hierarchy.py`
- `backend/tests/test_phase1_authorization.py`
- `lib/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart`
- `packages/correspondencia_api/test/phase1_contract_test.dart`
- `packages/correspondencia_repository/test/phase1_mapper_test.dart`
- `test/features/administration/user_permissions_section_test.dart`
- `docs/PHASE1_AUTHORIZATION.md`

## Archivos modificados por Fase 1 (excluye WIP inicial)

- `backend/app/modules/auth/dependencies.py`
- `backend/app/modules/auth/router.py`
- `backend/app/modules/correspondence/creation_policy.py`
- `backend/app/modules/identity/__init__.py`
- `backend/app/modules/identity/admin_router.py`
- `backend/app/modules/identity/admin_schemas.py`
- `backend/app/modules/identity/administrative_continuity.py`
- `backend/app/modules/identity/rbac_service.py`
- `backend/app/modules/identity/user_admin_service.py`
- `backend/app/modules/organization/__init__.py`
- `backend/app/modules/organization/admin_router.py`
- `backend/app/modules/organization/admin_schemas.py`
- `backend/app/modules/organization/position.py`
- `backend/app/modules/organization/position_admin_service.py`
- `backend/tests/c4/test_role_assignment.py`
- `lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart`
- `lib/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_state.dart`
- `lib/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart`
- `lib/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart`
- `lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart`
- `lib/features/administration/basic_data/users/upsert_users/cubit/upsert_users_state.dart`
- `lib/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart`
- `lib/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart`
- `lib/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart`
- `packages/correspondencia_api/lib/src/features/identity/api/users_admin_api.dart`
- `packages/correspondencia_api/lib/src/features/identity/models/user_admin_response.dart`
- `packages/correspondencia_api/lib/src/features/organization/api/positions_admin_api.dart`
- `packages/correspondencia_api/lib/src/features/organization/models/position_admin_response.dart`
- `packages/correspondencia_repository/lib/src/features/identity/entities/user_admin.dart`
- `packages/correspondencia_repository/lib/src/features/identity/mappers/identity_admin_mapper.dart`
- `packages/correspondencia_repository/lib/src/features/identity/repository/users_admin_repository.dart`
- `packages/correspondencia_repository/lib/src/features/organization/entities/position_admin.dart`
- `packages/correspondencia_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart`
- `packages/correspondencia_repository/lib/src/features/organization/repository/positions_admin_repository.dart`
- `test/features/administration/basic_data/positions/upsert_positions_view_test.dart`
- `test/features/administration/basic_data/users/upsert_users_view_test.dart`

## Pendiente para Fase 2

- Aprobar e implementar las cuatro clases documentales y sus umbrales de jerarquía.
- Definir autoridad del actor frente al funcionario de origen y cualquier representación.
- Planificar asignación de jerarquías y migración de roles/permisos sin elevar derechos.
- Preservar perfiles, movimientos, snapshots y PDF legacy.
- Coordinar publicación de h1: i1 depende de esa migración WIP, que este lote no incorpora en commits.
- Validar el esquema real de cualquier entorno destino antes de aplicar migraciones.
