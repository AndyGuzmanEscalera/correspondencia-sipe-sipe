# Refactorización de comportamiento documental

Fecha: 2026-10-28. Repositorio: C:\dev\correspondencia_sipe_sipe. Rama: develop.

## 1. HEAD inicial y final

Inicial y final: `e08980157bde47f9da2a3b0fa79ee92f3c8e1bfb`.
No se creó ningún commit ni se modificó el índice.

## 2. Estado Git

El working tree estaba limpio al comenzar. Los cambios actuales pertenecen a este lote.
El estado exacto se registra al final de este informe. Sin push ni deploy.

## 3. Alembic inicial

Heads iniciales: `h1b2c3d4e5f6` (RR.HH.) y `k1b2c3d4e5f6` (Correspondencia).
La rama documental sigue siendo independiente de h1. No se modifica ninguna revisión previa.

## 4. Migración

Nueva revisión: `l1b2c3d4e5f6_document_behavior.py`.
Parent: `k1b2c3d4e5f6`. Sin depends_on ni dependencia de RR.HH.

- Reutiliza `document_types.profile`, sin crear una segunda columna de comportamiento.
- Backfill exclusivamente por códigos estables.
- Crea/reutiliza HOJA_RUTA preservando su ID y nombre si ya existe.
- Conserva el permiso `correspondence.create` para Hoja de Ruta, sin otorgarlo a usuarios o roles.
- Agrega CHECK de valores del enum.
- Agrega `emission_date` (DATE), `emission_time` (TIME), `page_count` (INTEGER positivo).
- Las tres columnas son nullable para históricos; no se inventan datos desde created_at.
- No cambia document_type_id, movimientos, adjuntos ni snapshots históricos.

Heads finales del repositorio: `h1b2c3d4e5f6` y `l1b2c3d4e5f6`.
La head documental es l1. No se mezclan las dos ramas de migración.
En las bases temporales documentales, la única revisión aplicada es l1 y no existen tablas biométricas.

## 5. Enum backend

`backend/app/modules/correspondence/document_behavior.py`.
Contrato string explícito: ROUTE_SHEET, INTERNAL_COMMUNICATION, REPORT,
MEMORANDUM, CIRCULAR, GENERIC, LEGACY_CHAINING, LEGACY_INTERNAL_NOTE.

DocumentFormProfile y los nombres antiguos son aliases de compatibilidad del mismo enum.
Los servicios de producción utilizan DocumentBehavior directamente.
El enum no contiene ni concede permisos.

## 6. Enum Flutter

`packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart`.
Mismos ocho valores de wire. Serialización mediante `value`, nunca enum.index.
Se exporta desde API y Repository. Los valores explícitos desconocidos se rechazan.

El fallback por código está centralizado y documentado exclusivamente para payloads antiguos
que carecen de behavior. Un GENERIC explícito siempre tiene prioridad.

## 7. DocumentType.behavior

Atributo ORM `behavior` respaldado por la columna existente `profile`.
El atributo `profile` se mantiene como synonym compatible.
API pública/administrativa expone behavior; DTO, entidades y mappers lo transportan como enum.
El campo profile de la API permanece para clientes anteriores.

## 8. Mapeo

| Identidad estable | Comportamiento |
|---|---|
| HOJA_RUTA | ROUTE_SHEET |
| COMUNICADO_INTERNO | INTERNAL_COMMUNICATION |
| INFORME | REPORT |
| MEMORANDUM | MEMORANDUM |
| CIRCULAR | CIRCULAR |
| EDIE, S, ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS | LEGACY_CHAINING |
| NOTA | LEGACY_INTERNAL_NOTE |
| Tipo personalizado sin comportamiento especial | GENERIC |

No se usa el nombre visible para inferir comportamiento.
Los códigos de los tipos estructurales siguen identificando sus contratos de permisos y jerarquía;
esta comprobación de identidad está separada de formularios y PDF.

## 9. Hoja de Ruta

Flujo propio ROUTE_SHEET. La validación reside en route_sheet_policy.py.
El formulario, el snapshot y el renderer se seleccionan por behavior.
Se conservan numeración, routing, CREATED/DERIVED, destinatarios, movimientos y adjuntos.
Cada registro produce exactamente una derivación inicial.

## 10. Campos

Reutilizados: origin_employee_id, sender_name, reference, description, numeración y snapshots existentes.
Nuevos exclusivamente: emission_date, emission_time, page_count.
El detalle muestra PARA y los datos explícitos de emisión.

## 11. DE

Exactamente uno de:
- origin_employee_id de funcionario activo;
- sender_name con nombre libre no vacío, normalizado con trim.

sender_name es el equivalente existente de origin_external_name; no se agrega otra columna.
Ambos vacíos o ambos informados se rechazan con 422.
El tipo INTERNAL/EXTERNAL se determina por el origen realmente resuelto.
La autorización sigue dependiendo del actor autenticado, nunca del origen seleccionado.

## 12. PARA

Reutiliza Configuración Institucional:
`institutional.mayor_display_name` y, cuando está configurado, `institutional.mayor_employee_id`.
Se preservan las referencias por IDs y los datos de autoridad existentes.
No se resuelve una autoridad buscando nombres/cargos que contengan Alcalde.

El endpoint autenticado `GET /route-sheet-authority` devuelve el texto configurado para el formulario.
La autoridad documental y el destinatario del routing siguen siendo responsabilidades diferentes.
El destino operativo conserva las reglas de receptores iniciales configurados y Ventanilla.

## 13. Fecha, hora y hojas

Datos explícitos requeridos para registros nuevos ROUTE_SHEET.
API valida fecha y hora; Flutter valida AAAA-MM-DD y HH:MM[:SS].
page_count es entero estricto entre 1 y 2147483647; DB impone > 0.
No se usa created_at como sustituto de emisión.

## 14. PDF

Registro de renderers por DocumentBehavior en pdf/document_renderer.py.
ROUTE_SHEET tiene renderer propio; los cuatro documentos conservan su plantilla institucional compartida.
Los snapshots v1 anteriores siguen resolviéndose por su profile explícito.
El endpoint y renderer físico de encadenamiento se mantienen para LEGACY_CHAINING.

Se generó un PDF con datos ficticios, se renderizó y se inspeccionó visualmente:
cabecera, márgenes, PARA, DE, referencia, contenido, emisión, hojas, firma y pie sin recortes.
Artefactos de comprobación: carpeta temporal sipe-document-behavior-20261028.

## 15. Snapshots

Se amplía document_snapshot existente con behavior y datos de emisión.
Se conserva el snapshot de actor/origen/destino, contenido, referencia y numeración.
PARA/autoridad sigue teniendo una única fuente persistida:
`institutional_authority_snapshot`.
El renderer compone ambos snapshots en memoria; no guarda otra copia de la autoridad.
No se reescriben los snapshots históricos.

## 16. Decisiones por código eliminadas

- Resolución de formulario vivo en Flutter: usa type.behavior.
- Selección por código de PDF en encabezado: usa documentBehavior.
- Validación de contenido/origen en backend: usa behavior persistido.
- Disponibilidad del PDF legacy en backend: usa LEGACY_CHAINING.
- Tipo predeterminado: prioridad por behavior, sin depender de nombres ni de códigos de presentación.
- Se eliminaron listas duplicadas de códigos para decidir formularios.

## 17. Usos legacy e identidad que permanecen

Inventario exacto: DOCUMENT_BEHAVIOR_HARDCODES.md.
79 coincidencias clasificadas A/C en código productivo y migraciones.
A: identidad estructural, enum, presentación o backfill estable.
C: migraciones inmutables, adapters para clientes antiguos, EDIE/NOTA y renderers históricos.
No quedan decisiones dispersas de formularios/contenido/PDF que reconstruyan behavior por código.

## 18. Backend y autorización

Cambios en modelos, schemas, creación, profiles, snapshot, catálogo administrativo, router y PDF.
Las cuatro reglas aprobadas permanecen:
- Comunicado: permiso específico.
- Informe: permiso específico.
- Memorándum: permiso específico + JEFE o superior.
- Circular: permiso específico + DIRECTOR o superior.

Hoja de Ruta utiliza el permiso existente correspondence.create y contexto institucional activo.
Ese permiso no permite crear los cuatro documentos anteriores.
SUPERADMIN y la evaluación central de permisos conservan sus reglas existentes.
Los tipos personalizados siguen sin habilitar creación automáticamente.

La administración muestra behavior y ofrece un selector del enum.
Backend devuelve behavior_locked para tipos estructurales o ya utilizados.
Sus cambios peligrosos se rechazan; un tipo personalizado sin uso admite edición.
El backend es la autoridad final de esta protección.

## 19. Flutter

Cambios en contrato API/Repository, modelos de presentación y mappers,
formulario y Cubit/state, origen, campos de emisión, detalle y catálogo administrativo.
Componentes de contenido compartidos para los cuatro tipos conservados;
la selección y validación se hacen mediante el enum recibido.

## 20. Pruebas

Pruebas nuevas:
- Enum válido/inválido, round trip y GENERIC explícito.
- DTO, mapper, emisión y selección de formulario por behavior con código ajeno.
- Hoja completa con funcionario y con nombre libre.
- Origen vacío/doble y contenido/fecha/hora/hojas inválidos.
- Permiso de Hoja independiente de los otros cuatro permisos.
- Origen de jerarquía superior no autoriza al actor.
- Snapshot/PDF estable tras cambios de datos maestros.
- Protección administrativa y edición de behavior.
- Migraciones en base nueva, k1 y k1 con históricos sintéticos.

Suites completas conservadas: reglas de jerarquía, capabilities, visibilidad,
EDIE/NOTA históricos, movimientos, reportes, adjuntos y PDF.

## 21. Resultados

| Validación | Resultado |
|---|---|
| Backend pytest tests/ | 599 aprobadas, 0 fallidas |
| Flutter test | 590 aprobadas, 0 fallidas |
| correspondencia_api | 63 aprobadas |
| correspondencia_repository | 49 aprobadas |
| failures | 6 aprobadas |
| flutter analyze | 0 errores, 0 warnings; 98 infos preexistentes |
| git diff --check | OK |
| Migración desde cero | OK, l1 |
| Upgrade desde k1 | OK, l1 |
| Históricos sintéticos | OK; tipos/IDs/documentos/movimientos/adjuntos/permisos conservados |
| PDF de muestra | Revisado visualmente |
| Archivos protegidos | 47 SHA-256 sin cambios |

Backend emite dos DeprecationWarning de dependencias (Starlette/AnyIO y ReportLab).
Analyzer conserva 98 infos del proyecto y por ello su comando devuelve código 1;
no se presenta como una ejecución sin diagnósticos.

Logs en `%TEMP%/sipe-document-behavior-20261028/`.
La validación backend final utiliza una base completamente nueva (behavior_verified).
Una ejecución diagnóstica sobre una base reutilizada detectó un fixture de código fijo duplicado;
se comprobó la suite completa sobre bases nuevas, sin borrar datos de la base habitual.

## 22. Límites y riesgos pendientes

- No se aplicó l1 a la base habitual ni al servidor.
- La base que se use para ejecutar esta versión deberá tener l1 antes de probar los campos nuevos.
- El repositorio conserva dos heads por la rama RR.HH. preexistente.
  Un futuro despliegue documental debe elegir su revisión explícita y revisar el estado real de su DB;
  no se ejecutó ni se propone ejecutar un upgrade ambiguo en la base habitual.
- Se mantiene compatibilidad temporal para clientes/payloads sin behavior; puede retirarse
  solamente cuando ya no existan consumidores antiguos.
- No se generaron snapshots retrospectivos ni datos de emisión ficticios.
- No se ejecutó una prueba interactiva contra QA Ubuntu ni se cambió su URL.
- RR.HH./biométrico, Website y h1/i1/j1/k1 permanecen intactos.
- Sin commit, staging, push, deploy, reset, rebase ni modificaciones de la base habitual.

## Estado Git final

```text
 M backend/app/modules/correspondence/correspondence.py
 M backend/app/modules/correspondence/document_creation_authorization.py
 M backend/app/modules/correspondence/document_snapshot.py
 M backend/app/modules/correspondence/document_type.py
 M backend/app/modules/correspondence/document_type_admin_service.py
 M backend/app/modules/correspondence/document_type_profiles.py
 M backend/app/modules/correspondence/pdf/operational_document_pdf.py
 M backend/app/modules/correspondence/router.py
 M backend/app/modules/correspondence/schemas.py
 M backend/app/modules/correspondence/service.py
 M backend/tests/conftest.py
 M backend/tests/test_chaining_catalog_code.py
 M backend/tests/test_phase2_operational_documents.py
 M backend/tests/visibility_helpers.py
 M lib/core/auth/permissions.dart
 M lib/features/administration/basic_data/document_types/list_document_types/tables/document_types_table.dart
 M lib/features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart
 M lib/features/administration/basic_data/document_types/upsert_document_types/helpers/upsert_document_types_inherited.dart
 M lib/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart
 M lib/features/correspondence/detail/widgets/correspondence_detail_header.dart
 M lib/features/correspondence/detail/widgets/correspondence_info_section.dart
 M lib/features/correspondence/domain/document_type_profiles.dart
 M lib/features/correspondence/domain/entities/correspondence_entity.dart
 M lib/features/correspondence/domain/mappers/correspondence_entity_mapper.dart
 M lib/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart
 M lib/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_state.dart
 M lib/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart
 M lib/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart
 M lib/features/correspondence/upsert_correspondence/widgets/origin_section.dart
 M packages/correspondencia_api/lib/correspondencia_api.dart
 M packages/correspondencia_api/lib/src/features/correspondence/api/correspondence_api.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/correspondence_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/create_correspondence_request.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_admin_response.dart
 M packages/correspondencia_api/lib/src/features/correspondence/models/document_type_response.dart
 M packages/correspondencia_repository/lib/correspondencia_repository.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/correspondence.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/create_correspondence_input.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/entities/document_type_admin.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/correspondence_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/mappers/document_type_admin_mapper.dart
 M packages/correspondencia_repository/lib/src/features/correspondence/repository/correspondence_repository.dart
 M test/features/correspondence/phase2_creation_test.dart
?? backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py
?? backend/app/modules/correspondence/document_behavior.py
?? backend/app/modules/correspondence/pdf/document_renderer.py
?? backend/app/modules/correspondence/pdf/route_sheet_pdf.py
?? backend/app/modules/correspondence/route_sheet_policy.py
?? backend/tests/test_document_behavior.py
?? backend/tests/test_document_behavior_migration.py
?? docs/DOCUMENT_BEHAVIOR_HARDCODES.md
?? docs/DOCUMENT_BEHAVIOR_PROTECTED_SHA256.json
?? docs/DOCUMENT_BEHAVIOR_REFACTOR.md
?? lib/features/correspondence/upsert_correspondence/widgets/route_sheet_fields.dart
?? packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart
?? packages/correspondencia_api/test/document_behavior_test.dart
?? packages/correspondencia_repository/test/document_behavior_test.dart
?? test/features/correspondence/document_behavior_test.dart
```
