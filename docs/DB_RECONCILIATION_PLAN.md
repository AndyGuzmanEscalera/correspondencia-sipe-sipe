# Base habitual: auditoría y plan de reconciliación

Fecha: 16/10/2026. **Plan propuesto, no ejecutado.** Este documento no habilita cambios sobre la base habitual.

## Evidencia read-only

Se consultó la base utilizada por `sipe_correspondencia_backend` con `SET TRANSACTION READ ONLY`. Se repitió la auditoría al terminar y coincidieron revisión, columnas, constraints/FKs, filas de turnos/segmentos, asignaciones y permisos. No hubo stamp, downgrade, DROP, reset, clean ni eliminación de volúmenes.

| Elemento | Hallazgo |
|---|---|
| alembic_version habitual | **a3b4c5d6e7f8** |
| Head actual del código develop | **g2b3c4d5e6f7**, única |
| work_shifts | **11 filas activas**, Turno 1 a Turno 11 |
| work_shift_segments | **14 filas**, con secuencias/horarios y cruces de medianoche |
| employees.work_shift_id | Columna física UUID nullable; **0 funcionarios asignados** |
| Permisos | master_data.work_shifts.read / master_data.work_shifts.manage |
| Asignaciones de esos permisos | ADMIN y MANAGER, según datos persistidos |
| Dependencias directas de Correspondencia hacia Turnos | Ninguna FK directa en tablas correspondence* |

El ORM Employee de develop no mapea work_shift_id. La columna física sigue existiendo en la base habitual; su FK apunta a work_shifts. Correspondencia usa employees/users/organizational_units, que son tablas compartidas: esto obliga a preservar su integridad al migrar datos.

Se inspeccionó la cabecera histórica con `git show feature/rrhh-turnos:backend/alembic/versions/a3b4c5d6e7f8_work_shifts.py`, sin checkout ni modificación de esa rama. Esa revisión declara down_revision **g2b3c4d5e6f7**. La migración histórica crea los artefactos de Turnos y seeds; no se restaura al release actual. La marca de Alembic por sí sola no demuestra equivalencia del esquema: hay que comparar el esquema completo sobre una copia representativa.

## Columnas físicas auditadas

| Tabla.columna | Tipo | Nullable |
|---|---|---|
| `employees.work_shift_id` | uuid | YES |
| `work_shift_segments.id` | uuid | NO |
| `work_shift_segments.work_shift_id` | uuid | NO |
| `work_shift_segments.sequence` | integer | NO |
| `work_shift_segments.start_time` | time without time zone | NO |
| `work_shift_segments.end_time` | time without time zone | NO |
| `work_shift_segments.ends_next_day` | boolean | NO |
| `work_shifts.id` | uuid | NO |
| `work_shifts.name` | character varying | NO |
| `work_shifts.description` | text | YES |
| `work_shifts.is_active` | boolean | NO |
| `work_shifts.created_by_user_id` | uuid | YES |
| `work_shifts.updated_by_user_id` | uuid | YES |
| `work_shifts.created_at` | timestamp with time zone | NO |
| `work_shifts.updated_at` | timestamp with time zone | NO |

## Constraints y FKs asociadas

- `ck_work_shift_segment_range`: `CHECK ((ends_next_day OR (end_time > start_time)))`.
- `ck_work_shift_segment_sequence`: `CHECK ((sequence > 0))`.
- `ck_work_shifts_name`: `CHECK ((length(TRIM(BOTH FROM name)) > 0))`.
- `fk_employees_work_shift_id`: `FOREIGN KEY (work_shift_id) REFERENCES work_shifts(id) ON DELETE RESTRICT`.
- `uq_work_shift_segment_sequence`: `UNIQUE (work_shift_id, sequence)`.
- `work_shift_segments_pkey`: `PRIMARY KEY (id)`.
- `work_shift_segments_work_shift_id_fkey`: `FOREIGN KEY (work_shift_id) REFERENCES work_shifts(id) ON DELETE RESTRICT`.
- `work_shifts_created_by_user_id_fkey`: `FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL`.
- `work_shifts_pkey`: `PRIMARY KEY (id)`.
- `work_shifts_updated_by_user_id_fkey`: `FOREIGN KEY (updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL`.

No se encontró una FK de Correspondencia hacia work_shifts o work_shift_segments. Las tablas correspondence* conservan dependencias con correspondences, document_types, employees, users y organizational_units; no se propone alterar esas relaciones.

## Datos persistidos que deben conservarse

Aunque no hay funcionarios asignados, **no son tablas vacías**. No se puede inferir que se puedan eliminar por ser WIP. Se preservan los 11 turnos, sus descripciones/auditoría y los 14 segmentos. Resumen de horarios leído, sin UUID ni datos personales:

| Turno | Secuencia | Inicio | Fin | Termina al día siguiente |
|---|---|---|---|---|
| Turno 1 | 1 | 08:00:00 | 12:00:00 | No |
| Turno 1 | 2 | 14:00:00 | 18:00:00 | No |
| Turno 2 | 1 | 04:00:00 | 08:00:00 | No |
| Turno 2 | 2 | 14:00:00 | 18:00:00 | No |
| Turno 3 | 1 | 04:00:00 | 12:00:00 | No |
| Turno 4 | 1 | 14:00:00 | 22:00:00 | No |
| Turno 5 | 1 | 07:00:00 | 16:00:00 | No |
| Turno 6 | 1 | 08:00:00 | 06:00:00 | Sí |
| Turno 7 | 1 | 20:00:00 | 08:00:00 | Sí |
| Turno 8 | 1 | 08:00:00 | 08:00:00 | Sí |
| Turno 9 | 1 | 08:00:00 | 18:00:00 | No |
| Turno 10 | 1 | 08:00:00 | 16:00:00 | No |
| Turno 11 | 1 | 08:00:00 | 12:00:00 | No |
| Turno 11 | 2 | 14:00:00 | 18:00:00 | No |

Las filas de permisos y sus asignaciones tampoco se eliminan automáticamente. El hecho de que nombres de roles aparezcan en esta auditoría describe datos históricos; no es una nueva regla de autorización runtime.

## Estrategia segura propuesta

**No se creó migration bridge.** La reconciliación queda pendiente de una decisión sobre el destino del histórico de Turnos y de pruebas sobre copia. Agregar un archivo vacío con la revisión antigua o cambiar la marca no demostraría equivalencia y ocultaría la divergencia.

1. Obtener y verificar un respaldo completo fuera del repositorio, incluyendo filas de Turnos, permisos, Alembic y archivos de adjuntos. Restaurarlo en una instancia aislada; validar recuentos y constraints antes de experimentar. Nada se ejecuta todavía sobre el original.
2. Comparar estructuralmente esa copia con una base nueva migrada desde cero a g2b3c4d5e6f7. Incluir settings, notificaciones, reportes, snapshots documentales, índices, constraints y grants; no limitarse a la tabla alembic_version.
3. Elegir destino con el responsable funcional:
   - **Preservar la base completa:** diseñar una reconciliación explícita que reconozca y verifique el estado legacy, mantenga todas las filas/columnas y permisos de Turnos y conserve Correspondencia. Su grafo Alembic debe poder explicar ambas procedencias, dejar una sola head legítima y no instalar Turnos en bases nuevas de Correspondencia. El diseño y la nueva revisión se revisan antes de aplicarlos.
   - **Usar una base limpia para Correspondencia:** la ruta desde cero a g2 ya está probada. Si se requiere información habitual, definir y probar una transferencia controlada de usuarios, organización, documentos/movimientos, adjuntos, settings y permisos de Correspondencia, con los identificadores y secuencias coherentes. Mantener la base legacy completa como respaldo/archivo; una DB nueva vacía por sí sola no migra esos datos.
   - **Retirar Turnos del esquema habitual:** requiere autorización explícita porque existen 25 filas. Antes de considerar cualquier retirada hay que acordar su archivo/recuperación y probar restauración. No está autorizado ni realizado en este lote.
4. En la copia elegida, comprobar trazabilidad de revisiones, una sola head, recuentos/IDs, contenido de adjuntos, login y permisos, CRUD de básicas, creación/derivación, PDF, notificaciones y reportes. Demostrar que el proceso es repetible y que el respaldo puede recuperarse.
5. Presentar resultado y plan de ventana/recuperación. Solo una autorización posterior permitiría ejecutar sobre la base habitual o el servidor. No utilizar stamp/downgrade como sustituto de esta validación.

**Estado actual:** la base habitual continúa en a3b4c5d6e7f8 y no puede recibir el upgrade ordinario del develop actual. No afirmar que es compatible con g2 por el solo hecho de que el backend responda. El código tiene una única head g2 y no depende de Turnos para una base nueva, demostrado con migración y smoke HTTP aislados.

## Validación ya realizada

Se crearon dos DB temporales, sin reutilizar volúmenes habituales: closure_qa para 396 pruebas backend y closure_smoke para upgrade desde cero y backend real. La segunda alcanzó g2, no contiene work_shifts ni employees.work_shift_id y respondió 200 en /health, /health/database, /auth/login, /auth/me y /admin/employees con una cuenta ficticia. Esto valida la instalación limpia, **no** la reconciliación del histórico.

No se modificaron Turnos/RR.HH. ni Website. No se accedió a Debian. Inventario y demás verificaciones en [cierre QA](QA_CLOSURE_20261016.md).
