# Motor de evaluación y hoja individual — 27 de octubre de 2026

La integración Flutter agrega `GET /rrhh/attendance/contracts` y
`GET /rrhh/biometric/syncs/latest`, ambas protegidas con `rrhh.read`.
El catálogo procede de `AttendanceSource.contracts(db)`; por defecto está vacío con
dependencias pendientes. El resumen general agrega `status` semántico calculado
por servidor y `shifts`, para que el cliente no reconstruya reglas de clasificación.

Implementación del módulo RRHH existente, en `C:/dev/correspondencia_sipe_sipe/backend`.
No cambia el lector, worker, deduplicación, importador, tablas originales ni autenticación.
No agrega tablas o migraciones. La evaluación se calcula bajo demanda; no persiste
interpretaciones que dupliquen o reemplacen las marcaciones originales.

## Archivos y separación

- `evaluation_models.py`: contratos inmutables Pydantic de entradas, incidencias,
  resultados diarios, calendario, resumen, reporte y generación.
- `evaluation.py`: motor puro, sin SQL, red, pyzk ni escrituras.
- `attendance_repository.py`: lectura de funcionarios/unidades/cargos, parámetros,
  políticas y marcas desde las tablas existentes.
- `attendance_source.py`: interfaz para población contractual, período confirmado,
  horarios diarios históricos, ventanas de asociación y cobertura.
- `shift_source.py`: lectura opcional de las tablas reales de turnos y adaptación explícita.
- `attendance_service.py`: orquestación común a generación y reporte individual.
- `router.py`: mantiene los endpoints existentes; delega `generate` y agrega el reporte.
- `tests_evaluation/`: pruebas puras del motor, adaptadores y orquestación.
- `tests_rrhh/test_attendance_reports.py`: HTTP, permisos, PostgreSQL e inmutabilidad.
- `scripts/install_attendance_evaluation.py`: instala solo esta etapa, sin ejecutar
  migraciones, seeds, consultas al dispositivo ni reiniciar servicios.

## Hallazgos reales de turnos y dependencias pendientes

El ORM de `employees` sigue sin mapear contratos ni turno. **La base local sí contiene**:

| Relación/campo | Significado estructural verificado |
| --- | --- |
| `employees.work_shift_id` | UUID nullable, FK a `work_shifts.id` |
| `work_shifts.id/name/is_active` | Identidad, nombre y estado del turno |
| `work_shift_segments.work_shift_id` | FK al turno existente |
| `work_shift_segments.sequence` | Orden de segmentos |
| `start_time`, `end_time` | Horas locales de cada segmento |
| `ends_next_day` | Indicador de cruce de medianoche |

Se verificaron solo nombres, tipos y claves mediante inspección de la base local;
no se consultaron marcaciones ni datos personales para desarrollar el algoritmo.
Esos artefactos pertenecen al trabajo histórico de Turnos, separado del ORM vigente.
Se revisaron también `docs/DB_RECONCILIATION_PLAN.md` y
`docs/AUTHORIZATION_RRHH_SEPARATION.md` del repositorio compartido.

`ExistingShiftReader` reutiliza esas tablas sin registrar modelos duplicados en
`Base.metadata`, sin crearlas y sin reactivar migraciones/semillas históricas.
Inspecciona su existencia antes de consultarlas: instalaciones limpias sin Turnos
siguen siendo compatibles. El reporte incluye `current_shift` cuando hay asignación;
su alcance se etiqueta `current_unversioned`. **No demuestra una asignación histórica.**

Falta confirmar:

- catálogo y nombres reales de contratos y vínculo de cada funcionario con ellos;
- semántica contractual exacta de los cortes (mes nominal, inclusividad y vigencia);
- vigencia histórica del turno por funcionario;
- días laborables, descansos, feriados y excepciones;
- roles de entrada/salida de cada segmento y ventanas razonables para asociar marcas;
- tratamiento de los turnos `ends_next_day=true` y asignación de marcas al día laboral;
- certificación de cobertura histórica por funcionario/día.

`schedule_from_shift` convierte los segmentos reales en eventos solo cuando el adaptador
recibe explícitamente el día, los roles de sesión y las ventanas. No contiene horas
laborales predeterminadas ni adivina fines de semana. Rechaza turnos nocturnos hasta
confirmar su política; no los recorta ni convierte en turnos diurnos.

## Conectar una fuente institucional confirmada

Implementar `AttendanceSource.resolve_period(...)` y `load(...)` y registrar esa fuente
mediante la dependencia existente `get_attendance_source`. La configuración de la fuente
es del servidor; el cliente no envía horarios arbitrarios para sustituir el turno real.

`load` devuelve `WorkforceData` con población contractual, nombre/ID del contrato,
horarios diarios, cobertura opcional y dependencias pendientes. Debe obtenerlos de fuentes
institucionales confirmadas, utilizando `ExistingShiftReader` cuando corresponda.
`employee_ids=None` significa fuente faltante; `employee_ids=()` significa población
vacía confirmada. No se presentan ambos casos como un reporte exitoso vacío.

La fuente predeterminada indica pendientes. El `cutoff_day` almacenado no basta para
confirmar una regla contractual. Se conserva el período provisional del endpoint anterior
para compatibilidad, con `period_confirmed=false`; **no se usa para buscar ni evaluar
marcas**. La evaluación empieza cuando el adaptador devuelve un período confirmado.
El tipo `EvaluationPeriod` usa `[start_date, end_exclusive)` y limita a 367 días.

## Reglas implementadas

Los seis parámetros usan exactamente los campos PostgreSQL existentes y la unidad
**segundos**. No se modificó su estructura ni se agregaron valores de producción.

### Entrada y retorno

```text
atraso_segundos = max(0, marca - hora_esperada - tolerancia_entrada)
```

Llegar temprano, a la hora o en el límite de tolerancia es NORMAL. El atraso empieza
después del límite. Con 08:00 y 300 segundos: 08:05 → 0; 08:06 → 60; 08:10 → 300.
La segunda entrada usa `afternoon_entry_tolerance` y genera `LATE_RETURN` si corresponde.
No se usa distancia absoluta para penalizar entradas tempranas.

### Salida

```text
tiempo_bruto_anterior = max(0, hora_esperada - marca)
```

Salir a la hora o más tarde es NORMAL; salir antes genera EARLY_EXIT. No se penaliza
permanecer más tiempo ni se computan horas extra sin su política.

El usuario confirmó que **la política de tolerancia de salida queda pendiente**.
Se devuelve `gross_early_exit_seconds/minutes` como diferencia temporal bruta.
Si hay salida anticipada y tolerancia configurada mayor que cero, `early_exit_seconds`
y `early_exit_minutes` quedan null, con `exit_tolerance_policy_pending=true`.
Con tolerancia cero, ambas interpretaciones coinciden y el tiempo computable es el bruto;
con salida a la hora o posterior, ambas dan cero. No se aplica un descuento no confirmado.

Se conservan segundos exactos. Minutos = segundos / 60, sin truncamiento ni redondeo
sancionatorio. No hay equivalencia implícita entre null y cero.

### Asociación temporal

El horario admite una o dos sesiones, hasta cuatro eventos principales. Cada evento
requiere ventana local explícita. El motor usa el orden temporal y todas las asociaciones
cronológicas de máxima cobertura, con programación dinámica `O(eventos × marcas)`.
No fuerza una marca a un evento solo por ser primera/segunda/tercera/cuarta.
No fuerza una ganadora por cercanía si varias asociaciones siguen siendo posibles.
Una marca no se asigna a dos eventos. Las asociaciones ambiguas producen
INCONSISTENT_SEQUENCE, horas principales null y candidatos conservados.

Los códigos crudos `status`/`punch` no determinan entrada, salida ni verificación.
Solo su igualdad, junto con dispositivo/identificador, se usa como señal conservadora
de compatibilidad para una posible repetición. Cambiar los códigos no cambia las reglas
de atraso ni salida anticipada.

### Posibles duplicados

Se detectan grupos con span desde la primera marca menor o igual a `duplicate_window`,
misma identidad/códigos y mismas ventanas candidatas. No se encadenan indefinidamente
grupos 18:10→18:14→18:18 cuando la ventana total permitida es cinco minutos.
Un cambio entre ventanas de eventos distintos evita confundir la pausa con repetición.

POSSIBLE_DUPLICATE es una observación. Todas las marcas permanecen en `original_records`.
La marca principal opcional aparece únicamente en `suggestions.suggested_record_id`;
no se copia al campo de hora principal ni modifica la evidencia. Cuando todas las
candidatas producen exactamente la misma métrica, puede devolverse esa métrica segura;
en otro caso queda null. No se cuentan multas ni atrasos basados en una elección arbitraria.

### Faltantes, extras e intervalos intermedios

- Evento sin una marca asociable: MISSING_MARK, sin justificación ni ausencia automática.
- Una marca adicional sin rol principal: EXTRA_MARK informativo; cinco marcas por sí
  solas no hacen que un día normal se vuelva anómalo.
- Exactamente dos marcas adicionales no agrupadas, entre entrada y salida principales
  inequívocas: posible INTERMEDIATE_EXIT, con horas aproximadas y duración para revisión.
  No se reconstruyen pares alternando automáticamente todas las marcas adicionales.
- Ejemplo 07:55, 11:03, 17:05, 18:02, con ventanas que excluyen las dos horas intermedias:
  faltan los dos eventos centrales y existe una sugerencia de intervalo de 6 h 02 min.
- Si no puede reconstruirse una secuencia única: INCONSISTENT_SEQUENCE. Nunca se afirma
  permiso, comisión, abandono o existencia de hoja de salida.
- La pausa confirmada salida primera sesión→entrada segunda sesión se compara con
  `minimum_return_interval`. Un intervalo inferior genera MINIMUM_BREAK_VIOLATION;
  el límite exacto cumple. Esta regla es independiente de duplicados. También puede
  advertirse sobre un intervalo intermedio sugerido, identificado como hipótesis.

## Estados y valores incompletos

| Estado | Significado |
| --- | --- |
| NORMAL | Eventos principales coherentes, sin incidencias de observación/anomalía; extras informativos posibles |
| OBSERVATION | Atraso, salida anticipada o posible repetición no crítica |
| ANOMALY | Faltantes parciales, ambigüedad, intervalo intermedio o pausa incompatible |
| NO_DATA | Cero marcas, horario/parámetros faltantes, cobertura explícitamente inválida o día sin sesión esperada |

Con cero marcas se indican eventos faltantes, pero el estado es NO_DATA y **no significa
ausencia**. Con marcas parciales y horario conocido se describen las anomalías observables.
La cobertura desconocida no impide interpretar marcas presentes; no certifica exhaustividad.
`coverage=false` impide penalizar el día incluso si se conservan marcas en su respuesta.
Un día sin trabajo solo se reconoce cuando el adaptador entrega explícitamente cero eventos.

Métricas incompletas son null. `observed_late_seconds` y
`observed_gross_early_exit_seconds` conservan las partes conocidas sin presentarlas como
totales completos. El resumen tiene `totals_complete`; la cobertura desconocida también
impide certificarlo. Ausencia, minutos no evaluables y horas extra quedan null mientras
no existan políticas confirmadas. `reconstruction_complete` se refiere a asociación de
marcas, no a descuentos ni certeza de cobertura.

## API y reporte individual

Rutas internas FastAPI `/rrhh/...`; detrás del Apache existente se publican `/api/rrhh/...`.
Reutilizan `rrhh.read` y la resolución de permisos central. No hay otro login.

```text
POST /api/rrhh/attendance/generate
{"contract_type_id":"UUID","year":2026,"month":10}

GET /api/rrhh/attendance/employees/{employee_id}/report
    ?contract_type_id=UUID&year=2026&month=10
```

`generate` devuelve `GenerationResult`: período y confirmación, dependencias pendientes,
cobertura, cantidad contractual confirmada y resumen por funcionario. No devuelve todos
los detalles de cada marca en la lista general. Una población contractual que referencia
un funcionario inexistente o mezcla contratos produce error controlado.

`report` devuelve `IndividualReport`:

- `employee`: ID, nombre, documento, unidad, cargo y contrato confirmado.
  `item_code` queda null: no existe un campo confirmado de ítem del funcionario;
  no se confunde con `position_code`.
- `current_shift`: asignación física actual, si existe, etiquetada como no versionada.
- `shifts`: turnos usados por los días evaluados, incluyendo variación durante el período.
- `period`, `period_confirmed`, `engine_version`, copia de parámetros y su `updated_at`.
- `days`: una fila por día del período confirmado, horario, originales, eventos,
  cuatro horas principales opcionales, métricas, estado, incidencias y sugerencias.
- `summary`: días evaluados/normales/observados/anómalos/sin datos, minutos y segundos,
  cantidades de marcas/incidencias y banderas de completitud.
- `calendar`: fecha, estado semántico, cantidad de marcas, primera/última y número
  de incidencias. Flutter aplica los colores; el backend no define colores.
- `pending_configuration` y `pending_policies`: dependencias o políticas sin confirmar.

Cada incidencia tiene tipo, severidad, descripción, segundos/minutos opcionales,
IDs de marcas relacionadas, evento y sugerencia opcional. `INTERMEDIATE_EXIT` mantiene
la etiqueta de posibilidad y `requires_review=true`.

Las marcas están incluidas dentro de sus días como `original_records`, conservando
record_id, timestamp, códigos, UID y fuente. No se duplican otra vez en una lista plana.
El reporte solo consulta el funcionario y período solicitado, con límite superior
exclusivo. No incluye funcionarios ajenos al contrato confirmado ni marcas no vinculadas.

## Reproducibilidad, rendimiento y límites de producción

El motor es determinista para los mismos parámetros, horarios, registros y cobertura.
No persiste análisis ni crea tablas redundantes. El reporte devuelve la versión del motor,
los parámetros y los horarios/IDs originales necesarios para inspeccionar su resultado.
Cambiar parámetros o incorporar marcaciones nuevas recalcula el resultado al solicitarlo.
Los registros originales, su hash, sus códigos y su fuente no se actualizan.

Generación carga cabeceras y marcas por lotes para la población del contrato; no hace una
consulta por funcionario y día. El reporte individual no lee las marcas de todo el contrato.
El trabajo corre en las funciones síncronas de FastAPI, fuera del event loop, sin red al reloj.
La carga del resultado sigue creciendo con funcionarios y marcas del período. Antes de
reportes masivos institucionales conviene medir memoria/latencia y definir paginación o jobs
de evaluación si el volumen real lo requiere. No se publicitan límites de rendimiento no medidos.

No se garantiza snapshot transaccional de auditoría entre cambios concurrentes de configuración,
turnos y registros. Si se necesita aprobar/cerrar períodos o conservar resultados legales,
acordar una generación versionada, snapshot consistente y trazabilidad de política antes
de persistirla. No usar estas interpretaciones preliminares para descuentos automáticos.

El árbol local combina dos heads existentes: `h1` RRHH y `k1` Correspondencia, ambos
descendientes de `g2`. Esa separación es intencional según la documentación actual del
repositorio. Esta etapa **no** crea merges, cambia revisiones ni aplica migraciones reales.
No ejecutar `alembic upgrade head` a ciegas sobre el árbol mixto. La validación aislada
aplica explícitamente las dos revisiones a su base temporal, sin alterar su genealogía.

Pruebas y resultados: ver `VERIFICACION_ATTENDANCE.md`.
