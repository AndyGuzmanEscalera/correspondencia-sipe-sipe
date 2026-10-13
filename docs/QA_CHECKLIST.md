# Correspondencia — QA READY

13/10/2026 · develop · cierre funcional: backend `585b3da`, cliente `3ead534`.
Sin push ni deploy. No usar el árbol local con WIP de Turnos/RR.HH./Website como artefacto QA.

## Preparación

- BD y almacenamiento QA aislados; variables configuradas sin incluir secretos en este documento. Aplicar `alembic upgrade head` al árbol committeado: head `f2a3b4c5d6e7`. Sin reset ni borrado de volúmenes.
- Unidades, cargos, funcionarios, usuarios vinculados y tipos documentales activos. Cuentas para creador, responsable, ajeno, lector de unidad y administración; proporcionar credenciales por canal separado.
- `correspondence.create` en roles activos para creadores; `Position.can_view_unit_correspondence` para el lector de unidad. Read/manage de maestros y settings según tarea; roles.assign sólo para asignación de roles.
- Configurar `institutional.intake_unit_id`, `institutional.initial_recipient_employee_ids` y `institutional.mayor_display_name`. Receptores con funcionario/cargo/unidad/usuario activos. La autoridad documental no es ownership operativo.
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

## Evidencia del cierre

- Backend completo: **219**; Flutter completo: **426**; API: **18**; repository: **24**; failures: **4**. Cero fallos.
- Analyzer: **0 errores, 0 warnings, 93 infos** no bloqueantes. `git diff --check` correcto.
- Una head Alembic `f2a3b4c5d6e7`; migración probada desde PostgreSQL nuevo aislado.
- Build web /api correcto. Smoke HTTP local: web/assets/health/BD/login/me/refresh 200, logout 204; cookie real HttpOnly /api/auth eliminada al salir.
- Smoke de negocio mediante suites de integración y widgets, incluido ciclo completo en `backend/tests/test_qa_smoke.py`; aceptación visual/manual del entorno real corresponde a QA.

## Incidencias aceptadas y alcance

Sin bloqueos A/B conocidos. Se aceptan infos de const/estilo/biblioteca web y dos avisos de deprecación de dependencias backend (Starlette/AnyIO y ReportLab). No son fallos ni warnings de analyzer.
Reportes y consulta pública: **No disponible**, sin simulaciones; backend productivo queda post-QA. Código mock antiguo sin ruta activa queda como limpieza posterior.
Fuera de alcance: Turnos, Asistencia, RR.HH., Website, módulos nuevos, refactors/cosmética y despliegue remoto. Los WIP respectivos permanecen preservados.

## Entrega pendiente

Seleccionar el árbol committeado, preparar entorno QA aislado/proxy, aplicar migraciones sin reset, configurar datos/cuentas reales y entregar este checklist para aceptación manual. No publicar ni desplegar sin nueva instrucción.
