# Integración biométrica RRHH

## Arquitectura vigente

```text
Flutter RRHH
    ↓  (endpoints /rrhh/... existentes)
Backend RRHH
    ↓  HTTPS + Bearer token
Biometric API  (https://biometric.sipesipe.gob.bo)
    ↓  Cloudflare Tunnel
Biometric Reader API
    ↓
Reloj biométrico real
```

El backend RRHH es el **único** consumidor de la Biometric API. Flutter no conoce el
dominio ni el token. La conexión directa `pyzk`/TCP 4370 ya no forma parte del camino
de ejecución; el código del lector se conserva solo como referencia y para pruebas de
protocolo en loopback. Las fuentes de persistencia son `SOURCE_API` y `SOURCE_FILE`.

La etapa del 27 de octubre agrega evaluación diaria reproducible y reporte individual:
ver [README_ATTENDANCE_EVALUATION.md](README_ATTENDANCE_EVALUATION.md). Su inspección física
confirma tablas históricas de turnos que no aparecen en el ORM vigente; no se duplican.

Destino: backend FastAPI compartido de `C:/dev/correspondencia_sipe_sipe/backend`.
Este directorio contiene una extensión instalable, **no un segundo servidor ni otro login**.
`scripts/install_rrhh.py` instala el módulo y registra su router y metadata en el backend.
Flutter mantiene su importador TXT/DAT y nunca abre conexiones al dispositivo.

## Puesta en marcha

Desde el backend compartido, con Python 3.11+ y su entorno virtual:

```powershell
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
# Otro proceso supervisado, en el mismo directorio y con las mismas variables:
python -m app.modules.rrhh.worker
```

La migración `h1b2c3d4e5f6` sucede a `g2b3c4d5e6f7`. No ejecuta consultas al reloj.
Para una instalación nueva hay que aplicar también las migraciones existentes del backend.
El worker debe desplegarse como servicio supervisado, con salida a Internet hacia la
Biometric API (o acceso al tunnel) y PostgreSQL. Ya no requiere LAN al reloj.
Si no está activo, las solicitudes permanecen en estado `queued`; la API sigue respondiendo.
`--once` procesa como máximo una tarea y es útil para un planificador externo.

Con Docker Compose, después de agregar o cambiar dependencias reconstruir el servicio:

```powershell
docker compose up -d --build --no-deps backend
```

El Dockerfile debe copiar **ambos** archivos `requirements.txt` y
`requirements-biometric.txt` antes de ejecutar pip; el instalador aplica este ajuste.
El cliente HTTPS (`httpx`) se carga al usarse: su ausencia produce
`biometric_dependency_missing` sin impedir arrancar autenticación, salud ni el resto.
Si Flutter muestra un error XMLHttpRequest con sugerencia CORS, comprobar primero
`GET /health`: una conexión sin respuesta también produce ese mensaje del navegador.
Las pruebas de arranque `python -m pytest tests_startup -q` simulan `httpx` ausente
y configuración API incompleta; verifican salud, preflight y refresh sin cookie (401), sin DB.

## Desarrollo local / QA

Copiar `.env.biometric.example` (o las claves equivalentes de `.env.example`) al `.env`
del backend compartido. Completar:

```env
BIOMETRIC_API_URL=https://biometric.sipesipe.gob.bo
BIOMETRIC_API_TOKEN=<token real local, nunca versionar>
BIOMETRIC_API_TIMEOUT=60
BIOMETRIC_DEVICE_ID=alcaldia-central
```

`BIOMETRIC_DEVICE_ID` debe coincidir con el `device_id` que informa la API; si difieren,
el `record_id` local no coincidiría con el histórico y reaparecerían duplicados.
El token no se imprime en logs ni se expone en respuestas. Desde esta PC se puede
desarrollar con datos reales vía HTTPS sin acceso LAN al reloj.

Prueba manual controlada (solo lectura, con token válido):

1. `GET /health` de la Biometric API
2. `GET /rrhh/biometric/status` y `GET /rrhh/biometric/users` del backend RRHH
3. Lectura de un rango pequeño o un CI concreto vía sincronización / cliente

No modificar el biométrico, no borrar datos, no ejecutar escritura remota.

Los endpoints utilizan el Bearer token y `require_permission` existentes:

FastAPI registra el prefijo interno `/rrhh`. El Apache existente publica `/api/`
y lo retira al reenviar a FastAPI, de modo que las rutas públicas son `/api/rrhh/...`.
En desarrollo directo usar `http://localhost:8000/rrhh/...`, igual que `/auth` y `/admin`.

| Método y ruta bajo `/api/rrhh` | Permiso | Comportamiento |
| --- | --- | --- |
| GET `/biometric/status` | `rrhh.read` | Distingue `api_available` y `device_connected`; no descarga marcaciones ni expone token |
| GET `/biometric/users` | `rrhh.read` | Identificador, UID y nombre; sin contraseña, tarjeta ni plantillas |
| POST `/biometric/sync` | `rrhh.manage` | Fechas obligatorias; descarga filtrada `from`/`to` vía API; 202 con tarea |
| GET `/biometric/syncs/{id}` | `rrhh.read` | Progreso y resultado de la tarea |
| POST `/biometric/import` | `rrhh.manage` | JSON normalizado procedente de TXT/DAT, máximo 10.000 registros por petición |
| PUT `/biometric/devices/{device_id}/links/{user_id}` | `rrhh.manage` | Vínculo explícito; actualiza también marcaciones históricas |
| GET `/biometric/records/summary` | `rrhh.read` | Fechas + device_id; vinculados, no vinculados e identificadores desconocidos |
| GET `/attendance/employees/{funcionario_id}/records` | `rrhh.read` | Fechas obligatorias; orden cronológico, limit/offset y total |
| GET `/attendance/parameters` | `rrhh.read` | Parámetros persistentes, unidad segundos |
| PUT `/attendance/parameters` | `rrhh.manage` | Sustitución completa de los seis valores, entre 0 y 86.400 |
| POST `/attendance/generate` | `rrhh.read` | Preparación explícitamente pendiente de contratos/turnos confirmados |

Los permisos nuevos se conceden a `ADMIN`. No se presupone que un ID de usuario 2 o
un rol MANAGER sea automáticamente RRHH: asignar `rrhh.read` y/o `rrhh.manage` al rol
autorizado mediante la administración compartida. Autenticación no equivale a autorización.
Quien obtiene `rrhh.read` tiene acceso al módulo completo de RRHH, incluidos todos los funcionarios.

Ejemplo de sincronización:

```json
{"start_date":"2026-09-25","end_date":"2026-10-24"}
```

El rango máximo es 367 días inclusivos. **Cada sincronización descarga solo el período
solicitado** mediante `GET /attendance?from=&to=` en la Biometric API (y `ci` si aplica).
La paginación del cliente usa `limit`/`offset` hasta cubrir `total`, con tope de páginas.
Abrir marcaciones, consultar funcionarios o generar una preparación nunca inicia una descarga.
No hay actualización automática por cada apertura ni temporizador de descargas repetidas.
La frescura depende de la última sincronización solicitada por un usuario autorizado.

## Concurrencia, fallos y deduplicación

Una cola PostgreSQL conserva solicitudes tras reinicios. Un índice parcial único impide
dos tareas `queued/running` del mismo dispositivo. Otro bloqueo, advisory de sesión por
URL de la Biometric API, serializa descargas entre procesos API y workers. Las consultas
de estado y usuarios reciben 409 si hay otra operación activa. PostgreSQL debe conectarse
directamente o mediante pooling de sesión; el pooling transaccional de PgBouncer no admite
este contrato. No cambiar `BIOMETRIC_API_URL`/`device_id` mientras exista una tarea activa;
API y worker deben compartir la misma configuración.

Si el worker cae, la conexión libera el bloqueo. La siguiente ejecución marca la tarea
`running` huérfana como fallida, sin descargar automáticamente otra vez. El usuario puede
solicitar una nueva tarea. No se descartan registros descargados por una sincronización
exitosa anterior. Una descarga incompleta o un lote inválido revierte todos los nuevos
registros y registra un error seguro en la tarea. No se devuelven excepciones originales.

La deduplicación **no** cambia al adoptar la Biometric API: se sigue calculando el
`record_id` local con SHA-256 de JSON compacto `[device_id,user_id,timestamp,status,punch]`
(`attendance_record`). El `record_id` externo de la API se ignora a propósito para no
duplicar el histórico ya persistido vía pyzk. `uid` no participa. PostgreSQL usa UNIQUE +
`ON CONFLICT DO NOTHING` en lotes de 1.000. `SOURCE_API` y `SOURCE_FILE` comparten la
misma función y tabla. `status`/`punch` se guardan crudos (p. ej. 15/25/1 y punch 255);
la interpretación de entrada/salida sigue en evaluación institucional.

El cliente HTTPS pagina en memoria el resultado filtrado del período; no descarga el
histórico completo del reloj. Los timestamps del dispositivo son locales, sin zona
(`TIMESTAMP WITHOUT TIME ZONE`), con precisión de segundos. Solo los tiempos operativos
de las tareas usan UTC. Los filtros de consulta RRHH incluyen ambos días mediante
límites `[inicio 00:00, día siguiente al fin 00:00)`.

Errores de la Biometric API: `401/403` → token/configuración; `502` → API reachable pero
dispositivo no; `504`/timeout HTTP → timeout; fallos DNS/Cloudflare/red → API unreachable.
La sincronización queda en `failed` sin persistir el lote.

## Funcionarios, turnos y contratos: hallazgos y pendientes

El modelo vigente revisado es `app/modules/organization/employee.py`: tabla `employees`,
UUID `id`, `document_number`, nombres, unidad y cargo. No es una tabla `funcionarios`
ni tiene un campo `ci`. El SQL histórico `database/schema/004_employees.sql` difiere del
ORM y no debe usarse como fuente vigente sin verificar la base desplegada.
No se inspeccionaron datos personales de la base de producción ni se afirma que su
esquema real haya sido verificado contra el ORM.

No existe un identificador biométrico confirmado en el modelo. Por defecto se utilizan
vínculos explícitos en `biometric_employee_links`, referenciando `employees.id`.
Una marca desconocida se conserva con `funcionario_id=null`; el resumen permite detectarla.
Solo tras confirmar equivalencia puede activarse `BIOMETRIC_MATCH_DOCUMENT_NUMBER=true`:
coincidencia textual exacta y única, sin quitar ceros, sufijos ni normalizar números.
Los vínculos explícitos prevalecen. El modo automático se aplica a nuevos registros;
el endpoint de vínculo permite corregir retrospectivamente registros existentes.

La revisión inicial de modelos/migraciones no encontró contratos ni turnos. La inspección
física del 27 de octubre confirmó `work_shifts`, `work_shift_segments` y
`employees.work_shift_id` en la base local; `ExistingShiftReader` ya reutiliza esas tablas.
Faltan calendario, vigencia histórica y ventanas de asociación; ver la documentación
de evaluación. No se crearon empleados ni turnos duplicados ni horarios artificiales.
Para contratos hace falta una migración posterior que relacione `employees` con el catálogo
institucional confirmado (o una asignación histórica con fechas de vigencia).
`attendance_contract_policies` prepara únicamente el nombre confirmado y día de corte;
no contiene tres contratos inventados y no sustituye ese catálogo institucional.

La política de períodos disponible es opcional y explícita: el mes/año nombra el mes del
corte, el inicio es el día posterior al corte anterior y el fin exclusivo es el día posterior
al corte actual. Días 29–31 se limitan al último día del mes. No se asigna esta política
a contratos reales hasta confirmar su significado; rangos consecutivos nunca se solapan.
Por defecto `generate` devuelve `ready=false`, período provisional no confirmado,
dependencias pendientes y cobertura `unknown`. Con un adaptador institucional confirmado
utiliza el nuevo motor y devuelve resúmenes reales. No presenta población desconocida
como un reporte exitoso vacío ni inventa cobertura.
Una descarga exitosa tampoco demuestra exhaustividad histórica: el reloj puede haber
rotado/borrado eventos previamente. Hay que acordar cómo certificar cobertura por período.

Los seis parámetros empiezan en null; no se usan valores arbitrarios de producción.
Se debe confirmar `status` y `punch`, zona/desfase del equipo, tres contratos y sus cortes,
horarios por funcionario y calendarios antes de implementar evaluación, descuentos o sanciones.
El código no interpreta entradas/salidas, alternancias, retornos ni métodos de verificación.

## Importación TXT/DAT

Se preserva íntegro el importador Flutter. El nuevo endpoint recibe la representación
normalizada: `device_id` y `records` con `user_id,timestamp,status,punch,uid`.
No se infiere qué columnas del archivo son status/punch/uid; debe confirmarse ese mapeo
antes de conectar el botón de guardado del importador. No se reinterpreta automáticamente
la configuración de análisis local ya existente en Flutter.

## Pruebas

```powershell
$env:RRHH_TEST_DATABASE_URL='postgresql+psycopg://test@127.0.0.1:55439/rrhh_biometric_test'
python -m pytest tests_rrhh -q
python -m compileall -q app/modules/rrhh tests_rrhh
python -m pip check
```

La suite exige una base desechable cuyo nombre contenga `rrhh_biometric_test` y vacía
sus tablas. Nunca apuntarla a la base compartida. El cliente HTTP se prueba con
`httpx.MockTransport`; nunca contra `https://biometric.sipesipe.gob.bo` en CI.
Incluye paginación, filtros, 401/502/timeout/red, deduplicación, worker, sync y
recuperación de tareas, además de evaluación y arranque.

El monitor/SQLite/`pyzk` originales se conservan bajo `reader/` como referencia retirada
del camino de ejecución. Producción usa el worker, PostgreSQL y `api_client`.
La CLI histórica del lector no se convierte en router ni se ejecuta desde HTTP.
