# PROJECT CONTEXT

Handoff del Sistema de Gestión de Correspondencia y Documentos / Hoja de Ruta del Gobierno Autónomo Municipal de Sipe Sipe, Cochabamba, Bolivia.

**Regla de verdad:** este documento es contexto; el código y sus tests son la fuente final. Reportar discrepancias antes de cambiar arquitectura. No iniciar funcionalidades nuevas para “completar” lo descrito aquí.

## 1. Estado de cierre y límites

Actualizado el 7 de octubre de 2026. Se trabaja directamente en `develop`.
HEAD de código al redactar: `d87d106d8ed0ca3d22a9b68854c0a59b3a62f6d7`; el commit documental posterior se consulta con Git.

- C3 y C4 están cerrados y committeados; no son WIP.
- Los diez commits del lote final están cerrados.
- Configuración Apache demo committeada; instalación y verificación en servidor pendientes.
- No se hizo push ni deploy en este cierre. No asumir que una referencia remota prueba el estado desplegado.
- `git fetch origin` confirmó `origin/develop = 9828a7559fcd00bb7295aa96dd57045999c044df` (C2: roles institucionales base).
- El rango remoto → HEAD de código contiene 16 commits, incluidos **tres del sitio público website**. El commit documental agrega otro. Un push de develop publicaría también esos tres; excluir el WIP de website del índice no los excluye del historial.
- No crear rama/worktree ni reescribir historial sin instrucción. No ejecutar limpieza/reset de datos. No stagear en bloque: auditar rutas y hunks.

### Bloques previos cerrados

| Commit | Bloque |
| --- | --- |
| `ee61a02` | Build Flutter demo /api y configuración Apache |
| `fc303ba` | ADMIN-C3: UI, menú y acciones por permissions |
| `559950f` | ADMIN-C4: asignación de roles independiente de gestión de usuarios |

### Lote final cerrado

| Commit | Resultado |
| --- | --- |
| `336f449` | Configuración del sistema persistida y permisos propios |
| `fd21562` | Selectores buscables y validación unificados |
| `7c8f976` | Configuración institucional y encadenamiento EDIE |
| `a68b350` | Validación de destino en derivación |
| `03efaeb` | Normalización de errores HTTP 400/422 |
| `d3433ad` | Desactivación lógica y recuperación de datos básicos |
| `1dda656` | Indisponibilidad explícita de reportes/consulta pública sin mocks |
| `33412fd` | Corrección de advertencias del lote |
| `20cae0a` | Retiro de mocks del arranque y bandejas heredadas |
| `d87d106` | Destinatario histórico del PDF de encadenamiento |

## 2. Arquitectura y fuentes principales

- Flutter Web en `lib/`: features, Cubit/BLoC, formularios con helpers Inherited y controladores.
- Inyección GetIt en `lib/injection/`.
- `packages/correspondencia_api/`: Dio, ApiMethod, endpoints y modelos JSON.
- `packages/correspondencia_repository/`: entidades, repositorios, mappers y handleExceptions.
- `packages/failures/`: Result, Failure y excepciones tipadas.
- FastAPI en `backend/app/`, SQLAlchemy, PostgreSQL y Alembic.
- Adjuntos en almacenamiento de archivos configurado mediante STORAGE_ROOT; no confundirlo con la base de datos.
- Docker Compose contiene PostgreSQL y backend; no se modificó para el deploy /api.
- `website/` es otro producto: sitio público municipal Astro. No es la app Flutter ni su artefacto de deployment.

Flujo: Widget → Cubit → Repository → API/ApiMethod/Dio → FastAPI → PostgreSQL.
Los errores regresan por Result.err → Cubit → FailureGeneric → listeners/diálogos.

Patrones existentes que deben reutilizarse:
`GeneralStatus`, `TypeOperation`, `AppDataGrid`, `AppFormDialog`, `DialogMessage`, `ListenerPro`, `FullWidgetGeneric`, `AdminUpsertBlocListener` y `PermissionGuard`.
`AppSearchableDropdown` es alias de `AppDropdown`: buscador integrado, validación conectada al controlador y comprobación de mounted después de esperas asíncronas.

## 3. Autenticación, sesión y modelo institucional

- Backend es autoridad de autenticación/autorización.
- Access token en memoria; refresh token en cookie HttpOnly. Coordinación de refresh evita carreras de solicitudes.
- Restauración tras F5: refresh → /auth/me → sesión. Logout elimina cookie y sesión local.
- UserSession contiene roles, permissions y contexto institucional. No reconstruir la unidad del operador desde catálogos de pantalla.
- Employee identifica a la persona; Position es cargo laboral, **no rol de seguridad**.
- Unit identifica unidad institucional; User es la cuenta/credencial.
- Role y Permission viven en BD; la sesión obtiene la unión efectiva de permisos de roles activos.
- La vinculación User–Employee y su unidad determinan el contexto operativo, separado de las autorizaciones de datos maestros.
- Un administrador técnico sin funcionario puede administrar según sus permisos, pero no registrar/derivar/concluir/reabrir correspondencia como operador institucional; su bandeja operativa permanece vacía.

## 4. Permisos: C3, C4 y configuración

No usar comparaciones de nombre de rol ADMIN/MANAGER/OPERATOR para decidir UI o acciones.
Los nombres de roles aparecen en seeds/migraciones para otorgar permisos iniciales; no sustituyen comprobaciones de permissions.

### C3

Para users, employees, positions, units y document_types:

- `master_data.<recurso>.read`: acceso, GET y listado.
- `master_data.<recurso>.manage`: acciones mutables y POST/PUT/PATCH.
- Visibilidad del menú Administración deriva de sus opciones accesibles.
- SideMenuCubit conserva permissions de sesión. refreshBadges no reconstruye el menú con permisos vacíos.
- MANAGER-like con users.read y sin users.manage: Usuarios solo lectura.
- OPERATOR-like sin master_data.*: sin Administración.
- ADMIN-like con los diez permisos read/manage: acceso completo a esos datos.
- AUDITOR_TEST-like con users.read + employees.read: solo Usuarios y Funcionarios.
- Roles custom se resuelven por su combinación efectiva de permisos.

### C4

`master_data.roles.assign` es independiente de users.manage.

- ADMIN recibe el permiso mediante migración; MANAGER y OPERATOR no reciben ese grant automático.
- GET /admin/roles requiere roles.assign.
- Crear usuario sin asignar roles no exige roles.assign; asignarlos sí.
- En update, omitir roles o mantener semánticamente el mismo conjunto no es reasignación.
- Cambiar el conjunto, incluso vaciarlo, requiere roles.assign.
- Los roles asignados deben existir y estar activos.
- Contrato API/repository distingue campo omitido de lista vacía.
- Formulario sin roles.assign muestra roles en lectura y omite la modificación de roles en el payload.
- Tener roles.assign no sustituye users.manage para crear/modificar usuarios.
- Migración aditiva e idempotente; preserva roles personalizados y no elimina grants en downgrade.

### Configuración del sistema

- `system.settings.read`: lectura de configuración.
- `system.settings.manage`: edición.
- Backend: `backend/app/modules/system/`; GET/PUT `/admin/system-settings/institutional`.
- Tabla system_settings, clave `institutional.mayor_display_name`.
- Normalización trim; valor vacío limpia override y permite fallback; máximo 200 caracteres.
- UI guarda cuando cargó el estado y tiene permiso manage.
- Override es nombre de presentación, no cambio de usuario, funcionario, titularidad ni ownership.
- ADMIN recibe ambos permisos de configuración por migración; no asumir que users.manage o roles.assign los otorgan.

## 5. Alembic

Cadena final committeada del tramo reciente:

```text
a7c8d9e0f1a2
  → c9d0e1f2a3b4  roles.assign
  → b8c9d0e1f2a3  system_settings y permisos de configuración
```

Una sola head: `b8c9d0e1f2a3`.
b8 ya está committeada en 336f449; no sigue siendo migración solo-WIP.
C4 depende directamente de a7, no de b8. Después, b8 se conectó a c9.
Ambas migraciones son aditivas, preservan custom roles y no borran sus datos/grants en downgrade.
No modificar migraciones históricas para introducir funcionalidades posteriores ni usar reset de BD como sustituto de Alembic.

## 6. Correspondencia y reglas críticas

### Numeración, origen y destino

- Hoja de ruta correlativa por año; correlativo documental por tipo/año. Mantener transacciones y bloqueo de secuencias.
- Distinguir persona de origen, destinatario y actor que registra/deriva.
- current_unit_id representa la unidad propietaria; current_user_id puede ser opcional según perfil.
- Scope mine usa usuario; scope unit usa unidad del operador.
- Enviados incluye correspondencia creada por el usuario o con DERIVED creado por él; no inferir autoría desde from_user_id.
- Operadores de la unidad propietaria pueden gestionar el trámite; no convertir la asignación individual en bypass/restricción diferente.
- Derivar requiere correspondencia ACTIVE y contexto institucional activo coincidente con la unidad propietaria; no hay bypass por nombre ADMIN.
- Destino debe ser activo y coherente usuario–unidad. Rechazar reasignación idéntica.
- Conclusión/reapertura conservan ownership y registran movimientos.

### EDIE/S y titular institucional

El titular se resuelve desde User + Employee + Position + Unit activos, con códigos de cargo configurados (defaults ALCALDE/ALCALDESA).
Cero titulares válidos significa indisponibilidad; múltiples titulares generan validación de ambigüedad.
La selección usa IDs institucionales, nunca un nombre personal hardcodeado.
Endpoint autenticado de consulta: /institutional-mayor.

Al registrar encadenamiento:

```text
1. CREATED: registro institucional
2. DERIVED: al titular institucional
3. DERIVED: del titular al segundo destinatario
```

- Segundo destino requiere unidad y usuario activo de esa unidad, distinto del titular.
- Actor created_by de los tres movimientos es quien realiza el registro.
- Ownership final queda en el segundo destino.
- No confundir titular intermedio con propietario final.
- Otros perfiles conservan el flujo estándar y su usuario opcional cuando corresponda.
- INFORME/NOTA conservan requisitos de origen institucional.
- Crear trámite y adjuntar archivos son operaciones separadas: fallos de upload posteriores no borran el registro; informar resultado parcial.

### PDF histórico

PDF de encadenamiento bajo /correspondences/{id}/encadenamiento.pdf.
El destinatario histórico se toma del primer DERIVED no cancelado; no se reemplaza por el titular vigente al descargar.
Se preservan referencias a destinatarios que luego quedaron inactivos.
Esto preserva identidad por IDs; no equivale a guardar una fotografía inmutable de todos los nombres. El override de presentación puede seguir afectando el texto mostrado.

## 7. Administración, errores y datos reales

- Desactivación lógica por active, no borrado físico de datos maestros.
- Listados de cinco recursos ofrecen activos/inactivos/todos; default activos.
- Reactivación requiere manage.
- Catálogos operativos excluyen inactivos; referencias históricas permanecen.
- No desactivar un funcionario vinculado a una cuenta activa: validación 422.
- HTTP 400/422 se normaliza a ValidationException/ValidationFailure.
- Detail estructurado FastAPI se traduce con etiquetas seguras; no exponer raw input ni mensajes técnicos internos.
- Mensajes de validación de negocio admitidos se conservan; 500 muestra mensaje seguro.
- No crear manejo paralelo de errores por pantalla ni exponer excepciones crudas.

Reportes generales y consulta pública no tienen backend productivo integrado:
las pantallas muestran indisponibilidad; no generan resultados simulados.
No existe un reports.view implementado por este cierre.
Arranque ya no siembra mocks de LocalStore. Bandejas heredadas no disponibles no instancian cubits de datos simulados desde su UI.
Puede quedar código legacy/mocks sin ruta activa: no deducir que fue eliminado todo archivo histórico.

## 8. Deploy demo preparado, no ejecutado

Archivos versionados:
- deploy/apache/correspondencia.conf
- deploy/apache/README.md
- scripts/build_web_demo.ps1
- packages/correspondencia_api/test/api_config_test.dart

Desarrollo mantiene **http://localhost:8000** como API_BASE_URL por defecto.
Build demo: `flutter build web --release --dart-define=API_BASE_URL=/api`.
El script ejecuta pub get y build; no copia archivos al servidor ni instala servicios.

Apache:
- Flutter en /var/www/correspondencia, servido desde raíz.
- Rewrite SPA excluye /api/ y respeta archivos/directorios existentes.
- ProxyPass /api/ → http://127.0.0.1:8000/ elimina el prefijo público.
- /api/auth/login, /api/auth/refresh y /api/auth/logout llegan a /auth/*.
- Backend conserva Path=/auth; ProxyPassReverseCookiePath /auth /api/auth adapta Set-Cookie, incluida eliminación en logout.
- Módulos: proxy, proxy_http, rewrite; Require all granted usa authz_core.
- /api sin barra no tiene proxy propio.
- Cookie Secure requiere HTTPS; VirtualHost actual es demo HTTP. No cambiar auth ni COOKIE_PATH como compensación.

Las pruebas Chrome /api verifican resolución de rutas/clientes, no una cookie real atravesando Apache.
Servidor demo sigue pendiente de actualización, configtest y validación de health, SPA/assets, login, F5 refresh/me y logout.
No se ejecutó deploy ni se tocó Debian durante este cierre.

## 9. Validación del cierre

Resultados finales del lote, revalidar tras el commit documental:
| Suite | Resultado validado |
| --- | --- |
| Backend | 166/166 |
| Flutter raíz | 382/382 |
| Package API | 11/11 |
| Package repository | 19/19 |
| Package failures | 4/4 |
| Chrome API_BASE_URL=/api | 2/2 |
| Flutter analyze | 0 errors, 0 warnings; 88 infos |
| Alembic | Una sola head b8c9d0e1f2a3 |

Los cuatro fallos globales de derivación y el bloqueo backend por entorno citados en auditorías antiguas ya no describen el estado validado del lote.
Infos del analyzer no se cuentan como warnings; pueden producir exit code 1 aunque haya cero errors/warnings.

Comandos de cierre:
```text
flutter test
flutter analyze
# En backend, con entorno de tests aislado:
python -m pytest tests/ -q --tb=short
python -m alembic heads
# En raíz:
git diff --check
```

Backend requiere JWT_ACCESS_SECRET y DATABASE_URL. No apuntar tests a BD del servidor/demo.
La validación utilizó PostgreSQL temporal aislado: contenedor correspondencia_closure_tests_20261007, puerto local 55439, BD closure_tests; STORAGE_ROOT temporal separado.
No se ejecutaron scripts de reset/clean contra datos de desarrollo o producción.
La suite backend emite avisos de dependencias; distinguirlos de fallos funcionales.
No ejecutar limpieza de contenedores/volúmenes como paso implícito del handoff.

## 10. WIP excluido y riesgos pendientes

### Dos archivos de app/test preservados

- lib/features/app/cubit/app_session_cubit.dart: solo reflujo de una expresión de copyWith; comportamiento idéntico. Historial de autenticación previo al lote.
- test/correspondence_movements_grid_test.dart: formato y sustitución de un nombre largo por otro más corto en fixture móvil de 390px. Aserciones y comportamiento no cambian; acorta una entrada de estrés de layout. Historial del grid responsive previo al lote.
- Ninguno fue modificado por los diez commits finales ni exige un commit funcional para cerrarlos.
- No hay evidencia de necesidad del cambio de fixture. Ambos permanecen WIP intactos: no se descartaron ni se incluyeron automáticamente.

### Sitio público website

Hay WIP visual en 13 archivos de componentes/layout/CSS de Astro. Pertenece al sitio público separado; no se modificó ni stageó en este cierre.
Tres commits YA presentes en el rango a push:
`54a087e` (primera versión), `fbc7bec` (preparación sitio/repositorio), `d21457f` (workflow Pages).
La decisión de publicación/separación de ese historial sigue pendiente. No resolver mediante reescritura no autorizada.

### Scripts no versionados

- backend/scripts/clean_dev_data.py
- backend/scripts/reset_admin_dev.py
- scripts/clean_dev_data.ps1
- scripts/reset_admin.ps1

Son borradores con propósito legítimo de desarrollo, no herramientas de producción aprobadas.
No se ejecutaron, stagearon ni committearon.

Riesgos auditados:
- Limpieza realiza borrado físico de correspondencia, movimientos, adjuntos y parte de maestros/cuentas. Sus comprobaciones de entorno/URL son heurísticas, no garantía de conexión exclusivamente local.
- Borrado de archivos de adjuntos no se revierte con rollback de la transacción SQL.
- Reset admin cambia credenciales y privilegios, usa contraseña fija y carece de una barrera equivalente de entorno/confirmación.
- Reset contempla permisos históricos de maestros; no asumir que provisiona todos los permisos C4/settings de una instalación nueva.
- Wrappers PowerShell pueden arrancar Docker Compose, incluso antes de una comprobación/dry-run.
- Requieren decisión y validación explícitas antes de versionar o usar. No reproducir credenciales en documentación.

### Antes de push/deploy

1. Decidir qué hacer con los commits existentes de website en develop.
2. Resolver o preservar conscientemente los dos residuos y WIP del sitio; no incluirlos por accidente en builds.
3. Asegurar entorno de servidor, migraciones pendientes, backup y almacenamiento según plan autorizado; no ejecutar ahora.
4. Validar Apache y cookie real en navegador, incluida renovación y eliminación, cuando se autorice deploy.
5. Revisar TLS y variables del servidor: los tests locales no certifican infraestructura productiva.

Este cierre termina con commit documental selectivo, índice vacío y resto del WIP intacto. Consultar git status y el historial antes de la siguiente acción.
