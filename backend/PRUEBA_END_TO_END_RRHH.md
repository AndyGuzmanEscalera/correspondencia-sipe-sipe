# Prueba end-to-end controlada de RRHH

Preparación de staging: Flutter → API Ubuntu autenticada → worker → biométrico → PostgreSQL → motor existente → listado/calendario/detalle/hoja. La implementación y las pruebas automatizadas no consultan el dispositivo real. La ejecución física queda a cargo del operador, después de completar los valores reales que se indican aquí. No hay resultados físicos que reportar todavía.

## 1. Requisitos y alcance

- Ubuntu con el backend compartido actualizado, Python y PostgreSQL compatibles con sus requirements; red privada del servidor al dispositivo. Navegador sin acceso directo al puerto biométrico.
- Instancia de API, worker, almacenamiento y **base separada descartable** de QA. No reutilizar el `.env`, la base ni el worker institucionales. La descarga existente recupera **todo el histórico de todos los usuarios**, aunque la evaluación se limite a 1–2 personas y 2–3 días. No es posible prometer una descarga física de solo tres días con este conector.
- Una cuenta de prueba de la autenticación existente, con `rrhh.read` y, para sincronizar/vincular/guardar parámetros, `rrhh.manage`. No se crean usuarios ni credenciales universales.
- Uno o dos funcionarios existentes en esa base, su identificador biométrico exacto (incluidos ceros), un turno activo real ya asignado y sus segmentos. Obtener los UUID con la administración existente; no usar los UUID ilustrativos del ejemplo.
- Operador confirma, exclusivamente para esta prueba, fechas, días laborables/no laborables, vigencia del turno en esas fechas, roles de las sesiones, ventanas y parámetros. No se deducen reglas de nombres ni de días de la semana.
- El esquema de staging debe contener las tablas compartidas y RRHH, además de las tablas opcionales reales `work_shifts`, `work_shift_segments` y `employees.work_shift_id`. Esta entrega no crea ni migra esas tablas opcionales.

El archivo temporal es una fuente de configuración, no un contrato guardado en SQL. Su única opción siempre se presenta como `[PRUEBA STAGING]`. Sin archivo se conserva la fuente pendiente y `ready=false`. No se modifica el evaluador ni se omiten sus comprobaciones. La cobertura sigue desconocida salvo evidencia independiente confirmada; `ready` expresa dependencias de evaluación, no completitud física de las marcas.

## 2. Variables y archivo temporal

Desde el checkout Flutter, instalar únicamente los cambios de esta entrega sobre el backend existente:

```bash
python3 backend/scripts/install_staging_support.py /srv/rrhh-staging/backend
cd /srv/rrhh-staging/backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.rrhh-staging.example .env
chmod 600 .env
sudo install -d -m 700 -o "$USER" /etc/rrhh-staging
install -m 600 staging/attendance.example.json /etc/rrhh-staging/attendance.json
```

Editar los dos archivos con valores reales de staging. No cargar `.env` con `source`: lo leen Pydantic/python-dotenv. API y worker deben tener el mismo directorio de trabajo y entorno.

| Variable | Valor/uso |
| --- | --- |
| `APP_ENV` | `qa`; el backend solo admite development/qa/production |
| `DATABASE_URL` | URL `postgresql+psycopg://...` de la base descartable; usuario/clave locales |
| `JWT_ACCESS_SECRET` | Secreto privado aleatorio de al menos 32 caracteres, distinto del institucional |
| `JWT_ISSUER`, `JWT_AUDIENCE` | Los mismos valores en API y worker; conservar convenciones existentes |
| `ACCESS_TOKEN_TTL_MINUTES`, `REFRESH_TOKEN_TTL_DAYS` | Vigencias existentes; ejemplo 15 y 7 |
| `COOKIE_NAME`, `COOKIE_PATH` | `refresh_token`, `/api/auth` si Apache publica `/api`; `/auth` si se accede directamente sin ese prefijo |
| `COOKIE_SECURE`, `COOKIE_SAMESITE` | `true`, `lax` para staging HTTPS del mismo origen |
| `CORS_ALLOW_ORIGINS` | Vacío con frontend/API del mismo origen; orígenes exactos si se sirve Flutter desde otro origen |
| `CORS_ALLOW_CREDENTIALS` | `true`; nunca combinar con origen `*` |
| `STORAGE_ROOT` | Directorio exclusivo de staging |
| `BIOMETRIC_IP` | IPv4 privada real accesible desde Ubuntu; no se incorpora al build Flutter |
| `BIOMETRIC_PORT` | Puerto real, normalmente 4370 |
| `BIOMETRIC_PASSWORD` | Clave de comunicación real, entero; usar 0 solo si el equipo está configurado sin clave |
| `BIOMETRIC_TIMEOUT` | Segundos, máximo 300; ejemplo 30 |
| `BIOMETRIC_TRANSPORT` | `auto`, `tcp` o `udp`, según conectividad real |
| `BIOMETRIC_ENCODING` | Codificación del dispositivo; ejemplo UTF-8 |
| `BIOMETRIC_DEVICE_ID` | Identificador estable del dispositivo; mismo valor en archivo temporal/API/worker |
| `BIOMETRIC_MATCH_DOCUMENT_NUMBER` | Mantener `false` |
| `RRHH_STAGING_CONFIG` | Ruta absoluta al JSON privado temporal |

El worker usa cola PostgreSQL y espera fija de 5 segundos cuando no procesa trabajo; `--once` procesa como máximo un trabajo. `BIOMETRIC_POLL_INTERVAL` corresponde al monitor original del lector y **no configura este worker**. No ejecutar ese monitor paralelo.

En `attendance.json`:

- `database_name` coincide exactamente con la base de `DATABASE_URL` y contiene un componente `qa`, `test` o `staging` separado por guiones bajos. El código rechaza una base distinta y `APP_ENV` distinto de QA.
- `purpose` es `controlled_rrhh_staging`; `contract_type_id` es un UUID reservado para esta configuración temporal, sin INSERT de contrato. Generarlo una vez con `.venv/bin/python -c 'import uuid; print(uuid.uuid4())'`.
- `year/month` corresponden al inicio del período; `start_date` incluido, `end_exclusive` excluido, distancia exactamente 2 o 3 días. En la petición de sincronización, `end_date` es el último día incluido.
- Sustituir `employee_id`, `biometric_user_id`, `shift_id` con valores existentes. Se admite hasta dos objetos. El lector verifica que la asignación actual sea activa y coincida con el turno configurado; el operador confirma su aplicación a las fechas de prueba.
- Declarar cada fecha en `working_days` con booleanos; `false` confirma un día no laborable, no una ausencia. Para turno de una sesión usar, por ejemplo, `[["morning_entry","final_exit"]]` y solo esas ventanas. Las horas esperadas se leen de los segmentos reales, nunca del ejemplo.
- Las ventanas del ejemplo son **ilustrativas**. Confirmarlas y adaptarlas al turno; si no incluyen sus horas esperadas, faltará `association_windows`. Los turnos nocturnos siguen pendientes.

El ejemplo no guarda ni modifica parámetros; usar la pantalla/API existente con los seis valores confirmados. Salida anticipada con tolerancia no nula mantiene su política pendiente, como se acordó. No fijar cero para ocultar esa decisión.

## 3. Chequeo previo de solo lectura desde Ubuntu

Con la base preparada y los archivos completos:

```bash
cd /srv/rrhh-staging/backend
.venv/bin/python -m app.modules.rrhh.staging_check preflight
```

**Este comando sí contacta el equipo cuando el operador lo ejecuta.** Adquiere el mismo bloqueo PostgreSQL por IP/puerto que API/worker, establece sesión y consulta modelo, serial, plataforma, firmware y cantidad de usuarios mediante contadores. No consulta la hora del reloj, ni usuarios completos, ni marcaciones; no descarga histórico y no desactiva, cambia hora, escribe ni borra. La política de comandos de solo lectura del lector se conserva. Un error devuelve código de salida 1 sin imprimir secretos; éxito devuelve JSON. Modelo/serial pueden depender del soporte del firmware.

No usar para esta comprobación el botón de estado de Flutter ni `GET /biometric/status`: la operación existente `info` también lee la hora. Ese comportamiento anterior no se ha cambiado.

## 4. Iniciar backend y comprobar esquema

Esta entrega no ejecuta migraciones. En el backend compartido hay ramas Alembic existentes; no ejecutar `upgrade head` ni fusionarlas a ciegas. El responsable de staging debe provisionar **la base vacía de QA** con las revisiones compatibles y tablas reales siguiendo el plan de reconciliación del backend. Verificar primero, sin modificar:

```bash
cd /srv/rrhh-staging/backend
.venv/bin/alembic heads
.venv/bin/alembic current
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8100
```

Publicar únicamente API por Apache HTTPS en `https://rrhh-staging.example.org/api/`, retirando `/api/` al reenviar a `http://127.0.0.1:8100/`, igual que el backend existente. Reemplazar ese dominio ilustrativo por el del servidor Ubuntu. No publicar 4370 ni credenciales biométricas. `/health` solo comprueba arranque; verificar también login y consultas reales de RRHH para comprobar el esquema/permisos.

## 5. Iniciar worker

En otra terminal, mismo directorio y `.env`:

```bash
cd /srv/rrhh-staging/backend
.venv/bin/python -m app.modules.rrhh.worker
```

Para ejecutar solo un trabajo en una terminal atendida, **después de encolarlo**, usar `.venv/bin/python -m app.modules.rrhh.worker --once`. No arrancar ambos modos para la prueba. El worker no toca hardware sin trabajo en cola. API/worker mantienen el índice único de trabajo activo por dispositivo y el bloqueo de sesión por IP/puerto; no se permite doble sincronización física entre estos procesos. Otros programas externos ajenos al backend deben permanecer sin consultar el equipo durante la prueba.

## 6. Autenticarse, vincular y sincronizar

Ejemplos Bash para Ubuntu con `curl` y `jq`. No poner contraseñas en argumentos ni guardar tokens en Git. Desactivar `set -x` antes de introducir credenciales. Login es el endpoint existente:

```bash
API='https://rrhh-staging.example.org/api'
read -r -p 'Usuario staging: ' LOGIN_USER
read -r -s -p 'Clave staging: ' LOGIN_PASSWORD; printf '\n'
TOKEN=$(printf '%s\n%s\n' "$LOGIN_USER" "$LOGIN_PASSWORD" |
  jq -Rn '[inputs] | {username:.[0],password:.[1]}' |
  curl --fail-with-body -sS "$API/auth/login" -H 'Content-Type: application/json' --data-binary @- |
  jq -er '.access_token')
unset LOGIN_PASSWORD
read -r -p 'BIOMETRIC_DEVICE_ID exacto: ' DEVICE
read -r -p 'user_id biométrico exacto: ' BIO_USER
read -r -p 'UUID funcionario de staging: ' EMPLOYEE
read -r -p 'Inicio incluido YYYY-MM-DD: ' START
read -r -p 'Fin incluido YYYY-MM-DD: ' END
DEVICE_PATH=$(printf '%s' "$DEVICE" | jq -sRr @uri)
USER_PATH=$(printf '%s' "$BIO_USER" | jq -sRr @uri)
```

El dispositivo debe estar registrado por una sincronización o estado anterior. El preflight es de solo lectura y no lo registra. En la primera prueba: sincronizar primero, comprobar que las marcas estén no vinculadas y luego vincular; se actualizan también las marcas ya descargadas.

**La siguiente llamada encola la descarga del histórico completo** y el worker la ejecutará. Usarla una vez que el operador autorice ese acceso:

```bash
JOB=$(jq -n --arg start "$START" --arg end "$END" '{start_date:$start,end_date:$end}' |
  curl --fail-with-body -sS "$API/rrhh/biometric/sync" -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' --data-binary @-)
printf '%s\n' "$JOB" | jq .
SYNC_ID=$(printf '%s' "$JOB" | jq -er '.id')
```

Con dispositivo ya registrado, crear el vínculo explícito existente (repetir solo para el segundo funcionario seleccionado):

```bash
jq -n --arg id "$EMPLOYEE" '{funcionario_id:$id}' |
  curl --fail-with-body -sS -X PUT "$API/rrhh/biometric/devices/$DEVICE_PATH/links/$USER_PATH" \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data-binary @- | jq .
```

Este PUT guarda un vínculo y actualiza las marcas de ese user_id **en staging**. No activa coincidencias por documento. Verificar cuidadosamente el identificador antes de usarlo.

## 7. Comprobar trabajo, vínculos y evidencia almacenada

```bash
curl --fail-with-body -sS "$API/rrhh/biometric/syncs/$SYNC_ID" -H "Authorization: Bearer $TOKEN" |
  jq '. + {duplicates_ignored: (if .status=="completed" then .downloaded_records-.new_records else null end)}'
```

Repetir esa consulta hasta `completed` o `failed`. Conservar id, created_at, started_at, finished_at, estado, downloaded_records, new_records, error_code, error_message. Duplicados ignorados = descargadas − nuevas **solo al completar**. Una descarga fallida no confirma cobertura. Un 409 significa que debe revisarse el trabajo activo, no reenviar en bucle. Tras caída del worker, reiniciarlo permite marcar como interrumpido un trabajo sin propietario; revisar antes de solicitar otro.

Diagnóstico local, **sin consultar dispositivo**, con transacción SQL de solo lectura:

```bash
umask 077
.venv/bin/python -m app.modules.rrhh.staging_check inspect > rrhh-diagnostic.json
test -s rrhh-diagnostic.json && jq . rrhh-diagnostic.json
```

Contiene última sincronización de ese dispositivo, extremos reales en PostgreSQL, rango por user_id, conteos por cada fecha (incluye ceros), fechas sin marcas, `linked`/`unlinked`/`linked_to_other_employee`, UUID vinculado y discrepancias de vínculo en registros. Incluye las marcas aun no vinculadas para comparación. Luego reutiliza `AttendanceService.report`, que solo evalúa marcas vinculadas al funcionario.

Extremos mínimo/máximo, sincronización completada o varios registros diarios **no prueban que falten cero marcas**. No inferir ausencia ni cobertura de períodos intermedios. El reporte conserva `biometric_coverage=unknown` con esta fuente. Los reportes del motor incluyen todos los dispositivos vinculados al funcionario conforme al comportamiento existente; el diagnóstico de user_id se limita al dispositivo configurado. Revisar si hay marcas de otro dispositivo en staging.

## 8. Parámetros, generar y obtener reporte

```bash
curl --fail-with-body -sS "$API/rrhh/attendance/parameters" -H "Authorization: Bearer $TOKEN" | jq .
curl --fail-with-body -sS "$API/rrhh/attendance/contracts" -H "Authorization: Bearer $TOKEN" | jq .
```

Guardar los seis valores confirmados desde Flutter con **Guardar parámetros**, o enviar un JSON completo en segundos a `PUT /rrhh/attendance/parameters`. No hay valores de tolerancia predeterminados para aprobar esta prueba. Para API, archivo privado `parameters.confirmed.json` con las claves `morning_entry_tolerance`, `morning_exit_tolerance`, `afternoon_entry_tolerance`, `afternoon_exit_tolerance`, `minimum_return_interval`, `duplicate_window`, cada una entre 0 y 86400:

```bash
curl --fail-with-body -sS -X PUT "$API/rrhh/attendance/parameters" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' --data-binary @parameters.confirmed.json | jq .
CONTRACT=$(jq -r '.contract_type_id' /etc/rrhh-staging/attendance.json)
YEAR=$(jq -r '.year' /etc/rrhh-staging/attendance.json)
MONTH=$(jq -r '.month' /etc/rrhh-staging/attendance.json)
jq -n --arg id "$CONTRACT" --argjson year "$YEAR" --argjson month "$MONTH" \
  '{contract_type_id:$id,year:$year,month:$month}' |
  curl --fail-with-body -sS "$API/rrhh/attendance/generate" -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' --data-binary @- | jq .
curl --fail-with-body -sS --get "$API/rrhh/attendance/employees/$EMPLOYEE/report" \
  -H "Authorization: Bearer $TOKEN" --data-urlencode "contract_type_id=$CONTRACT" \
  --data-urlencode "year=$YEAR" --data-urlencode "month=$MONTH" | jq .
```

Si falta turno real/configuración/parámetros, revisar `pending_configuration` y conservar `ready=false`. No cambiarlo manualmente. Las políticas de ausencia, horas extras y tolerancia de salida siguen pendientes: `pending_policies` y campos `null` hacen explícitos esos límites.

## 9. Flutter contra Ubuntu

El proyecto ya admite `API_BASE_URL`; no hay mocks de ejecución ni modificaciones de rutas para staging.

Recomendado: compilar y servir en el **mismo origen HTTPS** que `/api`, copiando `build/web` al virtualhost exclusivo de staging:

```bash
flutter pub get
flutter build web --dart-define=API_BASE_URL=/api
```

Para abrir el build local contra Ubuntu con URL absoluta:

```bash
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=https://rrhh-staging.example.org/api
```

Ese segundo modo necesita `CORS_ALLOW_ORIGINS=http://localhost:5000`, credenciales habilitadas y, si el navegador considera la cookie entre sitios, `COOKIE_SAMESITE=none` con `COOKIE_SECURE=true` sobre API HTTPS. Las políticas del navegador pueden bloquear cookies de terceros incluso con esa configuración; preferir mismo origen. No usar `APP_ENV=development` para un frontend remoto: su CORS permite solo loopback. El dominio del comando es ilustrativo, sustituirlo por Ubuntu real. No hardcodear la IP biométrica ni su puerto en Flutter.

Iniciar sesión normal → Asistencia Biométrica → seleccionar `[PRUEBA STAGING]` y el mes/año configurados → guardar parámetros confirmados → sincronizar y esperar (o revisar la ya ejecutada) → Generar → buscar funcionario → abrir detalle → Calendario → seleccionar día → Reporte. Generar no sincroniza y terminar la sincronización no genera automáticamente.

## 10. Comparación manual

Comparar `rrhh-diagnostic.json`, respuestas API, Flutter y la evidencia de solo lectura del equipo para **los mismos identificadores y fechas locales**. No convertir marcas originales a UTC.

Por funcionario verificar nombre/UUID, contrato temporal rotulado, turno real y segmentos, período incluido/excluido, marcas obtenidas, días evaluados, normales, observaciones, anomalías y minutos de atraso del `summary`. Por día verificar segundos originales, códigos status/punch sin interpretar, eventos asociados y candidatos, incidencias, sugerencias y estado. Calendario y hoja deben coincidir con el mismo reporte. Un guion/null no significa cero. Un día sin datos no significa falta. Las sugerencias no eliminan marcas.

Si se desea comprobar deduplicación, repetir explícitamente la sincronización **cuando la anterior haya terminado**. Con histórico inalterado, descargadas iguales, nuevas 0 y duplicados igual a descargadas. Si el reloj recibió nuevas marcas, comparar hashes y el incremento real; no exigir 0 nuevas. El test físico no se da por aprobado hasta contrastar estos resultados y registrar las dependencias que sigan pendientes.

## 11. Limpieza exclusiva de la prueba

No hay scripts DELETE/TRUNCATE ni limpiezas automáticas. Detener API y worker de staging (Ctrl+C si se iniciaron con los comandos anteriores). Retirar `RRHH_STAGING_CONFIG` y el archivo privado temporal; al reiniciar deja de aparecer el contrato de prueba, sin cambios SQL. Los vínculos/marcas/parámetros permanecen únicamente en la base descartable hasta que el administrador retire **esa instancia aislada completa**, después de verificar su nombre y guardar la evidencia necesaria. No aplicar esta limpieza sobre una base compartida. No limpiar el reloj.

Los diagnósticos contienen datos personales: conservarlos según el acceso del entorno de prueba; no incorporarlos a Git. Limpiar las variables de terminal con `unset TOKEN LOGIN_USER DEVICE BIO_USER EMPLOYEE JOB SYNC_ID` y cerrar la sesión. El archivo `.env` tampoco se versiona.

## 12. Problemas frecuentes y validaciones

| Síntoma | Comprobación |
| --- | --- |
| 401/403 | Token vigente y permisos RRHH existentes; no quitar autenticación |
| Configuración QA rechazada | APP_ENV, JSON válido, nombre exacto de base descartable, alcance 1–2 personas y 2–3 días |
| Catálogo vacío | RRHH_STAGING_CONFIG sin definir/no cargado; fuera de QA debe rechazarse si está definido |
| `employee_shift_source` | Tablas opcionales presentes, funcionario/turno reales, activo y UUID de asignación coincidente |
| `biometric_employee_link` | Falta el vínculo explícito del user_id configurado o apunta a otro funcionario |
| `association_windows` | Sesiones y ventanas incluyen horarios reales; turno nocturno sigue sin soporte confirmado |
| Error de esquema/Alembic | Revisar revisiones/plan de reconciliación en QA; no migrar producción ni crear tablas ficticias |
| Dependencia biométrica faltante | Instalar requirements incluidos y usar el mismo venv para API y worker |
| Timeout/conexión | Ruta privada Ubuntu→equipo, puerto/transporte y clave; no probar desde navegador |
| Cola no avanza | Worker activo en la misma base/dispositivo y directorio correcto |
| Sin marcas en reporte | Diagnóstico de user_id, vínculo explícito, fechas locales y discrepancias de registros |
| `ready=false` | Resolver dependencias listadas, no añadir bypass |
| Renovación de sesión/CORS | Origen exacto, HTTPS, Cookie Path con prefijo público y política de cookies |

Pruebas automatizadas: `tests_evaluation/test_staging.py` valida alcance, aislamiento, bloqueo fuera de QA y lista exacta de operaciones de preflight con conexión simulada. `tests_rrhh/test_staging_flow.py` recorre catálogo/generate/reporte autenticados con la fuente real de QA y PostgreSQL descartable, comprueba diagnóstico y falta de turno. Las simulaciones son fixtures de pruebas, no datos ni servicios usados en staging. Ejecutar junto a las suites RRHH/engine/startup existentes; requiere `RRHH_TEST_DATABASE_URL` con nombre `rrhh_biometric_test...`. Nunca apuntar esas suites a la base de staging con datos seleccionados: sus fixtures truncan exclusivamente la base de pruebas automatizadas.

```bash
export RRHH_TEST_DATABASE_URL='postgresql+psycopg://rrhh_test@127.0.0.1:55439/rrhh_biometric_test_20261027'
.venv/bin/python -m pytest tests_rrhh tests_evaluation tests_startup -q
```

Ese URL es un ejemplo de una **tercera base descartable para automatización**, no el valor de DATABASE_URL de la prueba física. No ejecutar los comandos de hardware en CI. Consultar el registro de validación de la entrega para los resultados ejecutados.

## Archivos de esta entrega

- Creados: `backend/app/modules/rrhh/staging_source.py`, `staging_check.py`; `backend/.env.example`; `backend/staging/attendance.example.json`; `backend/scripts/install_staging_support.py`; `backend/tests_evaluation/test_staging.py`; `backend/tests_rrhh/test_staging_flow.py`; este documento.
- Modificados: `attendance_source.py` (selección de fuente exclusiva de QA); `attendance_service.py` (acepta período explícito confirmado por la fuente sin crear política SQL); instaladores general y de evaluación (incluyen soporte QA); etiqueta de dependencia de vínculo en `lib/features/attendance/models/attendance_presentation.dart`; `.gitignore` y `README.md`.
- El instalador específico copia únicamente los cuatro módulos afectados, pruebas, ejemplo y documentación al backend compartido; su plantilla de entorno se llama `.env.rrhh-staging.example` allí para conservar el ejemplo propio del backend. Nunca reemplaza `.env` ni reinicia servicios.

## Validación ejecutada — 28 de octubre de 2026

- RRHH HTTP/PostgreSQL, motor/fuente QA y arranque sin conector: **135 pruebas aprobadas** en ejecución conjunta. Dos avisos de deprecación existentes (AnyIO y ReportLab).
- Flutter, paquetes API/repositorio/failures: **149 pruebas aprobadas**. `flutter analyze`: sin incidencias; formato del único archivo Dart modificado correcto.
- El CLI `inspect` se ejecutó como proceso independiente contra PostgreSQL descartable. El preflight se probó con una sesión simulada que rechaza cualquier método fuera de metadatos y contadores permitidos.
- Instalación selectiva realizada en el backend compartido autorizado; sin reiniciar sus servicios. No se accedió al biométrico real, no se aplicaron migraciones y no se eliminaron datos existentes. Los fixtures automatizados solo modificaron la base descartable identificada como `rrhh_biometric_test_20261027`.
- La prueba física completa queda pendiente de los valores reales del Ubuntu de staging, base, funcionarios/turnos, vínculos, fechas, ventanas y parámetros confirmados. No se declara completada por los resultados automatizados.
