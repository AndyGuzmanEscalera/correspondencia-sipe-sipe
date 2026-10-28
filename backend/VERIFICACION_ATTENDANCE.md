# Verificación del motor de asistencia — 27 de octubre de 2026

## Cambios y alcance

Se agregaron seis módulos a `app/modules/rrhh/`: `evaluation_models.py`, `evaluation.py`,
`attendance_source.py`, `attendance_repository.py`, `attendance_service.py` y `shift_source.py`.
Se modificó únicamente `router.py` dentro del código funcional existente: delega `generate`
y agrega `GET /rrhh/attendance/employees/{employee_id}/report`, con `rrhh.read` existente.
Las fuentes revisables se conservan también en `rrhh_sipe_sipe/backend/`.

Se agregaron `tests_evaluation/{__init__,conftest,test_engine,test_service,test_shift_adapter}.py`,
`tests_rrhh/test_attendance_reports.py`, `scripts/install_attendance_evaluation.py` y
`README_ATTENDANCE_EVALUATION.md`. Se actualizaron README general, README biométrico,
instalador general de la extensión y exclusiones de herramientas temporales en `.gitignore`.

No hay migraciones nuevas, tablas de análisis, empleados/turnos duplicados, PDF ni cambios
Flutter. No se modificaron el lector, la política de solo lectura, almacenamiento,
worker, parámetros persistidos, autenticación o código de Correspondencia.
Las marcaciones originales no se actualizaron ni eliminaron.

## Inspección previa

Se revisaron todo el módulo RRHH, modelos, esquemas, router, worker, almacenamiento,
políticas de corte, parámetros, migración h1 y modelos actuales de funcionarios/unidades/cargos.
La inspección de solo metadatos de PostgreSQL local confirmó:

- `work_shifts` y `work_shift_segments` existen aunque no aparecen en el ORM vigente;
- `employees.work_shift_id` existe físicamente y referencia el turno;
- segmentos: `sequence`, `start_time`, `end_time`, `ends_next_day`;
- no se identificó un catálogo/asignación contractual confirmado.

Se reutilizan los turnos mediante un lector de esas tablas exactas. No se activa el
WIP histórico ni se crean modelos con tablas duplicadas. Una asignación actual se
etiqueta `current_unversioned`; no se presume su vigencia para períodos históricos.

## Pruebas ejecutadas

Entorno: Windows, Python 3.13.14, PostgreSQL 18 temporal en 127.0.0.1:55439,
FastAPI 0.115.6, SQLAlchemy 2.0.36, Pydantic 2.10.3, psycopg 3.2.3 y pyzk 0.9.

| Comprobación | Resultado |
| --- | --- |
| Motor, modelos y adaptador de turnos sin DB (`tests_evaluation`) | 46 aprobadas |
| RRHH existente + reportes HTTP/PostgreSQL (`tests_rrhh`) | 69 aprobadas |
| Arranque sin pyzk (`tests_startup`) | 2 aprobadas |
| Ejecución conjunta de esas tres suites | **117 aprobadas** |
| Suite existente de Correspondencia | 554 aprobadas en primera ejecución; los 7 casos restantes aprobaron en repetición aislada |
| `compileall` de módulo, motor y pruebas | Correcto |
| OpenAPI | Correcto, 11 rutas RRHH; respuestas tipadas IndividualReport y GenerationResult |
| `git diff --check` | Correcto |

Los siete casos existentes necesitaron corregir únicamente el entorno de pruebas:
cinco escriben archivos PDF en `/tmp` (se preparó `C:/tmp`); otro lanza un subproceso
del Python embebido que no heredaba los imports de dependencias aisladas (se usó una
copia del runtime dentro del workspace); el séptimo chocó aleatoriamente con un código
de fixture de seis caracteres. **Los siete aprobaron sin modificar código ni tests
de Correspondencia.** Los 561 casos existentes quedaron verificados entre ambas ejecuciones;
no se presenta esto como una única ejecución de 561 casos sin incidencias iniciales.

Las pruebas nuevas verifican: entradas tempranas y exactas, límites de tolerancia,
segundos sin redondeo, salidas tardías normales, salidas anticipadas con política pendiente,
retornos, cuatro marcas normales, duplicados sin eliminar y sin encadenamiento ilimitado,
independencia de códigos crudos, extras informativos, intervalos intermedios, pausas mínimas,
faltantes, ambigüedades, ausencia de datos/cobertura, parámetros distintos, calendario,
resúmenes parciales y exclusión de marcas de otro funcionario o fuera del rango.
Una comprobación exhaustiva pequeña contrasta el algoritmo de asociaciones con todas
las asignaciones cronológicas de máxima cobertura posibles.

Las pruebas HTTP comparan todas las columnas de evidencia relevantes antes/después de
generar y consultar el reporte, y verifican que ningún BiometricService fue invocado.
Un cambio de parámetros recalcula las métricas sin cambiar timestamps, códigos, hashes,
UID, fuentes ni vínculos de las marcaciones originales.

## Aislamiento de datos y migraciones

No se consultó el reloj físico ni se aplicaron migraciones a la base compartida.
Los tests del lector usan exclusivamente mocks y sockets de loopback. El PostgreSQL
temporal se detuvo después de la validación. Se utilizaron bases desechables nuevas:

- `rrhh_biometric_test_20261027`: fixtures RRHH con tablas ORM;
- `rrhh_biometric_regression_20261027`: migraciones existentes para Correspondencia.

El árbol local tiene dos heads preexistentes e intencionales: h1 (RRHH) y k1
(Correspondencia), ambas descendientes de g2. La primera preparación mediante `upgrade head`
detectó correctamente esa ambigüedad y no cambió nada. Tras revisar la documentación
de separación, se aplicaron explícitamente k1 y h1 **solo** en la base temporal.
No se alteró genealogía, no se creó merge ni se modificaron esas migraciones.
La prueba existente de subida/bajada de h1 también está incluida en las 69 pruebas RRHH.

## Decisiones funcionales y límites

- El análisis es reproducible bajo demanda, con `engine_version=1.0.0`, copia de parámetros,
  horarios y evidencia originales en la respuesta. No se persisten resultados redundantes.
- La política de tolerancia de salida quedó pendiente por respuesta explícita del usuario.
  Se informa diferencia bruta; el valor computable no se inventa cuando una tolerancia
  no nula permitiría interpretaciones diferentes.
- Los períodos existentes se muestran solo como provisionales hasta confirmación del
  adaptador. No se evalúa usando una semántica 25→25/30→30 no confirmada.
- Faltan contratos reales, vínculo contractual, calendario y asignación histórica del turno,
  ventanas de asociación y cobertura certificada. El adaptador por defecto mantiene
  `ready=false` con dependencias detalladas; un adaptador confirmado ya puede utilizar
  el motor completo, como demuestran las pruebas HTTP y de servicio.
- `ends_next_day` se conserva, pero el motor intradía exige resolver antes la política
  de turnos nocturnos. No se asigna silenciosamente el evento al día equivocado.
- Ausencias, justificaciones y horas extra no se infieren. NO_DATA no equivale a ausencia.
- Las horas ambiguas quedan null y los originales permanecen visibles. Los duplicados y
  las posibles salidas intermedias contienen sugerencias para revisión, nunca correcciones.
- Antes de producción: revisar contratos/turnos/cobertura, reconciliación del esquema local,
  consolidación de políticas y requisitos de auditoría/snapshot si se aprueban períodos.
  Medir latencia/memoria con la población real antes de generar reportes masivos.
