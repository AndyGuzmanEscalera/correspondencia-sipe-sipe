# PROJECT CONTEXT — Sistema de Correspondencia GAM Sipe Sipe

Actúa como ingeniero de software senior y arquitecto de software trabajando conmigo en este proyecto.

Quiero que continúes el desarrollo desde el estado actual del repositorio, no que empieces un proyecto nuevo.

# ESTADO ACTUAL — INFRAESTRUCTURA FLUTTER + AUTH (confirmado en repo)

Backend FastAPI con autenticación JWT + refresh HttpOnly cookie está operativo
en Docker (`backend` + `postgres`).

Flutter Web usa packages internos:

| Package | Rol |
|---------|-----|
| `packages/failures` | `Failure`, `Result`, `handleExceptions`, `AppLogger` |
| `packages/correspondencia_api` | `ApiMethod`, 2× Dio, `AuthApi`, interceptors |
| `packages/correspondencia_repository` | `AuthenticationRepository` |

**Auth Flutter (real, no mock):**

- Access token solo en memoria (`AuthTokenStore`).
- Refresh token en cookie HttpOnly (navegador; Flutter no lo lee).
- `refreshDio` → login / refresh / logout (sin interceptor de refresh).
- `mainDio` → Bearer + `AuthRefreshInterceptor` (401 → refresh → retry 1×).
- `AuthRefreshCoordinator` → single-flight refresh.
- Arranque: `main` → `bootstrap` → `AppView` → Splash → `restoreSession()`.
- `AppSessionCubit` (GetIt lazySingleton, `BlocProvider.value` en UI).
- Login / logout conectados al backend.
- Splash distingue: sin sesión (401 refresh) vs backend caído (Network/Timeout/Server).

**Features con backend real (API):**

- Autenticación, datos básicos (unidades, cargos, funcionarios, usuarios, tipos documentales).
- Correspondencia: listado, detalle, registro, derivación, movimientos, adjuntos.

**Features que siguen en mock (`LocalStore`):**

- Consulta pública, bandejas (inbox/recibidos/enviados/observados/archivados), empleados legacy UI, dashboard, reportes.

**Ownership operativo de correspondencia (Fase 0):**

- `current_unit_id` = unidad institucional responsable (obligatoria al crear/derivar).
- `current_user_id` = asignación personal opcional dentro de la unidad.
- El list item API expone IDs de unidad/usuario y `current_user_is_active`.
- Usuario destino inactivo no es seleccionable; trámites con responsable inactivo permanecen visibles por unidad.

**Rutas GoRouter:**

- `/` y `/correspondencia` → Splash
- `/consulta-publica` → consulta pública
- `/correspondencia/login` → login
- `/correspondencia/home` → panel admin (protegido)

GitHub Pages base-href: `/correspondencia-sipe-sipe/`

**Debug (solo kDebugMode):** `AuthTokenStore.debugInvalidateAccessToken()` invalida
el access token en memoria para probar el refresh automático sin esperar expiración JWT.

---

Antes de modificar código:

1. Inspecciona el repositorio actual.
2. Verifica qué archivos ya existen y su contenido.
3. No asumas que una recomendación previa ya fue aplicada.
4. No sobrescribas código útil sin necesidad.
5. Si encuentras diferencias entre este documento y el repositorio, considera al repositorio como la fuente de verdad y explícame la diferencia.
6. Trabaja paso a paso conmigo.
7. Antes de cambios grandes, explícame brevemente qué vas a hacer.
8. No sobrearquitectures el proyecto.

---

# 1. PROYECTO

Nombre conceptual:

Sistema de Gestión de Correspondencia y Documentos
Gobierno Autónomo Municipal de Sipe Sipe
Cochabamba, Bolivia

Repositorio/proyecto local:

C:\dev\correspondencia_sipe_sipe

Actualmente la raíz del proyecto ES un proyecto Flutter existente.

No mover Flutter a una carpeta `frontend/` por ahora.

Estructura aproximada actual:

correspondencia_sipe_sipe/
├── lib/
├── web/
├── test/
├── build/
├── database/
├── scripts/
├── backend/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── pubspec.yaml
├── pubspec.lock
└── README.md

El proyecto Flutter ya existía antes de iniciar el backend.

---

# 2. OBJETIVO DEL SISTEMA

No debe ser solamente un sistema de "hoja de ruta".

Debe evolucionar como un:

Sistema de Gestión de Correspondencia y Documentos

El concepto principal debe ser una correspondencia/trámite/documento institucional que puede pasar por varias unidades y funcionarios conservando trazabilidad completa.

Flujo conceptual:

Documento / Correspondencia
↓
Registro
↓
Código oficial / CITE / hoja de ruta
↓
Asignación
↓
Recepción
↓
Derivación
↓
Seguimiento
↓
Respuesta
↓
Conclusión
↓
Archivo

Debe ser posible saber:

- quién creó el trámite;
- quién lo recibió;
- cuándo lo recibió;
- quién lo derivó;
- hacia quién;
- desde qué unidad;
- hacia qué unidad;
- instrucciones;
- observaciones;
- fechas;
- estado actual;
- historial completo.

Nunca destruir el historial de movimientos para simplemente almacenar el estado actual.

---

# 3. PRINCIPIOS DEL PROYECTO

Este es un sistema institucional real.

Priorizar:

- estabilidad;
- mantenibilidad;
- seguridad;
- trazabilidad;
- auditoría;
- claridad del código;
- separación de responsabilidades;
- facilidad de soporte;
- evolución futura.

No utilizar microservicios en esta etapa.

Usar un MODULAR MONOLITH.

No introducir:

- Kafka;
- RabbitMQ;
- Kubernetes;
- Redis;
- MinIO;
- arquitecturas distribuidas;

salvo que aparezca una necesidad real posteriormente.

No agregar dependencias innecesarias.

---

# 4. STACK DEFINIDO

## Frontend

Flutter Web.

Flutter instalado actualmente:

Flutter 3.22.3
Dart 3.4.x

No actualizar Flutter automáticamente.

Arquitectura prevista:

Feature-first

Estado:

flutter_bloc / Cubit

HTTP:

Dio

Routing:

GoRouter

Flujo recomendado:

UI
↓
Cubit
↓
Repository
↓
API Client
↓
REST API

No realizar HTTP directamente desde Widgets.

Código:

inglés.

Textos de UI:

español.

El frontend debe ser desktop-first, pero responsive para poder usar ciertas funciones desde celular, especialmente escaneo de QR.

---

# 5. BACKEND

Stack decidido:

Python
FastAPI
SQLAlchemy 2
Alembic
Pydantic
pydantic-settings
Psycopg 3
PostgreSQL 16
Pytest

Arquitectura:

router
↓
service
↓
repository
↓
database

Estructura conceptual:

backend/
└── app/
├── core/
│ ├── config.py
│ ├── database.py
│ ├── security.py
│ ├── logging.py
│ └── exceptions.py
│
└── modules/
├── auth/
├── users/
├── roles/
├── employees/
├── units/
├── correspondence/
├── derivations/
├── documents/
├── notifications/
├── tracking/
├── reports/
└── audit/

No crear carpetas vacías únicamente por estética.

Crear módulos cuando realmente sean necesarios.

---

# 6. ESTADO ACTUAL CONFIRMADO DE DOCKER

Docker Desktop ya fue instalado correctamente.

Comandos verificados:

docker --version

Resultado observado:

Docker version 29.8.0

También:

docker compose version

Resultado observado:

Docker Compose v5.5.1

Docker Engine funciona correctamente.

WSL2 está instalado.

Distribución predeterminada:

Ubuntu

Versión predeterminada:

WSL 2

---

# 7. POSTGRESQL YA FUNCIONA

Ya levantamos PostgreSQL mediante Docker.

Imagen:

postgres:16-alpine

Contenedor:

sipe_correspondencia_db

El comando:

docker compose ps

mostró:

sipe_correspondencia_db
postgres:16-alpine
Up
healthy
5432:5432

Por lo tanto:

Docker OK
PostgreSQL OK
Healthcheck OK

---

# 8. BASE DE DATOS

Base:

correspondencia_sipe

Usuario:

sipe_app

Se confirmó ingresando mediante:

docker exec -it sipe_correspondencia_db psql -U sipe_app -d correspondencia_sipe

`\l` mostró:

correspondencia_sipe | sipe_app | UTF8

La base de datos está actualmente LIMPIA.

No existen tablas de negocio todavía.

Eso es intencional.

No crear tablas manualmente.

Queremos que el esquema sea administrado mediante:

SQLAlchemy + Alembic

---

# 9. DOCKER-COMPOSE QUE EXISTÍA

El repositorio ya tenía un docker-compose.yml antes de comenzar este trabajo.

El contenido observado originalmente era aproximadamente:

services:

postgres:

    image: postgres:16-alpine

    container_name: sipe_correspondencia_db

    restart: unless-stopped

    ports:
      - "${POSTGRES_PORT:-5432}:5432"

    environment:
      POSTGRES_DB: ${POSTGRES_DB:-correspondencia_sipe}
      POSTGRES_USER: ${POSTGRES_USER:-sipe_app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change_me_in_production}

    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schema:/docker-entrypoint-initdb.d/schema:ro
      - ./database/seeds:/docker-entrypoint-initdb.d/seeds:ro
      - ./database/docker/00_init.sh:/docker-entrypoint-initdb.d/00_init.sh:ro

    healthcheck:
      test:
        [
          "CMD-SHELL",
          "pg_isready -U ${POSTGRES_USER:-sipe_app} -d ${POSTGRES_DB:-correspondencia_sipe}"
        ]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
postgres_data:

IMPORTANTE:

No asumir que este compose sigue exactamente igual.

INSPECCIONARLO antes de modificarlo.

Inicialmente discutimos eliminar los scripts automáticos:

database/schema
database/seeds
database/docker/00_init.sh

de la inicialización del esquema, porque queremos utilizar Alembic como mecanismo oficial para crear y evolucionar el esquema.

No borrar esas carpetas sin inspeccionar primero su contenido.

Pueden contener trabajo previo útil.

---

# 10. VARIABLES DE ENTORNO

Existe `.env`.

Está correctamente agregado a `.gitignore`.

Nunca subir `.env` a Git.

Existe también:

.env.example

El `.env` observado tenía conceptos como:

POSTGRES_DB=correspondencia_sipe
POSTGRES_USER=sipe_app
POSTGRES_PASSWORD=...
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

y una DATABASE_URL.

No imprimir ni copiar secretos innecesariamente.

IMPORTANTE SOBRE POSTGRES_HOST:

Si FastAPI se ejecuta directamente desde Windows:

POSTGRES_HOST=localhost

Si FastAPI se ejecuta dentro de Docker Compose:

POSTGRES_HOST=postgres

porque `postgres` es el nombre DNS del servicio dentro de la red Docker.

Dentro de Docker la conexión debe ser conceptualmente:

postgresql+psycopg://usuario:password@postgres:5432/correspondencia_sipe

No usar localhost desde el contenedor FastAPI para comunicarse con PostgreSQL.

---

# 11. .GITIGNORE

Ya contiene:

.env

También contiene:

postgres_data/

Aunque `postgres_data` actualmente es un named volume de Docker y no necesariamente una carpeta física.

Mantener `.env` ignorado siempre.

Más adelante, si existen carpetas locales como:

storage/
uploads/
backups/

revisar apropiadamente qué debe y no debe subirse a Git.

---

# 12. BACKEND — ESTADO ACTUAL

Ya se ejecutaron comandos para crear el esqueleto:

backend/
├── Dockerfile
├── requirements.txt
└── app/
├── **init**.py
├── main.py
└── core/
├── **init**.py
├── config.py
└── database.py

IMPORTANTE:

La creación de estos archivos está confirmada.

NO está confirmado todavía que todos contengan el código definitivo recomendado anteriormente.

Por eso:

INSPECCIONAR SU CONTENIDO PRIMERO.

No asumir que ya están configurados.

---

# 13. SIGUIENTE OBJETIVO TÉCNICO INMEDIATO

NO crear todavía usuarios, roles ni tablas de correspondencia.

Primero debemos conseguir únicamente:

Flutter existente
│
│ posteriormente
▼
FastAPI :8000
│
▼
SQLAlchemy
│
▼
PostgreSQL :5432

El siguiente milestone es:

1. configurar FastAPI;
2. ejecutarlo dentro de Docker;
3. conectarlo a PostgreSQL;
4. crear `/health`;
5. crear `/health/database`;
6. verificar Swagger `/docs`;
7. después configurar Alembic;
8. comprobar una migración limpia;
9. recién después diseñar las tablas del negocio.

No saltarse directamente al modelo completo de base de datos.

---

# 14. DEPENDENCIAS PREVISTAS DEL BACKEND

requirements.txt inicialmente puede necesitar:

fastapi
uvicorn[standard]
sqlalchemy
psycopg[binary]
alembic
pydantic-settings

Usar versiones compatibles y razonablemente actuales.

No utilizar paquetes abandonados.

No instalar librerías sin explicar para qué se necesitan.

---

# 15. HEALTH ENDPOINTS

Queremos algo conceptual como:

GET /health

respuesta:

{
"status": "ok",
"service": "correspondencia-api"
}

Y:

GET /health/database

que ejecute:

SELECT 1

mediante SQLAlchemy.

Respuesta esperada:

{
"status": "ok",
"database": "connected"
}

No devolver:

- passwords;
- connection strings;
- stack traces;
- información sensible;

al cliente.

---

# 16. DOCKER DEL BACKEND

Objetivo de desarrollo:

Docker
├── postgres
└── backend

PostgreSQL:

internamente postgres:5432

Backend:

internamente :8000

Windows accederá al backend mediante:

http://localhost:8000

FastAPI debe depender del healthcheck de PostgreSQL antes de iniciar cuando sea razonable.

Durante desarrollo podemos montar:

./backend:/app

y usar Uvicorn con:

--reload

Esto es solamente para desarrollo.

No usar `--reload` en producción.

---

# 17. PRODUCCIÓN FUTURA

Producción será Linux, probablemente Debian/Ubuntu.

Arquitectura objetivo:

Internet / LAN
│
▼
Firewall
│
▼
Nginx
│ HTTPS :443
├─────────────► Flutter Web estático
│
└── /api ─────► FastAPI
│
▼
PostgreSQL

PostgreSQL NO debe exponerse públicamente.

FastAPI tampoco debería exponerse directamente a Internet.

Externamente se publicará principalmente:

443

Nginx será reverse proxy.

HTTPS será obligatorio.

---

# 18. DOCUMENTOS Y ARCHIVOS

El sistema debe manejar dos clases principales:

GENERATED
UPLOADED

## GENERATED

Documentos generados por el propio sistema, por ejemplo:

- hoja de ruta;
- memorándum;
- comunicado;
- informe;
- carta;
- otros documentos institucionales.

La generación oficial de PDF debe realizarse en backend, no exclusivamente en Flutter.

Modelo recomendado:

datos estructurados PostgreSQL +
snapshot del documento +
PDF oficial +
hash SHA-256

Una vez emitido un documento oficial:

NO regenerarlo silenciosamente utilizando datos actuales modificables.

Guardar la versión oficial emitida.

Si existe una corrección:

crear nueva versión.

Marcar la anterior como:

superseded / annulled / replaced

según corresponda.

Mantener historial.

---

# 19. ARCHIVOS SUBIDOS

Usuarios podrán adjuntar:

PDF
DOC/DOCX
XLS/XLSX
JPG/JPEG
PNG

y posteriormente otros formatos autorizados.

Flujo:

Flutter
↓ multipart/form-data
FastAPI
↓
validación
↓
StorageService
↓
almacenamiento persistente

PostgreSQL almacena METADATOS.

No almacenar archivos grandes directamente como BLOB en PostgreSQL salvo una razón futura muy fuerte.

Metadata aproximada:

id
correspondence_id
movement_id nullable
document_type
source
original_filename
stored_filename
mime_type
size
sha256
storage_path
template_version
created_by
created_at
active

Nombre físico del archivo:

UUID / identificador generado.

Nunca confiar directamente en el nombre enviado por el usuario para construir paths.

---

# 20. STORAGE

Primera implementación:

almacenamiento local persistente mediante volumen Docker.

Ejemplo conceptual:

/data/documents

Pero diseñar una interfaz:

StorageService

para poder cambiar posteriormente a MinIO/S3 si fuera necesario.

No introducir MinIO inicialmente.

Los archivos no deben exponerse directamente como carpeta pública.

Acceso:

GET /api/documents/{id}/download

con autenticación y permisos.

Backups futuros deben incluir:

PostgreSQL

- document storage

Un volumen Docker NO es un backup.

---

# 21. QR

Los documentos oficiales podrán contener un QR.

NO poner PII directamente en el QR.

NO utilizar solamente IDs secuenciales predecibles como:

?id=152

Utilizar:

UUID/token aleatorio no predecible.

Flujo móvil:

Usuario abre Flutter Web en celular
↓
login
↓
Escanear QR
↓
cámara
↓
token
↓
FastAPI
↓
buscar correspondencia/documento
↓
validar permisos
↓
mostrar información

Ejemplo conceptual:

GET /api/correspondences/by-qr/{token}

Debe existir también búsqueda manual si QR está dañado.

Para cámara en navegador, producción debe trabajar sobre HTTPS.

---

# 22. NOTIFICACIONES

Las notificaciones deben persistirse.

Tabla conceptual:

notifications

campos aproximados:

id
user_id
type
title
message
entity_type
entity_id
is_read
read_at
created_at

Tipos futuros:

DOCUMENT_ASSIGNED
DOCUMENT_RECEIVED
DOCUMENT_OBSERVED
DOCUMENT_RETURNED
DOCUMENT_CONCLUDED
DOCUMENT_REOPENED
DEADLINE_WARNING
SYSTEM

Primera versión puede usar polling.

Por ejemplo:

GET /api/notifications/unread

cada cierto intervalo razonable.

WebSocket puede agregarse posteriormente o usarse si realmente mejora la experiencia.

No usar Redis/RabbitMQ solo para aparentar una arquitectura empresarial.

---

# 23. MODELO DE DATOS CONCEPTUAL

NO implementar todo automáticamente.

Primero validar los requisitos reales.

Familias conceptuales:

## Seguridad

users
roles
permissions
user_roles
role_permissions

## Organización

organizational_units
positions
employees

Posiblemente:

professions
professional_degrees

solo si los requisitos institucionales lo confirman.

## Catálogos

correspondence_types
document_types
priorities
instructions
statuses

## Núcleo

correspondences
correspondence_recipients
movements
status_history

## Documentos

documents
document_versions

## Sistema

notifications
audit_logs

---

# 24. CORRESPONDENCIA

No usar `route_sheet` como única entidad principal.

Entidad principal genérica:

Correspondence

Puede tener:

UUID id interno
sequence_number
management_year
code
subject
correspondence_type_id
priority_id
status_id
origin_unit_id
current_unit_id
current_employee_id
created_by
registered_at
created_at
updated_at

Esto es preliminar.

NO implementar estos campos sin revisar el levantamiento funcional.

---

# 25. MOVIMIENTOS / DERIVACIONES

El historial de movimientos es fundamental.

Conceptualmente:

movement

from_unit
from_employee
to_unit
to_employee
instruction
observation
sent_at
received_at
status
created_by
created_at

El estado actual puede estar denormalizado en `correspondences` para consultas rápidas.

Pero el historial verdadero está en `movements`.

Nunca sobrescribir movimientos anteriores.

---

# 26. STATUS HISTORY

Mantener historial de cambios de estado.

Conceptualmente:

correspondence_id
previous_status
new_status
changed_by
reason
created_at

---

# 27. AUDITORÍA

Auditoría NO es lo mismo que movimientos del trámite.

audit_logs debe poder registrar:

user_id
action
entity_type
entity_id
old_values JSONB
new_values JSONB
ip
user_agent
created_at

Ejemplos:

USER_UPDATED
ROLE_ASSIGNED
CORRESPONDENCE_EDITED
DOCUMENT_DOWNLOADED
STATUS_CHANGED

No guardar passwords ni tokens dentro de auditoría.

---

# 28. ORGANIZACIÓN MUNICIPAL

Necesitamos modelar:

Unidades organizacionales
Cargos
Funcionarios
Usuarios

Una unidad puede tener jerarquía.

Por ejemplo mediante:

parent_id

No asumir todavía la estructura exacta del GAM Sipe Sipe.

Esta información deberá obtenerse del organigrama y levantamiento institucional.

---

# 29. CORRESPONDENCIA INTERNA / EXTERNA

Existe el concepto:

CI = correspondencia interna

CE = correspondencia externa

No confundir:

correspondence_type

con:

document_type

Ejemplo:

Una correspondencia puede ser INTERNAL

y contener un documento tipo:

MEMORANDUM

Son conceptos diferentes.

---

# 30. FUNCIONALIDADES ESPERADAS

Basadas en el análisis funcional realizado hasta ahora:

Administración:

- usuarios;
- roles;
- permisos;
- funcionarios;
- cargos;
- unidades;
- tipos de correspondencia;
- instrucciones;
- prioridades;
- estados;
- catálogos.

Correspondencia:

- registrar;
- generar código;
- hoja de ruta;
- adjuntar documentos;
- destinatarios;
- copias;
- asignar;
- recibir;
- derivar;
- observar;
- devolver;
- concluir;
- archivar;
- seguimiento;
- historial.

Bandejas:

- entrada;
- pendientes;
- recibidos;
- enviados;
- observados;
- concluidos;
- archivados.

Reportes:

- por fechas;
- estado;
- unidad;
- funcionario/cargo;
- tipo;
- seguimiento.

Estos requisitos todavía deben ser validados mediante levantamiento funcional.

---

# 31. REFERENCIA COMPETITIVA

Se analizó un sistema/propuesta existente solamente como referencia funcional.

No copiar:

- código;
- diseño;
- assets;
- estructura propietaria;
- implementación propietaria.

Puede usarse únicamente para comprender funcionalidades comunes del dominio.

Funciones observadas en una solución comparable:

Administración:

- cuentas;
- cargos;
- funcionarios;
- unidades;
- profesiones;
- grados;
- instrucciones;
- referencias;
- tipos de correspondencia.

Hojas de ruta:

- correspondencias;
- bandeja de entrada;
- recibidos;
- enviados;
- observados;
- archivados;
- proveídos.

Reportes:

- salidas;
- general;
- seguimiento;
- seguimiento por cargo.

Esto sirve como referencia del dominio, no como especificación final.

---

# 32. REQUISITOS QUE TODAVÍA DEBEN LEVANTARSE

Antes de cerrar el modelo de datos necesitamos conocer del GAM Sipe Sipe:

- organigrama;
- unidades oficiales;
- cargos;
- funcionarios;
- tipos reales de correspondencia;
- reglas de CITE;
- numeración anual;
- modelos actuales de hoja de ruta;
- documentos físicos utilizados;
- Excel actuales;
- prioridades;
- estados;
- instrucciones/proveídos;
- rutas típicas;
- permisos por rol;
- reportes necesarios;
- identidad gráfica;
- logo/escudo;
- información visible al ciudadano;
- reglas de archivo;
- reglas de anulación/corrección.

No inventar estas reglas.

Si falta una regla de negocio, preguntarme.

---

# 33. AUTENTICACIÓN Y AUTORIZACIÓN

Se prevé:

JWT access token

- refresh token

RBAC:

usuarios
roles
permissions

No llenar el frontend de:

if role == "admin"

Las decisiones sensibles deben validarse en backend mediante permisos.

Frontend puede ocultar controles por UX, pero backend siempre debe autorizar.

---

# 34. SEGURIDAD

Reglas generales:

No hardcodear secrets.

No subir `.env`.

No exponer PostgreSQL públicamente en producción.

Validar tipos y tamaños de archivos.

Proteger paths.

No confiar en nombres de archivos del cliente.

Validar permisos en cada endpoint sensible.

Passwords con hashing seguro.

No guardar contraseñas en texto plano.

Aplicar CORS correctamente.

HTTPS en producción.

Evitar filtrar stack traces al cliente.

Auditar acciones sensibles.

---

# 35. BACKUPS

Producción deberá respaldar:

1. PostgreSQL
2. documentos almacenados

Plan aproximado:

pg_dump periódico

- copia del almacenamiento

Los backups deberán probarse mediante restauración.

No considerar Docker volumes como backup.

---

# 36. FORMA DE TRABAJAR CONMIGO

Soy desarrollador Flutter y quiero entender lo que estamos haciendo.

No hagas cambios masivos silenciosamente.

Cuando avancemos:

1. dime qué problema estamos resolviendo;
2. explícame brevemente la arquitectura;
3. muéstrame los archivos que modificarás;
4. implementa;
5. indícame cómo probarlo;
6. espera el resultado antes del siguiente bloque importante.

Evitar darme 20 cambios simultáneos sin haber probado el paso anterior.

---

# 37. REGLAS PARA MODIFICAR EL REPOSITORIO

Antes de editar:

- inspecciona archivos existentes;
- lee docker-compose.yml;
- lee .env.example;
- verifica .gitignore;
- inspecciona backend existente;
- inspecciona database/;
- inspecciona scripts/;
- revisa git status.

Nunca borrar archivos sin saber para qué servían.

No ejecutar una migración destructiva sin explicarlo.

No resetear PostgreSQL ni borrar el volumen sin mi autorización.

NO ejecutar:

docker compose down -v

sin preguntarme antes.

No hacer `git reset --hard`.

No borrar datos o código por conveniencia.

---

# 38. GIT

Usar Git como control de versiones.

Cambios pequeños y coherentes.

Antes de cambios grandes:

git status

No incluir:

.env
credenciales
tokens
archivos temporales
documentos sensibles

No cambiar configuración global de Git sin necesidad.

---

# 39. ESTADO EXACTO DESDE EL QUE DEBES CONTINUAR

ESTÁ CONFIRMADO:

- Flutter project existe.
- Flutter 3.22.3.
- Docker Desktop instalado.
- WSL2 funcionando.
- Docker Engine funcionando.
- Docker Compose funcionando.
- PostgreSQL 16 Alpine funcionando.
- contenedor `sipe_correspondencia_db` healthy.
- base `correspondencia_sipe` existe.
- propietario `sipe_app`.
- base actualmente limpia.
- `.env` existe.
- `.env` está ignorado por Git.
- `backend/` y su esqueleto básico fueron creados.

NO ESTÁ CONFIRMADO:

- que FastAPI esté configurado;
- que requirements.txt tenga todas las dependencias;
- que Dockerfile esté terminado;
- que backend esté agregado al docker-compose;
- que `/health` exista;
- que FastAPI conecte a PostgreSQL;
- que Alembic esté configurado;
- que exista alguna migración;
- que existan tablas.

Por eso debes empezar inspeccionando el estado actual.

---

# 40. PRIMERA TAREA PARA TI

NO empieces creando modelos de negocio.

Primero:

1. Inspecciona:
   - backend/
   - backend/app/
   - backend/app/core/
   - backend/requirements.txt
   - backend/Dockerfile
   - docker-compose.yml
   - .env.example
   - .gitignore
   - database/
   - scripts/

2. Dime qué ya existe y qué falta.

3. Configura la mínima API FastAPI.

4. Configura conexión SQLAlchemy con PostgreSQL.

5. Agrega:
   GET /health
   GET /health/database

6. Agrega backend al Docker Compose si todavía no está agregado.

7. Levanta mediante:
   docker compose up -d --build

8. Verifica:
   docker compose ps

9. Prueba:
   http://localhost:8000/health
   http://localhost:8000/health/database
   http://localhost:8000/docs

10. No crees tablas todavía.

11. Cuando las tres pruebas funcionen, detente y explícame el resultado.

Después configuraremos Alembic.

---

# 41. DESPUÉS DEL HEALTH CHECK

El siguiente milestone será:

FastAPI
↓
SQLAlchemy
↓
Alembic
↓
PostgreSQL

Configurar Alembic correctamente para SQLAlchemy 2.

Queremos que todas las modificaciones estructurales de la BD queden versionadas.

No usar:

Base.metadata.create_all()

como mecanismo de producción para administrar el esquema.

Alembic será el mecanismo oficial.

---

# 42. FILOSOFÍA

Quiero que este proyecto pueda evolucionar posteriormente a un producto reutilizable para otras instituciones.

Sin embargo:

NO diseñar hoy para 100 municipios.

Primero hacer correctamente Sipe Sipe.

Separar en lo posible:

núcleo reutilizable

- configuración/reglas específicas de la institución.

No sacrificar simplicidad por una hipotética expansión futura.

---

# 43. MUY IMPORTANTE

No continúes según lo que "probablemente" exista.

ABRE LOS ARCHIVOS.

INSPECCIONA EL REPOSITORIO.

Trabaja con el estado real.

Si algo de este contexto no coincide con el código actual:

detente,
muéstrame la diferencia
y proponme la corrección más segura.

Empieza ahora revisando el repositorio y dime el estado real antes de realizar modificaciones grandes.

# ESTILO DE CÓDIGO Y MANTENIBILIDAD

Este proyecto será mantenido directamente por el desarrollador del sistema.

Por lo tanto, todo código generado debe priorizar:

- claridad;
- legibilidad;
- nombres descriptivos;
- flujo fácil de seguir;
- métodos pequeños;
- responsabilidades claras;
- mínima complejidad accidental.

No generar código excesivamente abstracto o "enterprise" sin necesidad.

No crear interfaces, factories, adapters, managers, handlers o capas adicionales
si actualmente existe una sola implementación y no aportan una ventaja concreta.

No usar patrones de diseño solo por usarlos.

Antes de introducir una abstracción, debe existir una necesidad real.

Evitar:

- métodos gigantes;
- archivos gigantes;
- lógica escondida;
- magic strings;
- magic numbers;
- callbacks difíciles de seguir;
- herencias innecesarias;
- genéricos innecesarios;
- metaprogramación innecesaria;
- dependencias innecesarias.

Preferir código explícito y fácil de depurar.

El desarrollador debe poder colocar un breakpoint y seguir el flujo de la aplicación
sin tener que atravesar una cantidad innecesaria de capas.

Para backend mantener como máximo el flujo conceptual:

router -> service -> repository -> database

pero no obligar a que cada operación tenga las cuatro capas si alguna no aporta valor.

Para Flutter mantener:

UI -> Cubit/Bloc -> Repository -> API

sin lógica HTTP directamente en Widgets.

Los nombres de clases, funciones y variables deben estar en inglés.
Los textos visibles para el usuario deben estar en español.

Los comentarios deben explicar el POR QUÉ cuando sea necesario.
No llenar el código de comentarios que simplemente repiten lo que hace la línea.

Cuando OpenCode genere una implementación no trivial,
debe explicar brevemente el flujo antes o después de realizarla.

La prioridad es:

código que un desarrollador humano pueda mantener

> arquitectura sofisticada
>
> cantidad de patrones utilizados

# REGLA DE APRENDIZAJE

No implementar bloques grandes de arquitectura sin que el desarrollador pueda
entenderlos.

Cuando se introduzca una tecnología o concepto nuevo, por ejemplo:

- Alembic
- JWT
- refresh tokens
- middleware
- repository pattern
- WebSocket
- almacenamiento de documentos
- auditoría

explicar primero:

1. qué problema resuelve;
2. por qué lo necesitamos;
3. dónde encaja en este proyecto;
4. cuál será el flujo;
5. qué archivos intervienen.

Después implementar.

No asumir que "funciona" es suficiente.
El código debe poder ser comprendido y mantenido por el desarrollador.

---

# ARQUITECTURA FLUTTER OBLIGATORIA

El frontend Flutter utilizará Clean Architecture organizada por feature.

Estructura base por feature:

feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── bloc/ o cubit/
    ├── pages/
    └── widgets/

Flujo esperado:

UI
→ Bloc/Cubit
→ UseCase cuando exista lógica de aplicación que lo justifique
→ Repository
→ Datasource
→ API FastAPI

Reglas:

- Presentation nunca accede directamente a datasources.
- Los Widgets no realizan llamadas HTTP.
- Dio vive en la capa data/core correspondiente.
- Los modelos/response pertenecen a Data.
- Las Entities pertenecen a Domain.
- El Repository transforma modelos/responses a Entities.
- Preferir mapeos explícitos model/response -> entity.
- Las Entities deben ser inmutables.
- Utilizar Equatable cuando corresponda.
- Utilizar copyWith para actualización de estado.
- Bloc/Cubit mantiene estados inmutables.
- Mantener manejo consistente de Result/Failure.
- Los errores técnicos se convierten a Failure antes de llegar a Presentation.
- No pasar DTOs/API responses directamente a la UI.
- Inyección de dependencias por constructor.
- No usar Service Locator de forma indiscriminada.
- No crear abstracciones vacías solamente para cumplir una plantilla.

UseCases:
- Se utilizan cuando encapsulan una operación o regla de aplicación real.
- No crear UseCases triviales que solo llamen una línea del Repository sin aportar claridad.
- Mantener el estilo ya utilizado en POSMobile, Capturador e Inventarios.

Código en inglés.
UI y mensajes visibles en español.

La prioridad es que el proyecto resulte familiar y mantenible para el desarrollador,
no que parezca una Clean Architecture académica sobredimensionada.

IMPORTANTE:
Esta regla aplica al FRONTEND FLUTTER.

El backend FastAPI mantiene su propia arquitectura modular:
router -> service -> repository -> database,
sin intentar copiar artificialmente la arquitectura Flutter.

---

# DISEÑO DEL MODELO DE DATOS — OBSERVACIONES PENDIENTES

Estas observaciones complementan la propuesta del Bloque 1
(organización + identidad + autorización) y deben respetarse
cuando se generen los modelos y las migraciones.

1. organizational_units.code
   No asumir todavía UNIQUE NOT NULL.
   Marcar la existencia, el formato y la obligatoriedad del código
   como pendiente del levantamiento institucional.

2. employees.unit_id
   La relación empleado-unidad es correcta conceptualmente,
   pero su obligatoriedad y cardinalidad definitivas quedan
   pendientes del levantamiento institucional
   por posibles encargaturas, traslados o situaciones especiales.

3. Migraciones
   No es necesario asignar revision IDs manuales tipo 0001/0002.
   Alembic generará sus propios IDs.
   Los nombres conceptuales de las migraciones serán:
   - create organization structure
   - create identity and authorization

---

# CORRESPONDENCIA — REGLAS FUNCIONALES CONFIRMADAS

Reglas confirmadas con el GAM Sipe Sipe. Se registran aquí para que
queden como fuente de verdad durante el diseño e implementación.
Todavía NO se han creado modelos ni endpoints de correspondencia.

## Creación / registro

- La hoja de ruta / correspondencia puede ser generada por cualquier
  usuario operativo autorizado.
- Ventanilla será uno de los puntos donde más se registren documentos
  externos, pero la creación NO está limitada exclusivamente a
  Ventanilla.
- La creación de copias / CC queda fuera de la primera versión.

## Derivación

- Un trámite activo puede ser derivado por el usuario que actualmente
  lo tiene a cargo.
- Una derivación tiene UN solo destinatario (no hay destinatarios
  múltiples ni copias en esta versión).
- La derivación NO requiere aceptación del destinatario.
- Al derivar, el trámite pasa al nuevo destinatario directamente.
- No agregar por ahora campos `accepted_at`, `rejected_at`,
  `acceptance_status` ni equivalentes.

## Conclusión

- Todos los usuarios operativos autorizados pueden concluir un trámite
  que actualmente tienen a cargo.
- Un trámite puede concluir en la unidad / funcionario que realmente
  resuelva el asunto.
- No se asume ni se hardcodea que la conclusión deba ocurrir
  necesariamente en Secretaría Administrativa ni Técnica.

## Reapertura

- Los trámites concluidos podrán reabrirse.
- Una reapertura debe quedar registrada en historial.
- Nunca borrar el estado anterior: la trazabilidad histórica se
  conserva siempre.

## Estados (semántica confirmada)

- `PENDIENTE` significa que el trámite sigue activo y requiere
  atención.
- `OBSERVADO` significa que existe una observación, falta, corrección o
  impedimento que requiere atención.
- `OBSERVADO` debe ser distinto de `PENDIENTE`. NO son sinónimos.

## Trazabilidad

- Toda la trazabilidad histórica debe conservarse.
- El historial de movimientos y de estados NO se destruye bajo
  ninguna circunstancia del flujo normal.

## Modelo conceptual futuro (NO implementar todavía)

`Correspondence` mantiene el estado y ubicación actuales.
`Movement` conserva cada derivación histórica.

`Movement` podrá guardar conceptualmente:
- correspondence_id
- from_user_id
- from_unit_id
- to_user_id
- to_unit_id
- instruction
- observation
- sent_at
- created_by

`Correspondence` podrá mantener, para consultas rápidas de
"dónde está hoy el trámite":
- current_user_id
- current_unit_id
- status_id

La fuente de verdad del recorrido sigue siendo `Movement`. Los campos
denormalizados en `Correspondence` existen solo como índice de
consulta.

## Pendientes del levantamiento (NO cerrar sin confirmar)

Antes de cerrar el modelo se necesita:
- regla exacta de generación del CITE / código;
- campos oficiales de la hoja de ruta;
- datos requeridos al registrar documentación externa;
- proveídos / instrucciones reales;
- prioridades;
- reportes institucionales.
