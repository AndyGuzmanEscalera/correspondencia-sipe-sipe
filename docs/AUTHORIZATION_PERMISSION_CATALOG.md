# Catálogo definitivo de permisos y auditoría de referencias

Revalidado el 2026-10-27 sobre la cadena independiente g2 -> i1 -> j1 -> k1.
La instalación limpia contiene 26 permisos de Correspondencia, administración y configuración,
sin códigos duplicados. Los dos permisos rrhh.read/rrhh.manage pertenecen exclusivamente al WIP h1,
quedan fuera de este catálogo versionable y no son necesarios para las Fases 1–3.

Las referencias de aplicación siguientes no incluyen tests ni migraciones.
La ausencia de una mención literal en Flutter no significa falta de soporte:
el cliente utiliza sesión, catálogo dinámico y capacidades calculadas por el backend.

| Código | Referencias backend | Referencias Flutter/packages | Estado |
|---|---:|---:|---|
| correspondence.attachments.manage | 1 | 0 | En uso |
| correspondence.conclude | 1 | 1 | En uso |
| correspondence.create | 0 | 2 | Deprecated; no autoriza creación |
| correspondence.create.circular | 1 | 1 | En uso |
| correspondence.create.internal_communication | 1 | 1 | En uso |
| correspondence.create.memorandum | 1 | 1 | En uso |
| correspondence.create.report | 1 | 1 | En uso |
| correspondence.derive | 1 | 1 | En uso |
| correspondence.read.all | 1 | 0 | En uso |
| correspondence.read.own | 1 | 0 | En uso |
| correspondence.read.unit | 1 | 1 | En uso |
| correspondence.reopen | 1 | 1 | En uso |
| master_data.document_types.manage | 2 | 1 | En uso |
| master_data.document_types.read | 2 | 1 | En uso |
| master_data.employees.manage | 2 | 1 | En uso |
| master_data.employees.read | 2 | 1 | En uso |
| master_data.organizational_units.manage | 2 | 1 | En uso |
| master_data.organizational_units.read | 2 | 1 | En uso |
| master_data.positions.manage | 3 | 1 | En uso |
| master_data.positions.read | 3 | 1 | En uso |
| master_data.roles.assign | 4 | 1 | En uso |
| master_data.users.manage | 5 | 1 | En uso |
| master_data.users.read | 2 | 1 | En uso |
| reports.view | 1 | 3 | En uso |
| system.settings.manage | 2 | 1 | En uso |
| system.settings.read | 1 | 1 | En uso |

## Interpretación y compatibilidad

- correspondence.create se conserva como dato legacy y etiqueta deprecated; no autoriza CREATE por sí solo.
- Los siete permisos de lectura y operación se exigen en backend. Flutter consume capacidades, sin duplicar SQL de alcance.
- SUPERADMIN permanece en el resolvedor central y en la protección de su asignación.
- ADMIN/MANAGER/OPERATOR se usan para identificar datos de transición, sin autorizar operaciones documentales por nombre de rol.
- institutional_base_roles.py sigue disponible para las semillas históricas; no se modificaron esas migraciones.
- Position.can_view_unit_correspondence se conserva como columna/DTO legado. K1 copia su capacidad a grants explícitos.
- Los campos homónimos de contexto/contadores son capacidades calculadas desde permisos, no lecturas del flag antiguo.
- No se detectaron permisos core operativos huérfanos; algunos solo se exigen literalmente en backend porque Flutter usa capacidades.
- No se borraron permisos, roles ni grants reales como parte de esta auditoría.

La evidencia, los hashes del WIP y el manifiesto exacto de commit están en AUTHORIZATION_RRHH_SEPARATION.md.
