# PROJECT CONTEXT

Handoff del Sistema de Gestión de Correspondencia y Documentos / Hoja de Ruta del Gobierno Autónomo Municipal de Sipe Sipe, Cochabamba, Bolivia.

**Regla de verdad:** este documento es contexto; el código y sus tests son la fuente final. Reportar discrepancias antes de cambiar arquitectura. No iniciar funcionalidades nuevas para “completar” lo descrito aquí.

## 1. Estado de cierre y límites

Actualizado el **14 de octubre de 2026**. Rama de trabajo aislada `feature/correspondencia-final`, desde `release/correspondencia-qa` (`b28e08b`). **QA READY: núcleo de Correspondencia**.

- Cierre P0/P1: `f8b0488`, `8703f2e`, `fbc00ad`, `0ec7367`; correcciones del smoke Chrome: `28b41ef`, `a92cbb4`, `7914ace`. Todos los bloqueos P0/P1 solicitados quedaron resueltos. Checklist: [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md).
- Crear genera exactamente CREATED + un DERIVED inicial. Los destinos posteriores requieren derivaciones reales. Esta regla sustituye el antiguo encadenamiento automático de dos destinos.
- Ventanilla se identifica por configuración institucional; no por nombres de rol/cargo/unidad. Autoridad documental y receptor operativo son conceptos separados.
- NO PUSH. NO DEPLOY. No iniciar Turnos, Asistencia, RR.HH. ni Website. Inicio, Notificaciones y Reportes se completaron por autorización explícita en el worktree limpio.
- El árbol original conserva WIP ajeno. La entrega QA validada es el árbol **committeado**, exportado sin ese WIP; no construir el handoff desde el directorio sucio.
- No crear rama/worktree, reescribir historial, resetear bases ni borrar volúmenes sin instrucción. No usar `git add .`; seleccionar archivos/hunks.
- El historial previo incluye commits Website; excluir su WIP no los elimina del historial. Revisar el rango antes de cualquier publicación futura.

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

- `system.settings.read` permite leer y `system.settings.manage` editar GET/PUT `/admin/system-settings/institutional`; no se infieren de permisos de usuarios.
- `institutional.intake_unit_id`: unidad activa de Ventanilla. Se compara con la unidad real actual del operador.
- `institutional.initial_recipient_employee_ids`: receptores iniciales explícitos; funcionario, cargo, unidad y cuenta vinculada deben estar activos. No se identifican por SMA/SMT ni nombres.
- `institutional.mayor_display_name`: texto documental de máxima autoridad, obligatorio para nuevos EDIE, normalizado con trim y límite de 200 caracteres.
- `institutional.mayor_employee_id`: referencia compatible/opcional; no sustituye el texto ni implica ownership inicial.
- `/edie-first-recipients` y `/correspondence-creation-policy` proporcionan el catálogo operativo y la política de origen autenticada sin exigir administración.
- La pantalla permite editar texto, Ventanilla y receptores con manage, leer sin manage, refrescar y recuperar configuración heredada inválida. La creación rechaza configuración inválida hasta corregirla.
- La configuración no provisiona automáticamente funcionarios/cuentas ni modifica documentos anteriores.

### Creación dinámica

`correspondence.create` autoriza crear. La migración otorga grants iniciales a roles base; el runtime verifica permissions de roles activos, nunca nombres ADMIN/DIRECTOR/SECRETARIA/VENTANILLA. Requiere contexto institucional activo. El cargo determina lectura; ownership determina operaciones.

## 5. Alembic

La cadena limpia actual tiene **una sola head: `g2b3c4d5e6f7`**, después de notificaciones (`g1b2c3d4e5f6`) y de `correspondence.create` (`f2a3b4c5d6e7`). Incluye el snapshot JSONB histórico `d0e1f2a3b4c5` sin reescribir esa migración.

Se probó `upgrade head` desde PostgreSQL nuevo aislado y `alembic heads/history`. El WIP local de Turnos añade `a3b4c5d6e7f8`: no pertenece al artefacto QA. Los cambios WIP de migraciones previas también permanecen fuera de los commits.
No resetear BD ni modificar docker-compose. Ejecutar migraciones en el entorno QA elegido después de revisar backup/configuración; los tests no deben usar bases del usuario/servidor.

## 6. Correspondencia y reglas críticas

### Visibilidad y responsabilidad

- Funcionario normal: documentos asignados directamente. `Position.can_view_unit_correspondence=true`: correspondencia actual de su unidad.
- Otra unidad: sin lectura operativa. Enviados permite seguimiento personal por creación o DERIVED realizado; no inferir autoría desde from_user_id.
- Detalle, movimientos, PDF y descargas: lectura operativa actual o seguimiento legítimo. IDs fuera de alcance responden 404.
- Seguimiento histórico y lectura de unidad **no autorizan** mutar una asignación de otro responsable activo. Mutaciones requieren responsabilidad actual y contexto institucional activo.
- `can_operate` del detalle backend es la autoridad para las acciones Flutter. Ausencia del campo falla de forma cerrada. ADMIN no es bypass.
- Un cargo con alcance de unidad puede operar el pool sin usuario asignado o recuperar un responsable inactivo, conforme a la política vigente.

### Creación, origen y primer destino

- Correlativos por año/tipo, transacción y bloqueo de secuencias conservados.
- Ventanilla: selecciona exactamente un receptor configurado. Fuera de Ventanilla: receptor configurado o unidad/usuario ordinario si el perfil lo permite.
- No se elude un receptor configurado usando su unidad como destino genérico. Destinos explícitos contradictorios se rechazan antes de insertar/numerar.
- Cada create registra exactamente **CREATED + DERIVED**. Ownership inicial termina en ese único destino.
- INFORME/NOTA mantienen su origen institucional. EDIE exige texto documental de autoridad y destinatario válido; autoridad documental no requiere cuenta ni ser receptor operativo.

### Derivación, ciclo de vida y adjuntos

- Derivar exige ACTIVE, destino activo/coherente y unidad obligatoria. Si se especifica usuario, también funcionario/cargo activos pertenecientes a esa unidad. EDIE exige usuario; otros perfiles permiten unidad sola.
- Unidad sola: current_unit_id=destino, current_user_id=null. Cada operación agrega exactamente un DERIVED. Rechazar reasignación idéntica.
- Concluir/reabrir preservan ownership y registran CONCLUDED/REOPENED con autorización actual. Autorizar antes de exponer estado; bloquear operaciones incompatibles con conclusión.
- Adjuntos: listar/descargar comparten alcance de lectura. Subir/baja lógica requieren responsable actual y ACTIVE. Nunca habilitar mutación por Enviados. Se limita la lectura del upload al máximo permitido.
- Registro y gestión de adjuntos son pasos separados; el formulario indica que el responsable los administra desde el detalle después de transferir ownership.

### PDF y snapshot histórico

`/correspondences/{id}/encadenamiento.pdf` utiliza la autoridad documental, destinatario inicial y movimientos históricos. El snapshot nuevo congela texto/PARA, identidad opcional de autoridad, receptor inicial (también destino ordinario) y `routing_mode=single_initial_recipient` en la misma transacción.
Cambiar settings o maestros no recalcula estos históricos. Se conserva compatibilidad de snapshots anteriores/documentos incompletos. La migración histórica sólo puede congelar los datos disponibles; no reconstruye textos ya perdidos antes del snapshot.
Se probaron PDF, campos heredados y caracteres especiales, sin sustituir el receptor operativo por el nombre del alcalde.

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

Reportes tienen backend productivo, agregados y CSV, protegidos por reports.view y por visibilidad personal/unidad. Consulta pública sigue mostrando indisponibilidad; no genera resultados simulados.
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

Se validó HTTP /api con proxy local y cookie real HttpOnly; Apache/servidor remoto todavía requiere su propia validación. Las pruebas no equivalen a un deploy.
Servidor demo sigue pendiente de actualización, configtest y validación de health, SPA/assets, login, F5 refresh/me y logout.
No se ejecutó deploy ni se tocó Debian durante este cierre.

## 9. Validación del cierre

Suite completa sobre exportación del núcleo committeado, excluyendo WIP:

| Verificación | Resultado |
| --- | --- |
| Backend `pytest tests/` | 298 pasaron |
| Flutter `flutter test` | 488 pasaron |
| Package API / repository / failures | 23 / 27 / 4 pasaron |
| Flutter analyze | 0 errors, 0 warnings; 98 infos |
| Alembic | Una head g2b3c4d5e6f7; migración desde BD nueva correcta |
| Build web API_BASE_URL=/api | Correcto |
| HTTP web /api | Assets/health/BD/login/me/refresh 200; logout 204 y cookie eliminada |
| Smoke funcional | 18 pasos nuevos en Chrome headless/Playwright; todos PASS, sin errores JS |
| git diff --check | Correcto |

Cierre adicional P0/P1: receptor inicial compartido para EDIE, INFORME, NOTA y genérico, matriz perfil × Ventanilla × receptor; validación de receptores activos y error explícito sin configuración. ListenerPro conserva formularios y solo elimina su loading. Boundary ASGI conserva CORS en 500 con respuesta segura; pipeline cliente emite ServerFailure. Baja de adjuntos bloquea y refresca Correspondence antes de evaluar permisos. Smoke real descubrió y resolvió permisos visuales de adjuntos, Reabrir oculto y navegación de logout desde contexto global. Checklist contiene evidencia detallada.

La prueba desde HEAD en PostgreSQL nuevo migró a f2a3b4c5d6e7, inició backend y operó Funcionarios por HTTP 200 sin work_shifts ni employees.work_shift_id. La dependencia observada localmente correspondía al modelo Employee del WIP que sí mapeaba esa columna. El release no contiene ese WIP; base habitual y cambios protegidos permanecen preservados.

Limitaciones históricas aceptadas: participantes de movimientos usan maestros actuales; documentos antiguos sin snapshot pueden conservar referencias históricas parciales; textos anteriores perdidos no pueden reconstruirse. No se amplió el alcance ni se bloqueó QA por ello.

Corrección CRUD `473db9a`. Validación adicional de los cinco CRUD (Unidades, Cargos, Funcionarios, Usuarios y Tipos documentales): tras baja lógica/restauración exitosa se consulta siempre el backend, conservando búsqueda/filtro y ajustando la página. GeneralStatus.success y su feedback se emiten con el listado ya sincronizado; error de recarga conserva el registro desactivado localmente e informa el fallo. Se añadieron 25 regresiones de recarga, paginación, restauración y dependencias. Create/update ya recargan mediante onSuccess.

Antes del ajuste CRUD se comprobó también el árbol local incluyendo WIP: 243 backend, 424 Flutter, packages 21/27/4; sin fallos. Estos números **no** describen el artefacto Correspondencia entregable.
Diagnóstico adicional del entorno local: PATCH de baja de cargo devolvía 500 por SELECT completo de Employee, que incluía work_shift_id del WIP sin columna en la BD real. Se corrigieron las consultas de dependencias institucionales para seleccionar sólo IDs/referencias necesarios, sin migrar Turnos ni cambiar datos. Preflight PATCH respondió 200 con credenciales/origin correctos; validación de baja real pasó en modo sólo lectura. Regresiones específicas: 20 pasaron, incluidas 4 con esquema mínimo sin columnas opcionales.

Infos del analyzer son mejoras de const/estilo y uso de biblioteca web en implementación web; no son warnings. Backend emite dos deprecations de dependencias Starlette/AnyIO y ReportLab, sin fallos funcionales.

Pruebas sobre PostgreSQL y almacenamiento temporales separados, sin reset/clean de datos del usuario. El smoke HTTP usa proxy local que elimina /api y COOKIE_PATH=/api/auth; Apache preparado adapta ese Path mediante ProxyPassReverseCookiePath. Verificar una de estas adaptaciones en el entorno QA real. No se instaló ni desplegó nada en servidor.

### Reparación verificada del entorno local activo

El GET de Funcionarios seguía fallando en el contenedor real por work_shift_id ausente. Tras respaldo completo, se sincronizó esa base con las migraciones del código WIP que ya ejecutaba: ahora está en a3b4c5d6e7f8 (local, no artefacto QA core). Los cinco CRUD pasaron 21 lecturas por red y 75 comprobaciones transaccionales contra esa base; rollback y huellas confirmaron datos existentes intactos. Detalles y límites de verificación: [docs/BASIC_DATA_VALIDATION.md](docs/BASIC_DATA_VALIDATION.md). El código WIP permanece preservado y fuera de los commits.

## 10. WIP excluido y riesgos pendientes

- Preservados por hash 55 archivos protegidos de Turnos/RR.HH., Website, scripts y puntos de integración compartidos. Los hunks compartidos de Endpoints y formulario de funcionario se stagearon selectivamente sin Turnos.
- Permanecen cambios previos de formato y pruebas en Correspondencia/AppSession/grid, y WIP de migraciones, organización y permisos compartidos; no se añadieron automáticamente al cierre.
- Website es otro producto; sus componentes/layout/CSS y commits previos no se confundieron con Flutter.
- `TURNOS_HANDOFF.txt`, work_shifts y sus tests/migración permanecen pausados.
- Scripts clean/reset no se ejecutaron ni stagearon. Sus barreras heurísticas, credenciales fijas y borrado físico no los convierten en herramientas aprobadas.
- Consulta pública sigue **No disponible**, fuera de alcance. Reportes se completaron con backend real y CSV filtrado. Código mock heredado sin ruta activa puede retirarse después.
- Ningún bloqueo A/B conocido queda abierto en el núcleo validado. Las pruebas automatizadas no sustituyen la aceptación manual por QA con sus datos reales.

### Pasos antes de entregar a QA

1. Elegir el árbol committeado de este cierre sin incorporar WIP local.
2. Preparar PostgreSQL/almacenamiento QA aislados, variables y proxy/cookie /api; aplicar Alembic sin reset.
3. Provisionar datos reales activos y cuentas/permissions; configurar Ventanilla, receptores y texto de autoridad.
4. Entregar docs/QA_CHECKLIST.md y ejecutar aceptación manual con esas cuentas/datos.

Push y deploy requieren una instrucción posterior; no forman parte de este cierre.

## 11. Bloques finales en worktree limpio (14/10/2026)

Worktree C:/dev/correspondencia_sipe_sipe_qa_release, rama feature/correspondencia-final, HEAD inicial b28e08b. El original C:/dev/correspondencia_sipe_sipe permanece en develop/61ed753 y no se usa para compilar ni probar. Los 109 WIP se verifican por huellas; ninguna modificación del producto se realiza allí.

Backend/API/repository: 1b898ca; UI: 1abb422. Dashboard usa SQL y visibilidad existente para cinco métricas y diez eventos recientes. Notificaciones internas persistentes y transaccionales, unique por movimiento/usuario, sin actor propio ni funcionarios normales en unidad-only. La campana se actualiza con sesión/badges/operaciones, sin polling ni canales externos; lectura persistida y acceso al Detail siempre revalidado.

Reportes productivos: registrada, recibida, enviada y concluida; reports.view dinámico (seed aditivo ADMIN/MANAGER, custom roles válidos), sin alcance institucional automático. Filtros y agregados SQL compartidos con CSV, paginación AppDataGrid, fechas Bolivia inclusivas y exportación solo del filtro aplicado. No PDF de reporte nuevo. Consulta pública permanece fuera de alcance.

Nuevas migraciones f2a3b4c5d6e7 → g1b2c3d4e5f6 → g2b3c4d5e6f7; una sola head. BD nueva/arranque/operación de los tres bloques probados sin Turnos. Validación detallada y límites: docs/QA_CHECKLIST.md. No notificaciones históricas retroactivas ni actualización push; aceptación manual con datos reales de QA pendiente. Sin push ni deploy.
