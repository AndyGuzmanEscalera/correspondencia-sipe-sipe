# Verificación de integración — 19 de octubre de 2026

## Corrección de arranque — 22 de octubre de 2026

El contenedor existente no tenía `pyzk`; el import del módulo RRHH impedía arrancar
toda la aplicación (`ModuleNotFoundError: zk`). El navegador lo mostraba como
connectionError con sugerencia CORS. Además, el Dockerfile no copiaba el archivo
incluido `requirements-biometric.txt` antes de ejecutar pip.

Se corrigió el instalador para actualizar ese COPY, se cargó pyzk de forma diferida
y se reconstruyó únicamente el servicio backend mediante Docker Compose.
El conector ausente ahora devuelve `biometric_dependency_missing` (503) al solicitarlo,
sin impedir arrancar los módulos compartidos. Los seis módulos originales del lector
no se alteraron.

Validaciones adicionales:

- Dos pruebas de regresión en `tests_startup/test_optional_biometric_dependency.py`
  aprobadas, simulando pyzk ausente sin conectar base de datos ni hardware.
- Contenedor reconstruido: inicio completo de Uvicorn, `GET /health` → 200.
- `OPTIONS /auth/refresh` desde `http://localhost:5000` → 200 con credenciales CORS.
- `POST /auth/refresh` sin cookie → 401 con cabeceras CORS, respuesta esperada.
- `pip check` dentro del contenedor: sin incompatibilidades.

No se aplicaron migraciones ni se consultó el reloj durante esta corrección.
El resultado de las suites completas del 19 de octubre se conserva a continuación;
en esta corrección se ejecutaron las dos pruebas nuevas y las comprobaciones HTTP.

## Resultado

- Backend compartido: `C:/dev/correspondencia_sipe_sipe/backend`.
- Python usado para validación: 3.13.14; FastAPI 0.115.6, SQLAlchemy 2.0.36,
  Pydantic 2.10.3, psycopg 3.2.3, pyzk 0.9.
- PostgreSQL 18 temporal, exclusivamente loopback `127.0.0.1:55439`.
- Suite nueva instalada: **61 aprobadas**, incluidas las 13 originales del lector.
- Suite existente de Correspondencia: **409 aprobadas** sobre base temporal migrada.
- Flutter: `flutter analyze --no-pub` sin problemas; **117 pruebas aprobadas**.
- `compileall` del módulo y las pruebas: correcto.
- OpenAPI: diez rutas RRHH (once operaciones), prefijo interno `/rrhh`.
- Alembic: una sola revisión final `h1b2c3d4e5f6`.
- Toda la cadena Alembic desde una base vacía hasta esa revisión: correcta.
- Prueba adicional de subida/bajada de la nueva migración en esquema aislado: correcta.
- `pip check` con las dependencias aisladas: sin incompatibilidades.

Las primeras 29 incidencias de la suite existente ocurrieron sobre una base creada
solo con metadata ORM: faltaban semillas y un índice administrados por migraciones.
La repetición con la cadena Alembic completa pasó las 409 pruebas, sin modificar
las pruebas ni el código funcional existente de Correspondencia.
Persisten avisos de deprecación de dependencias (AnyIO/Starlette y ReportLab con Python 3.13).

No se consultó el dispositivo físico. Los sockets usados en las pruebas del lector
son exclusivamente de loopback con respuestas sintéticas. No se aplicó ninguna migración,
semilla, parámetro ni cambio de datos a la base compartida de producción.
El PostgreSQL temporal se detuvo al terminar la validación.

## Archivos creados e instalados en el backend compartido

- `app/modules/rrhh/__init__.py`
- `app/modules/rrhh/biometric_service.py`
- `app/modules/rrhh/errors.py`
- `app/modules/rrhh/models.py`
- `app/modules/rrhh/schemas.py`
- `app/modules/rrhh/storage.py`
- `app/modules/rrhh/worker.py`
- `app/modules/rrhh/router.py`
- `app/modules/rrhh/periods.py`
- `app/modules/rrhh/reader/{__init__,config,connection,records,storage,monitor}.py`
  (copias exactas de los módulos del ZIP).
- `alembic/versions/h1b2c3d4e5f6_rrhh_biometric.py`
- `tests_rrhh/{__init__,conftest,test_reader,test_integration,test_migration}.py`
- `requirements-biometric.txt`, `.env.biometric.example`, `README_BIOMETRIC.md`.

La misma extensión se conserva en `rrhh_sipe_sipe/backend/`, junto con
`scripts/install_rrhh.py` y este informe, para revisión y reinstalación idempotente.
El instalador no inicia procesos ni ejecuta migraciones.

## Archivos existentes modificados

En el backend compartido:

- `app/main.py`: registra el router RRHH.
- `alembic/env.py`: registra la metadata RRHH.
- `requirements.txt`: incluye `requirements-biometric.txt`.

En el proyecto Flutter:

- `README.md`: enlace a la extensión y distinción de notas históricas.
- `.gitignore`: excluye dependencias, cachés Python y PostgreSQL temporal de pruebas.

No se modificaron widgets, parsers TXT/DAT, autenticación ni modelos compartidos.
No se copiaron credenciales del ZIP ni se modificó su contenido.

## Alcance pendiente

La API y la persistencia están implementadas. La puesta en servicio requiere instalar
dependencias en el entorno del backend, aplicar Alembic, completar BIOMETRIC_* y supervisar
el worker separado. No se ejecutaron esos pasos sobre el servicio desplegado.

No se verificó el esquema/datos de una base de producción accesible: se inspeccionaron
ORM y migraciones vigentes, y se validaron contra PostgreSQL temporal. En ellos no hay
turnos/horarios ni asignación contractual; hace falta identificar su fuente institucional.
La generación devuelve pendientes explícitos, no asistencia inventada. Falta confirmar
identificadores biométricos, contratos/cortes, turnos, códigos crudos y cobertura histórica.
El guardado desde la pantalla TXT/DAT espera confirmar el mapeo de sus columnas a códigos;
su endpoint normalizado ya comparte persistencia y deduplicación con SOURCE_API.

Riesgos documentados: descarga completa de varios minutos y consumo de memoria heredado;
dependencia de internals de pyzk 0.9; posibles eventos indistinguibles en el mismo segundo;
reloj sin zona horaria; necesidad de worker supervisado y pooling PostgreSQL de sesión;
una descarga exitosa no demuestra exhaustividad histórica del equipo.
