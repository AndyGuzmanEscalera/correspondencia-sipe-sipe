# Integración biométrica RRHH

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
El worker debe desplegarse como servicio supervisado, con acceso de red al reloj y PostgreSQL.
Si no está activo, las solicitudes permanecen en estado `queued`; la API sigue respondiendo.
`--once` procesa como máximo una tarea y es útil para un planificador externo.

Con Docker Compose, después de agregar o cambiar dependencias reconstruir el servicio:

```powershell
docker compose up -d --build --no-deps backend
```

El Dockerfile debe copiar **ambos** archivos `requirements.txt` y
`requirements-biometric.txt` antes de ejecutar pip; el instalador aplica este ajuste.
El conector carga pyzk al usarse, de modo que su ausencia produce un error controlado
en RRHH y no impide arrancar autenticación, salud ni el resto de módulos.
Si Flutter muestra un error XMLHttpRequest con sugerencia CORS, comprobar primero
`GET /health`: una conexión sin respuesta también produce ese mensaje del navegador.
Las pruebas de arranque `python -m pytest tests_startup -q` simulan pyzk ausente
y verifican salud, preflight con credenciales y refresh sin cookie (401 normal), sin DB.

Copiar las claves de `.env.biometric.example` al entorno del backend y completar IP,
clave de comunicación y un `device_id` estable. No copiar `.env` del ZIP.
La configuración conserva las validaciones del lector: IPv4, puerto válido, clave numérica,
timeout por operación hasta 300 segundos, transporte `auto|tcp|udp`, encoding válido.
La clave no figura en modelos persistentes, respuestas ni mensajes de error.
No activar SQLAlchemy `echo` con entradas sensibles ni trazas locales de pyzk en producción.

Los endpoints utilizan el Bearer token y `require_permission` existentes:

FastAPI registra el prefijo interno `/rrhh`. El Apache existente publica `/api/`
y lo retira al reenviar a FastAPI, de modo que las rutas públicas son `/api/rrhh/...`.
En desarrollo directo usar `http://localhost:8000/rrhh/...`, igual que `/auth` y `/admin`.

| Método y ruta bajo `/api/rrhh` | Permiso | Comportamiento |
| --- | --- | --- |
| GET `/biometric/status` | `rrhh.read` | Consulta breve del dispositivo; no descarga marcaciones ni expone IP/clave |
| GET `/biometric/users` | `rrhh.read` | Identificador, UID y nombre; sin contraseña, tarjeta ni plantillas |
| POST `/biometric/sync` | `rrhh.manage` | Fechas obligatorias; devuelve 202 con tarea persistente |
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

El rango máximo es 367 días inclusivos. **Cada sincronización explícita descarga todo
el histórico**: el equipo no ofrece filtrado remoto confirmado. Se persiste todo, incluso
lo que queda fuera del rango solicitado, para evitar nuevas descargas por otras pantallas.
Abrir marcaciones, consultar funcionarios o generar una preparación nunca inicia una descarga.
No hay actualización automática por cada apertura ni temporizador de descargas repetidas.
La frescura depende de la última sincronización solicitada por un usuario autorizado.

## Concurrencia, fallos y deduplicación

Una cola PostgreSQL conserva solicitudes tras reinicios. Un índice parcial único impide
dos tareas `queued/running` del mismo dispositivo. Otro bloqueo, advisory de sesión por
IP/puerto, serializa el acceso físico entre procesos API y workers. Las consultas de estado
y usuarios reciben 409 si el equipo está ocupado. PostgreSQL debe conectarse directamente
o mediante pooling de sesión; el pooling transaccional de PgBouncer no admite este contrato.
No cambiar IP/device_id mientras exista una tarea activa; las tareas se atienden con la
configuración vigente del worker y debe ser idéntica a la de la API.

Si el worker cae, la conexión libera el bloqueo. La siguiente ejecución marca la tarea
`running` huérfana como fallida, sin descargar automáticamente otra vez. El usuario puede
solicitar una nueva tarea. No se descartan registros descargados por una sincronización
exitosa anterior. Una descarga incompleta o un lote inválido revierte todos los nuevos
registros y registra un error seguro en la tarea. No se devuelven excepciones originales.

Se reutiliza `Reader`, su guardia de comandos `_BoundedZK`, limpieza de sockets,
fallback TCP/UDP y `attendance_record`. `record_id` conserva exactamente el SHA-256 de
JSON compacto `[device_id,user_id,timestamp,status,punch]`, con Unicode original.
`uid` no participa. PostgreSQL usa UNIQUE + `ON CONFLICT DO NOTHING` en lotes de 1.000.
API y archivo normalizado usan la misma función y la misma tabla. `source` indica la
primera fuente que incorporó la marca; una segunda fuente idéntica no cambia ese valor.
Dos eventos indistinguibles en esos cinco campos y el mismo segundo se colapsan,
limitación heredada y documentada del identificador del lector.

La descarga completa se mantiene en memoria por el contrato actual de pyzk/Reader;
no se presenta como streaming ni descarga incremental. Los timestamps del dispositivo
son locales, sin zona (`TIMESTAMP WITHOUT TIME ZONE`), con precisión de segundos.
Solo los tiempos operativos de las tareas usan UTC. Los filtros incluyen ambos días
mediante límites `[inicio 00:00, día siguiente al fin 00:00)`.

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
sus tablas. Nunca apuntarla a la base compartida. Usa mocks y sockets de loopback, nunca
el equipo físico ni `.env` del ZIP. Incluye las pruebas originales adaptadas solo en sus
imports, más PostgreSQL real para deduplicación, fuentes, vínculos, fechas, seguridad,
parámetros, atomicidad, concurrencia, recuperación de tareas y períodos.

El monitor y SQLite originales se conservan como referencia; producción usa el worker
y PostgreSQL. La CLI `main.py` no se convierte en router ni se ejecuta desde HTTP.
La guardia del lector depende de detalles privados de `pyzk==0.9`; no actualizar sin
revisar la lista de comandos y repetir las pruebas de solo lectura.
