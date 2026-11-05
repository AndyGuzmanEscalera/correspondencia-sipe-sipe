# Auditoría de hardcodes documentales

Fecha: 2026-10-28. Alcance: backend/app (excluido RR.HH.), migraciones, lib y paquetes API/Repository.
Se inspeccionaron las coincidencias de EDIE, INFORME, NOTA, MEMORANDUM, CIRCULAR, COMUNICADO, HOJA_RUTA y CHAINING.

- A: identidad estable, enum, contrato de autorización, backfill o texto de presentación.
- B: decisión de formularios/contenido/PDF que debe depender de behavior. No quedan decisiones de esta categoría en producción.
- C: migraciones históricas inmutables, adapters de compatibilidad y renderers legacy necesarios.

Las comparaciones por código en document_creation_authorization.py y la protección administrativa verifican identidad estructural, permiso y jerarquía; no seleccionan formularios ni renderers.
Las decisiones por enum no son hardcodes de identidad documental.
El fallback por código de Flutter solo actúa si el payload no contiene behavior. GENERIC explícito es autoritativo.

## Inventario exacto

| Archivo:línea | Categoría | Uso restante | Código |
|---|---|---|---|
| backend/alembic/versions/c4d8e1f2a9b0_create_correspondence_module.py:22 | C | Migración histórica inmutable; no se modifica. | `("a1000001-0001-4001-8001-000000000002", "INFORME", "Informe"),` |
| backend/alembic/versions/c4d8e1f2a9b0_create_correspondence_module.py:23 | C | Migración histórica inmutable; no se modifica. | `("a1000001-0001-4001-8001-000000000003", "MEMORANDUM", "Memorándum"),` |
| backend/alembic/versions/c4d8e1f2a9b0_create_correspondence_module.py:24 | C | Migración histórica inmutable; no se modifica. | `("a1000001-0001-4001-8001-000000000004", "CIRCULAR", "Circular"),` |
| backend/alembic/versions/c4d8e1f2a9b0_create_correspondence_module.py:26 | C | Migración histórica inmutable; no se modifica. | `("a1000001-0001-4001-8001-000000000006", "NOTA", "Nota"),` |
| backend/alembic/versions/d0e1f2a3b4c5_authority_snapshot.py:1 | C | Migración histórica inmutable; no se modifica. | `"""Freeze EDIE authority data independently of future settings/master-data edits.` |
| backend/alembic/versions/d0e1f2a3b4c5_authority_snapshot.py:41 | C | Migración histórica inmutable; no se modifica. | `AND upper(trim(dt.code)) IN ('EDIE', 'S')` |
| backend/alembic/versions/f3a4b5c6d7e8_correspondence_document_origin.py:73 | C | Migración histórica inmutable; no se modifica. | `WHERE code = 'INFORME'` |
| backend/alembic/versions/f3a4b5c6d7e8_correspondence_document_origin.py:80 | C | Migración histórica inmutable; no se modifica. | `WHERE code = 'NOTA'` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:15 | C | Migración histórica inmutable; no se modifica. | `"COMUNICADO_INTERNO",` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:21 | C | Migración histórica inmutable; no se modifica. | `("INFORME", "Informe", "REPORT", "report", None),` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:22 | C | Migración histórica inmutable; no se modifica. | `("MEMORANDUM", "Memorándum", "MEMORANDUM", "memorandum", "JEFE"),` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:23 | C | Migración histórica inmutable; no se modifica. | `("CIRCULAR", "Circular", "CIRCULAR", "circular", "DIRECTOR"),` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:113 | C | Migración histórica inmutable; no se modifica. | `WHERE UPPER(TRIM(code)) NOT IN ('COMUNICADO_INTERNO','INFORME','MEMORANDUM','CIRCULAR')"""` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:118 | C | Migración histórica inmutable; no se modifica. | `"""UPDATE document_types SET profile='LEGACY_CHAINING'` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:119 | C | Migración histórica inmutable; no se modifica. | `WHERE UPPER(TRIM(code)) IN ('EDIE','S','ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS')"""` |
| backend/alembic/versions/j1b2c3d4e5f6_operational_document_types.py:124 | C | Migración histórica inmutable; no se modifica. | `"UPDATE document_types SET profile='LEGACY_INTERNAL_NOTE' WHERE UPPER(TRIM(code))='NOTA'"` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:17 | A | Backfill por código estable en l1. | `"HOJA_RUTA": "ROUTE_SHEET",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:18 | A | Backfill por código estable en l1. | `"COMUNICADO_INTERNO": "INTERNAL_COMMUNICATION",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:19 | A | Backfill por código estable en l1. | `"INFORME": "REPORT",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:20 | A | Backfill por código estable en l1. | `"MEMORANDUM": "MEMORANDUM",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:21 | A | Backfill por código estable en l1. | `"CIRCULAR": "CIRCULAR",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:22 | A | Backfill por código estable en l1. | `"EDIE": "LEGACY_CHAINING",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:23 | A | Backfill por código estable en l1. | `"S": "LEGACY_CHAINING",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:24 | A | Backfill por código estable en l1. | `"ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS": "LEGACY_CHAINING",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:25 | A | Backfill por código estable en l1. | `"NOTA": "LEGACY_INTERNAL_NOTE",` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:42 | A | Backfill por código estable en l1. | `VALUES (:id,'HOJA_RUTA','Hoja de Ruta','ROUTE_SHEET',TRUE,TRUE,'correspondence.create')` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:45 | A | Backfill por código estable en l1. | `{"id": uuid.uuid5(uuid.NAMESPACE_URL, "gam-sipe-sipe/document/HOJA_RUTA")},` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:47 | A | Backfill por código estable en l1. | `# An existing HOJA_RUTA retains its identity/name and adopts the same` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:53 | A | Backfill por código estable en l1. | `minimum_hierarchy_id=NULL WHERE UPPER(TRIM(code))='HOJA_RUTA'"""` |
| backend/alembic/versions/l1b2c3d4e5f6_document_behavior.py:59 | A | Backfill por código estable en l1. | `"profile IN ('ROUTE_SHEET','INTERNAL_COMMUNICATION','REPORT','MEMORANDUM','CIRCULAR','GENERIC','LEGACY_CHAINING','LEGACY_INTERNAL_NOTE')",` |
| backend/app/modules/correspondence/constants.py:31 | C | Renderer/valor/ruta legacy conservado para históricos. | `ATTACHMENT_SOURCE_GENERATED_CHAINING = "GENERATED_CHAINING"` |
| backend/app/modules/correspondence/correspondence_attachment.py:16 | C | Renderer/valor/ruta legacy conservado para históricos. | `UPLOADED vs GENERATED_CHAINING (sin columna en DB todavía).` |
| backend/app/modules/correspondence/document_behavior.py:10 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `MEMORANDUM = "MEMORANDUM"` |
| backend/app/modules/correspondence/document_behavior.py:11 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `CIRCULAR = "CIRCULAR"` |
| backend/app/modules/correspondence/document_behavior.py:13 | C | Renderer/valor/ruta legacy conservado para históricos. | `LEGACY_CHAINING = "LEGACY_CHAINING"` |
| backend/app/modules/correspondence/document_behavior.py:17 | C | Renderer/valor/ruta legacy conservado para históricos. | `CHAINING = "LEGACY_CHAINING"` |
| backend/app/modules/correspondence/document_behavior.py:23 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `"HOJA_RUTA": DocumentBehavior.ROUTE_SHEET,` |
| backend/app/modules/correspondence/document_behavior.py:24 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `"COMUNICADO_INTERNO": DocumentBehavior.INTERNAL_COMMUNICATION,` |
| backend/app/modules/correspondence/document_behavior.py:25 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `"INFORME": DocumentBehavior.REPORT,` |
| backend/app/modules/correspondence/document_behavior.py:26 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"MEMORANDUM": DocumentBehavior.MEMORANDUM,` |
| backend/app/modules/correspondence/document_behavior.py:27 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"CIRCULAR": DocumentBehavior.CIRCULAR,` |
| backend/app/modules/correspondence/document_behavior.py:28 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `"EDIE": DocumentBehavior.LEGACY_CHAINING,` |
| backend/app/modules/correspondence/document_behavior.py:29 | C | Renderer/valor/ruta legacy conservado para históricos. | `"S": DocumentBehavior.LEGACY_CHAINING,` |
| backend/app/modules/correspondence/document_behavior.py:30 | C | Renderer/valor/ruta legacy conservado para históricos. | `"ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS": DocumentBehavior.LEGACY_CHAINING,` |
| backend/app/modules/correspondence/document_behavior.py:31 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `"NOTA": DocumentBehavior.LEGACY_INTERNAL_NOTE,` |
| backend/app/modules/correspondence/document_type_profiles.py:13 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"COMUNICADO_INTERNO": (` |
| backend/app/modules/correspondence/document_type_profiles.py:19 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"INFORME": (` |
| backend/app/modules/correspondence/document_type_profiles.py:25 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"MEMORANDUM": (` |
| backend/app/modules/correspondence/document_type_profiles.py:27 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.MEMORANDUM,` |
| backend/app/modules/correspondence/document_type_profiles.py:31 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"CIRCULAR": (` |
| backend/app/modules/correspondence/document_type_profiles.py:33 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.CIRCULAR,` |
| backend/app/modules/correspondence/document_type_profiles.py:40 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"HOJA_RUTA": (` |
| backend/app/modules/correspondence/document_type_profiles.py:61 | C | Renderer/valor/ruta legacy conservado para históricos. | `return legacy_behavior(code) == DocumentBehavior.LEGACY_CHAINING` |
| backend/app/modules/correspondence/document_type_profiles.py:68 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.MEMORANDUM,` |
| backend/app/modules/correspondence/document_type_profiles.py:69 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.CIRCULAR,` |
| backend/app/modules/correspondence/institutional_mayor.py:52 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"""EDIE usa to_user_id: requiere funcionario, cargo, unidad y cuenta activos."""` |
| backend/app/modules/correspondence/pdf/document_renderer.py:13 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.MEMORANDUM: generate_operational_document_pdf,` |
| backend/app/modules/correspondence/pdf/document_renderer.py:14 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.CIRCULAR: generate_operational_document_pdf,` |
| backend/app/modules/correspondence/pdf/encadenamiento_pdf.py:1 | C | Renderer/valor/ruta legacy conservado para históricos. | `"""Physical EDIE form, Legal portrait; rendering never changes routing data."""` |
| backend/app/modules/correspondence/service.py:407 | C | Renderer/valor/ruta legacy conservado para históricos. | `in {DocumentBehavior.ROUTE_SHEET, DocumentBehavior.LEGACY_CHAINING}` |
| backend/app/modules/correspondence/service.py:412 | C | Renderer/valor/ruta legacy conservado para históricos. | `if profile in {DocumentBehavior.ROUTE_SHEET, DocumentBehavior.LEGACY_CHAINING}:` |
| backend/app/modules/correspondence/service.py:680 | C | Renderer/valor/ruta legacy conservado para históricos. | `if behavior_of(doc_type) != DocumentBehavior.LEGACY_CHAINING:` |
| backend/app/modules/correspondence/service.py:1066 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `"Debe configurar al Alcalde/Máxima Autoridad Ejecutiva antes de registrar documentos EDIE."` |
| backend/app/modules/correspondence/service.py:1171 | C | Renderer/valor/ruta legacy conservado para históricos. | `if profile == DocumentBehavior.LEGACY_CHAINING:` |
| backend/app/modules/correspondence/service.py:1251 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.MEMORANDUM,` |
| backend/app/modules/correspondence/service.py:1252 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `DocumentBehavior.CIRCULAR,` |
| backend/app/modules/correspondence/service.py:1261 | C | Renderer/valor/ruta legacy conservado para históricos. | `if profile in {DocumentBehavior.ROUTE_SHEET, DocumentBehavior.LEGACY_CHAINING}:` |
| backend/app/modules/system/schemas.py:56 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `description="Texto de la máxima autoridad para documentos nuevos; no cambia el funcionario destinatario EDIE. Vacío elimina el texto personalizado.",` |
| lib/features/administration/configuration/views/configuration_page.dart:267 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `'Este texto es necesario para registrar nuevos documentos EDIE. Los documentos históricos conservan su texto original.'),` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:6 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `memorandum('MEMORANDUM', 'Memorándum'),` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:7 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `circular('CIRCULAR', 'Circular'),` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:9 | C | Renderer/valor/ruta legacy conservado para históricos. | `legacyChaining('LEGACY_CHAINING', 'Encadenamiento histórico'),` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:28 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `'HOJA_RUTA': routeSheet,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:29 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `'COMUNICADO_INTERNO': internalCommunication,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:30 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `'INFORME': report,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:31 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `'MEMORANDUM': memorandum,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:32 | A | Enum o comparación explícita de DocumentBehavior; identidad/contrato estructural o texto visible. | `'CIRCULAR': circular,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:33 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `'EDIE': legacyChaining,` |
| packages/correspondencia_api/lib/src/features/correspondence/models/document_behavior.dart:36 | C | Adaptador único para integraciones/payloads antiguos sin behavior; nunca sustituye un behavior explícito. | `'NOTA': legacyInternalNote,` |
