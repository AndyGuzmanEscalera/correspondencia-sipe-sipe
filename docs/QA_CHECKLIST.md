# Correspondencia — QA READY

13/10/2026 · develop · cierre P0/P1: `f8b0488` a `7914ace` (antes del commit documental).
Sin push ni deploy. No usar el árbol local con WIP de Turnos/RR.HH./Website como artefacto QA.

## Preparación

- BD y almacenamiento QA aislados; variables configuradas sin incluir secretos en este documento. Aplicar `alembic upgrade head` al árbol committeado: head `f2a3b4c5d6e7`. Sin reset ni borrado de volúmenes.
- Unidades, cargos, funcionarios, usuarios vinculados y tipos documentales activos. Cuentas para creador, responsable, ajeno, lector de unidad y administración; proporcionar credenciales por canal separado.
- `correspondence.create` en roles activos para creadores; `Position.can_view_unit_correspondence` para el lector de unidad. Read/manage de maestros y settings según tarea; roles.assign sólo para asignación de roles.
- **Antes de probar Ventanilla:** entrar a Datos básicos → Institucional con permiso manage; seleccionar la unidad de Ventanilla, abrir “Receptores iniciales de Alcaldía”, buscar y seleccionar uno o varios funcionarios y guardar. Para los dos secretarios, seleccionar ambos. Verificar al volver a abrir que ambos permanecen seleccionados. Cada receptor necesita funcionario, cargo, unidad y usuario vinculados activos. No elegir personas por nombres de rol ni copiar IDs del smoke.
- Esa UI guarda `institutional.intake_unit_id`, `institutional.initial_recipient_employee_ids` y `institutional.mayor_display_name`. Sin receptores configurados, crear desde Ventanilla devuelve 422 con un mensaje claro y no consume numeración ni crea movimientos. La autoridad documental no es ownership operativo; no se insertaron personas reales ni IDs fijos en migraciones.
- Build con `API_BASE_URL=/api`. Proxy elimina /api; adaptar cookie a /api/auth mediante proxy (Apache ya preparado) o COOKIE_PATH equivalente. Comprobar refresh tras recarga y logout en ese entorno.

## Escenarios y resultados esperados

| # | Escenario | Resultado esperado |
| --- | --- | --- |
| 1 | Login, refresh y logout | Sesión válida; cookie HttpOnly; refresh conserva sesión y logout la elimina. |
| 2 | Crear EDIE, INFORME y NOTA | Permiso dinámico y origen/destino válidos; error conserva formulario; sin doble envío. |
| 3 | Historial inicial | Exactamente CREATED + un DERIVED; sin segundo destino automático. |
| 4 | Inbox del destinatario | Documento asignado visible; detalle/acciones coherentes. |
| 5 | Funcionario ajeno | No aparece en Inbox; ID directo fuera de alcance devuelve 404. |
| 6 | Cargo con lectura de unidad | Lee unidad actual; no muta asignación de otro responsable activo. |
| 7 | Derivar a otra unidad | Cuando perfil permite unidad sola, usuario actual queda null; exactamente un DERIVED. |
| 8 | Derivar a funcionario | Usuario/funcionario/cargo activos y unidad coherente; EDIE exige usuario. |
| 9 | Remitente en Enviados | Conserva seguimiento legítimo tras transferencia. |
| 10 | Remitente intenta operar | can_operate=false; derivar/concluir/mutar adjuntos bloqueado. |
| 11 | PDF | Autoridad y receptor históricos, movimientos y caracteres especiales correctos. |
| 12 | Adjuntos | Listar/descargar según lectura; subir/baja lógica sólo responsable ACTIVE. |
| 13 | Concluir | Responsable concluye; movimiento CONCLUDED; operaciones incompatibles bloqueadas. |
| 14 | Reabrir | Responsable autorizado; REOPENED; ownership preservado. |
| 15 | Baja de maestro sin dependencia | Baja lógica, desaparece de selectores nuevos, histórico permanece. |
| 16 | Baja con dependencia | Bloqueada, incluida configuración institucional y responsabilidad activa. |
| 17 | Restaurar maestro | Manage requerido; vuelve al catálogo activo. |
| 18 | Cambiar configuración | Afecta nuevos registros; documentos/PDF anteriores conservan snapshot. |

En los cinco CRUD, eliminar/restaurar debe recargar desde backend sin esperar a cerrar el mensaje de éxito, conservar búsqueda/filtro y rellenar o ajustar la página. Si una dependencia bloquea la baja, conservar fila y mostrar el motivo.

Además comprobar Mis documentos/De mi unidad/Enviados, filtros/búsqueda/paginación, refresh, vacío/loading/error, apertura/cierre de formularios y escritorio/pantalla estrecha. Validar Ventanilla y creador externo, rol personalizado con create y rol llamado ADMIN sin create; no autorizar por nombres. Configuración read-only debe impedir guardar. Selecciones inactivas no pueden usarse para nuevos registros.

Errores 400/422 muestran validación; 403 falta de autorización; 404 recurso inexistente/no visible; 409 dependencia/conflicto; 500 mensaje seguro. Sin excepción cruda, diálogo duplicado ni cierre del formulario en error.

## Evidencia del cierre P0/P1

Validación sobre exportación del árbol versionado del release, sin WIP. Los 661 archivos versionados coinciden con HEAD (normalizando únicamente CRLF/LF); las herramientas y fixtures del smoke están fuera del repositorio.

- Backend completo: **272**; Flutter completo: **454**; API: **19**; repository: **24**; failures: **4**. Cero tests fallidos.
- Analyzer: **0 errores, 0 warnings, 93 infos**. Exit 1 por infos; no se presenta como exit 0. `git diff --check` correcto (Git avisa únicamente conversiones LF/CRLF en WIP previo).
- Alembic: una head **f2a3b4c5d6e7**. `upgrade head` desde PostgreSQL nuevo aislado; backend inicia y health, login, auth/me y listado de Funcionarios devuelven 200. No hay tabla work_shifts ni columna employees.work_shift_id en ese esquema.
- La base habitual necesitó a3b4c5d6e7f8 porque ejecutaba el Employee del WIP, que mapeaba work_shift_id. No es una dependencia del release; no se modificó ni se reseteó esa base durante este cierre.
- Build web **API_BASE_URL=/api** correcto. Proxy local elimina /api y COOKIE_PATH=/api/auth permite cookies y refresh. Sin deploy.
- CORS: excepción interna controlada GET/PATCH → 500 seguro con CORS y credenciales; cliente → ServerFailure. Sin traceback en respuesta.
- Adjuntos: bloqueo de Correspondence y populate_existing actualizan ownership/estado antes de autorizar la baja. Derivación o conclusión concurrente/caché obsoleta bloquean la operación y conservan el adjunto activo.
- ListenerPro elimina exclusivamente su DialogRoute de loading. Regresiones cubren success/error iniciales, loading visible/silencioso y reconstrucción, preservando formularios.

## Smoke real en Chrome

Playwright en Chrome headless, autorizado por el usuario, contra **browser_qa** y almacenamiento separados, únicamente con actores ficticios. Se operaron controles reales del build; las llamadas auxiliares verificaron payloads, ownership, movimientos y SHA-256. No se sustituyeron interacciones de negocio por llamadas API.

| # | Paso | Resultado |
| --- | --- | --- |
| 1 | Login | PASS; sesión real y refresh cookie |
| 2 | Configuración institucional | PASS; pantalla abierta |
| 3 | Receptores iniciales | PASS; dos seleccionados y guardados por UI |
| 4 | EDIE desde Ventanilla | PASS; POST 201, receptor correcto |
| 5 | INFORME desde Ventanilla | PASS; POST 201, receptor correcto |
| 6 | NOTA desde Ventanilla | PASS; POST 201, receptor correcto |
| 7 | Historial inicial | PASS; exactamente CREATED + DERIVED en los tres |
| 8 | Inbox destinatario | PASS; tres asignados al receptor |
| 9 | De mi unidad | PASS; lector ve registros ajenos sin mutaciones |
| 10 | Enviados | PASS; creador conserva seguimiento de los tres |
| 11 | Detail | PASS; ownership/estado y acciones coherentes |
| 12 | Movements | PASS; tabla inicial y final |
| 13 | PDF | PASS; botón real, 200, %PDF; autoridad y receptor en el documento |
| 14 | Adjuntos | PASS; carga 201, lista actualizada, descarga con SHA-256 idéntico al original |
| 15 | Derivar | PASS; destino recibe y antiguo responsable pierde controles |
| 16 | Concluir | PASS; CONCLUDED bloquea mutaciones y permite Reabrir al responsable |
| 17 | Reabrir | PASS; ACTIVE, mismo responsable, cinco movimientos sin duplicados |

Fallos reales encontrados y corregidos en el smoke: controles de adjuntos visibles para lectores históricos (`28b41ef`), Reabrir oculto en CONCLUDED (`a92cbb4`) y excepción del listener global al cerrar sesión desde arriba del Router (`7914ace`). Regresiones y nueva ejecución Chrome confirmaron los ajustes. Las dificultades de sincronización/semántica/scroll del runner no se registran como fallos del producto.

El ciclo final es CREATED → DERIVED → DERIVED → CONCLUDED → REOPENED. Capturas locales revisadas: configuración, detalle con adjunto y detalle final. Esta aceptación automatizada local no equivale a un despliegue ni a aceptación manual con datos reales de QA.

## Incidencias aceptadas y alcance

Sin bloqueos A/B conocidos. Se aceptan infos de const/estilo/biblioteca web y dos avisos de deprecación de dependencias backend (Starlette/AnyIO y ReportLab). No son fallos ni warnings de analyzer.
- Históricos: nombres de participantes de movimientos todavía se resuelven desde maestros actuales; documentos antiguos sin snapshot pueden usar referencias históricas parciales; textos perdidos antes del snapshot no se pueden reconstruir. Limitación aceptada, sin refactor ni bloqueo QA.

Reportes y consulta pública: **No disponible**, sin simulaciones; backend productivo queda post-QA. Código mock antiguo sin ruta activa queda como limpieza posterior.
Fuera de alcance: Turnos, Asistencia, RR.HH., Website, módulos nuevos, refactors/cosmética y despliegue remoto. Los WIP respectivos permanecen preservados.

## Entorno de aceptación QA

Seleccionar el árbol committeado, preparar entorno QA aislado/proxy, aplicar migraciones sin reset, configurar datos/cuentas reales y entregar este checklist para aceptación manual. No publicar ni desplegar sin nueva instrucción.
