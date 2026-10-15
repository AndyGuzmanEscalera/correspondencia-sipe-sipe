# Correspondencia — QA READY

14/10/2026 · `feature/correspondencia-final` · base limpia `b28e08b` · backend/API `1b898ca`, UI `1abb422`.
Sin push ni deploy. No usar el árbol local con WIP de Turnos/RR.HH./Website como artefacto QA.

## Preparación

- BD y almacenamiento QA aislados; variables configuradas sin incluir secretos en este documento. Aplicar `alembic upgrade head` al árbol committeado: head `g2b3c4d5e6f7`. Sin reset ni borrado de volúmenes.
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

Validación sobre el worktree limpio del release, sin WIP. La base limpia transportó 33 commits sin Website. La implementación funcional posterior vive exclusivamente en este worktree; herramientas, credenciales y fixtures del smoke permanecen fuera del repositorio.

- Backend completo: **298**; Flutter completo: **488**; API: **23**; repository: **27**; failures: **4**. Cero tests fallidos.
- Analyzer: **0 errores, 0 warnings, 98 infos**. Exit 1 por infos; no se presenta como exit 0. `git diff --check` correcto en el worktree limpio.
- Alembic: una head **g2b3c4d5e6f7**. `upgrade head` desde PostgreSQL nuevo aislado; backend inicia y health, login, auth/me y listado de Funcionarios devuelven 200. No hay tabla work_shifts ni columna employees.work_shift_id en ese esquema.
- La base habitual necesitó a3b4c5d6e7f8 porque ejecutaba el Employee del WIP, que mapeaba work_shift_id. No es una dependencia del release; no se modificó ni se reseteó esa base durante este cierre.
- Build web **API_BASE_URL=/api** correcto. Proxy local elimina /api y COOKIE_PATH=/api/auth permite cookies y refresh. Sin deploy.
- CORS: excepción interna controlada GET/PATCH → 500 seguro con CORS y credenciales; cliente → ServerFailure. Sin traceback en respuesta.
- Adjuntos: bloqueo de Correspondence y populate_existing actualizan ownership/estado antes de autorizar la baja. Derivación o conclusión concurrente/caché obsoleta bloquean la operación y conservan el adjunto activo.
- ListenerPro elimina exclusivamente su DialogRoute de loading. Regresiones cubren success/error iniciales, loading visible/silencioso y reconstrucción, preservando formularios.

## Smoke anterior del core (13/10/2026)

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

## Validación final: Inicio, Notificaciones y Reportes

Auditoría inicial: Inicio/métricas/badges PARCIAL; notificaciones FALTA; reportes PARCIAL (placeholder y exportación simulada). Los tres bloques quedan IMPLEMENTADOS en esta rama, sin rediseño completo.

### Preparación y permisos

- Migrar desde la cadena limpia: f2a3b4c5d6e7 → **g1b2c3d4e5f6** (notifications) → **g2b3c4d5e6f7** (reports.view). Una sola head, sin a3b4c5d6e7f8 ni dependencia de Turnos.
- `reports.view` se comprueba por permissions efectivos. La migración concede ese permiso de forma aditiva a ADMIN/MANAGER activos; OPERATOR no lo recibe automáticamente. Los nombres de roles se usan exclusivamente para el grant inicial, nunca para autorización runtime. Los roles personalizados pueden recibir el mismo permiso mediante role_permissions, sin alcance adicional.
- Para la prueba de unidad, usar un usuario con funcionario/cargo/unidad activos y `Position.can_view_unit_correspondence=true`. Un usuario normal no debe ver la métrica ni el filtro de toda la unidad.
- No hay permiso global reports.all. La campana y sus endpoints solo muestran notificaciones del usuario autenticado, sin selector user_id.

### Inicio

Métricas SQL: mis pendientes, pendientes de mi unidad cuando corresponde, enviados personales, concluidos y total visible. Actividad reciente limitada a diez movimientos visibles: recepción, derivación, conclusión y reapertura. Acciones de registro/administración/reportes por permissions reales; loading, error con última información real, empty y refresh. Los cambios de badges refrescan Inicio; no se recorren listados completos en Flutter.

### Notificaciones

Modelo persistido: usuario, correspondencia opcional, movimiento para deduplicación, tipo, título, mensaje, leído, creación y lectura. Entrega en la misma transacción de CREATED→DERIVED inicial, DERIVED posteriores y REOPENED. Destinatario directo activo más lectores activos de la unidad con cargo habilitado; unidad-only nunca notifica a funcionarios normales. Unique(movement_id,user_id), exclusión del actor y rollback conjunto del documento/movimiento/notificación.

Campana con badge real, panel paginado responsive, fecha, resumen, marcar una/todas leídas y navegación al Detail normal. Una notificación no concede visibilidad: si el lector perdió scope o el documento cambió de unidad, el endpoint de Detail responde 404. Leer es idempotente y conserva read_at. Conteos/respuestas antiguas no reaparecen después de cambiar sesión o marcar leídas.

Actualización al entrar, refrescar badges/panel y volver de operaciones relevantes. Sin email, WhatsApp, Firebase, WebSockets ni polling. No se generan notificaciones retroactivas de documentos anteriores a la migración.

### Reportes

- **Registrada:** todos los documentos actualmente visibles, fecha de registro.
- **Recibida:** documentos visibles con una recepción dirigida al usuario o a su unidad si tiene scope; fecha de la última recepción aplicable.
- **Enviada:** seguimiento personal existente (creador o actor de derivación), fecha de último envío personal o registro.
- **Concluida:** documentos visibles en estado CONCLUDED, fecha de último cierre.
- Fechas inclusivas en horario Bolivia (UTC−4); tipo documental, estado, unidad actual solo habilitada para el scope propio, funcionario responsable aplicable y búsqueda literal por HR/CITE/asunto/referencia. Rango invertido/fechas inválidas se rechazan. Tipos inactivos con documentos visibles históricos siguen disponibles para filtrar.
- Tabla AppDataGrid con paginación backend. Agregados SQL sobre exactamente el mismo conjunto filtrado: total, pendientes, concluidas, distribución por tipo y por unidad cuando corresponde.
- **CSV productivo** desde backend, todos los resultados del filtro aplicado, no solo la página. Misma autorización, visibilidad y filtros que la tabla; no exporta contactos, documentos personales, credenciales ni campos adicionales ocultos. BOM UTF-8 y escape de celdas con riesgo de fórmula. Streaming por bloques con sesión propia; Flutter descarga bytes y no cuenta miles de filas.
- La exportación existía como intención en la UI anterior simulada. En este cierre inicial se implementó CSV; XLSX y PDF se incorporan en el lote posterior documentado al final. Los controles editados aún sin aplicar no cambian el CSV: utiliza los últimos filtros aplicados.

### Evidencia 14/10/2026

- **298 backend, 488 Flutter, 23 API, 27 repository, 4 failures; cero fallos.** Dos deprecations de dependencias backend conocidas. Analyzer: **0 errors / 0 warnings / 98 infos**, exit 1 por infos.
- PostgreSQL nuevo final_browser: upgrade hasta g2b3c4d5e6f7, backend inicia; Dashboard, Notifications y Reports operaron por HTTP y desde Chrome. Esquema sin work_shifts ni employees.work_shift_id. La suite utiliza otra base temporal final_tests.
- **Chrome/Playwright 18/18 PASS**, únicamente usuarios ficticios: login → métricas → creación desde Inicio → notificación del destinatario → badge → abrir → Detail → lectura persistida → derivar → nueva notificación → reportes con rol personalizado → fechas → tipo/estado → alcance sin bypass de unidad → CSV → logout → login → estado leído persistido. Sin errores JavaScript en la ejecución final. Capturas del Inicio/badge, panel del destinatario y tabla filtrada revisadas visualmente.
- El smoke detectó una excepción intermitente de recarga al cerrar la creación desde Inicio. Se conservó el Cubit de lista en la pantalla dueña y se protegió la respuesta tardía después del cierre; regresiones y nuevo smoke confirmaron la corrección. Se sincronizan badges/Inicio/Reportes al volver del detalle y se descartan respuestas de sesiones anteriores.
- No se repitió el smoke previo de 17 pasos del core: permanece como evidencia anterior. El flujo nuevo usa el mismo core sin cambiar sus reglas de ownership.

### Comprobaciones adicionales para QA con sus datos

Verificar dos usuarios de unidades distintas y uno con scope unidad; rol personalizado con reports.view y roles sin ese permiso; revocar scope y abrir una notificación histórica (404); recepción directa/unidad-only, lectura parcial/todas y persistencia tras recarga; paginación y CSV con más de una página; filtros vacíos/invalidación/errores de red; 390px y escritorio. No provisionar personas reales en migraciones.

## Incidencias aceptadas y alcance

Sin bloqueos A/B conocidos. Se aceptan infos de const/estilo/biblioteca web y dos avisos de deprecación de dependencias backend (Starlette/AnyIO y ReportLab). No son fallos ni warnings de analyzer.
- Históricos: nombres de participantes de movimientos todavía se resuelven desde maestros actuales; documentos antiguos sin snapshot pueden usar referencias históricas parciales; textos perdidos antes del snapshot no se pueden reconstruir. Limitación aceptada, sin refactor ni bloqueo QA.

Consulta pública: **No disponible**, fuera de alcance. Reportes ahora son productivos, con CSV y fuente backend real. Código mock antiguo sin ruta activa queda como limpieza posterior.
Fuera de alcance: Turnos, Asistencia, RR.HH., Website, módulos nuevos, refactors/cosmética y despliegue remoto. Los WIP respectivos permanecen preservados.

## Entorno de aceptación QA

Seleccionar el árbol committeado, preparar entorno QA aislado/proxy, aplicar migraciones sin reset, configurar datos/cuentas reales y entregar este checklist para aceptación manual. No publicar ni desplegar sin nueva instrucción.


## Lote previo a QA: presentación institucional y exportaciones (14/10/2026)

Base: develop 300ede1, coincidente con origin/develop al iniciar. Trabajo en el repo principal; sin Turnos/RRHH, Website ni scripts clean/reset. No push ni deploy.

### Identidad e Inicio

- Auditoría: el Dashboard anterior no usaba escudo/imagen, pero las tarjetas tenían iconos grandes, padding/sombras y la actividad una Card por fila. Los iconos web eran los cinco PNG predeterminados de Flutter. No había un escudo institucional verificable en los assets de esta rama; no se copió ni modificó Website.
- Se usa cabecera **tipográfica**, con Gobierno Autónomo Municipal de Sipe Sipe y Sistema de Gestión de Correspondencia. El saludo y cargo/unidad provienen de la sesión. No se generó ni reinterpretó un escudo.
- Marca neutra del sistema: **web/document-mark.svg**, documento lineal blanco sobre verde sobrio, únicamente favicon/PWA; sustituye los PNG stock Flutter. No representa un símbolo oficial. El Dashboard y PDF usan tipografía, sin logo inventado.
- Métricas reales compactas, número protagonista, icono funcional de 20px, borde fino, sin sombras. Distribución adaptable al espacio. Actividad continua con separadores, HR, evento, asunto resumido y fecha Bolivia; fecha debajo en móvil. Acciones por los mismos permisos dinámicos; la campana conserva su modelo, eventos y badge.
- Sin cambios al DashboardCubit ni a las consultas de métricas/visibilidad ni a los eventos de notificaciones. Cabecera superior compacta y adaptable; revisión visual a 1440, 820 y 390px sin overflow.

### Exportaciones productivas

- CSV conservado con su consulta/stream y protección de fórmulas; filename útil según tipo/periodo. Nuevos GET /reports/export.xlsx y /reports/export.pdf.
- Todos usan el mismo dependency reports.view, filtros tipados y InsightsService.query/rows_query que el reporte. Nunca se acepta un scope privilegiado del cliente. Unidad/funcionario ajenos se rechazan; no se exportan UUID, contactos ni datos personales adicionales.
- XLSX real desde backend: **openpyxl 3.1.5**. Hoja Correspondencia, cabecera institucional, tipo/periodo/filtros/generación Bolivia, resumen, siete columnas, anchos razonables, wrap, filtro y encabezado congelado A11. Textos de usuario explícitamente de tipo string, sin fórmulas/hipervínculos ejecutables.
- PDF desde backend reutiliza **ReportLab 4.2.5**, en el mismo módulo pdf del proyecto. A4 horizontal, cabecera institucional y de tabla repetida, Paragraph con texto escapado y wrap, LongTable con división de filas largas, márgenes y pie Página X de Y. No se introdujo otro motor PDF.
- Flutter: Exportar ofrece CSV / Excel (.xlsx) / PDF; estado Exportando, bloqueo durante carga/generación y errores por el pipeline Result/Failure. Descarga bytes mediante el servicio existente y utiliza los últimos filtros aplicados, nunca el borrador ni URLs externas.
- El smoke detectó que un botón deshabilitado anidado en PopupMenuButton perjudicaba semántica/interacción; se sustituyó por un solo control y se repitieron Flutter, analyzer, build y smoke sobre el código corregido.

### Validación aprobada de este lote

- Backend completo: **318 passed**, cero fallos, dos deprecations conocidas de dependencias.
- Flutter completo: **498 passed**, cero fallos. API **26**, repository **30**, failures **4**.
- Analyzer: **0 errors / 0 warnings / 98 infos**, exit 1 por infos. Build web local /api: correcto. git diff --check: correcto.
- Alembic: una sola head **g2b3c4d5e6f7**, sin nueva migración. PostgreSQL nuevo exports_tests y exports_browser con upgrade desde cero; sin Turnos. Bases y usuarios exclusivamente ficticios y aislados.
- Backend incluye 20 pruebas nuevas: validez de formatos, CSV, filtros/fechas/tipo/estado, scope personal/unidad, permiso obligatorio, fuera de alcance 403, ausencia de filas privadas, texto/fórmulas XLSX y PDF multipágina con texto mayor que una página.
- Chrome/Playwright: **18/18 pasos PASS**, sin errores JavaScript. Login, Inicio, identidad tipográfica, métricas, actividad, acciones, campana/panel, desktop/tablet/mobile, Reportes, CSV/XLSX/PDF, filtros y reexportación de los tres, 403 para unidad ajena en los tres.
- Apertura real de los archivos descargados: XLSX válido y legible por openpyxl; PDF válido y legible por pypdf. Los tres contienen exactamente las mismas **64 HR visibles**, no solo las 20 de la página. El filtro HR-QA-0001 produce exactamente **una fila** en cada formato. Los cuatro registros privados ajenos no aparecen.
- PDF de 64 filas: **8 páginas**, numeración y encabezados repetidos verificados; todas las páginas renderizadas y revisadas, sin texto fuera de márgenes ni solapamientos. PDF filtrado: 1 página. Capturas del Inicio a los tres anchos y Reportes revisadas.
- Evidencia local (no versionada): %TEMP%/codex-ui-exports-20261014; screenshots, logs, smoke-results.json y artifact-validation.json. smoke-private.json contiene solo la credencial temporal sintética y no se comparte ni commitea.

### Revisión de QA pendiente

Aceptación del usuario del diseño y validación con datos/perfiles del entorno QA cuando se autorice el deploy. Este lote no publica ni despliega. Se mantienen los 98 infos de estilo y las dos deprecaciones ya conocidas.


## Identidad oficial GAM Sipe Sipe — 15/10/2026

Base e7f50aa en develop. El usuario aportó ocho PNG oficiales y registró assets/images en pubspec; se preservaron esos originales y su pubspec previo en C:/dev/repo_backups/branding_originales_20261015 con SHA256. Se publican únicamente copias técnicas de identidad permanente en assets/branding. No hay gestión/autoridad fija en las imágenes productivas. Procedencia y variantes en assets/branding/README.md.

- Retirado web/document-mark.svg y los iconos account_balance que actuaban como logos en Login/Sidebar. Los iconos funcionales de menú, campana, reportes, usuarios, etc. permanecen.
- Login y Dashboard amplios: escudo oficial horizontal a color. Mobile: escudo compacto íntegro extraído de la variante vertical más nombre institucional y nombre del sistema. Sidebar/drawer: aplicación digital 02 blanca sobre fondo oscuro. Las variantes se muestran sin tint ni deformación; se comprobó transparencia sobre el fondo real. Se conservan también las variantes verticales y compacto blanco para futuras superficies justificadas.
- Favicon/PWA: escudo oficial PNG a 32/192/512px. No se generan isotipos. Las imágenes de gestión quedan fuera de Flutter y backend. No se usan nombres/personas/gestión fijos como branding.
- Verde #08813A extraído del wordmark oficial; blanco y neutros claros; estados siguen usando sus colores semánticos y etiquetas. Tokens centralizados en UiColors y branding.py. Se retira el gradiente de login, sin implementar dark mode ni rediseñar flujos. Botones, chips, formularios, dropdowns, tablas, AppDataGrid, paginación y diálogos heredan el mismo theme.
- PDFs EDIE y Reportes: escudo oficial de alta calidad incluido dentro del paquete backend app/assets/branding; cabeceras también en páginas de continuación. Se elimina el recuadro genérico SIPE/SIPE del PDF documental y se usa el lema contenido en el recurso oficial. Se mantiene identificación institucional, tablas, datos, filtros, totales y paginación. XLSX conserva cabecera textual limpia y solo alinea el color. CSV no cambió.
- Sin cambios a Cubits, permisos, visibilidad, ownership, métricas, notificaciones, flujo CREATED→DERIVED, rutas/API, servicios ni reglas de exportación. No nueva migración; head g2b3c4d5e6f7. Turnos/Website y scripts excluidos.

### Validación final

- **Flutter 503 PASS**, **backend 321 PASS**, cero fallos. Las pruebas backend afectadas (branding/EDIE/exportaciones) también pasaron: **34 PASS**. Dos deprecations backend conocidas de dependencias.
- Analyzer **0 errors / 0 warnings / 98 infos** (exit 1 por infos). Build web local correcto. git diff --check correcto.
- Nuevas pruebas verifican assets exactos, ausencia de tint, BoxFit.contain, semántica/alt y contraste AA; PDF con imagen en todas sus páginas y conservación de contenido. Se detectó y corrigió el prefijo hexadecimal requerido por ReportLab y se repitieron pruebas backend y smoke sobre la corrección.
- Chrome/Playwright **13/13 PASS**, cero JS errors; solo usuarios y bases ficticios aislados. Capturas de Login desktop/mobile, Dashboard desktop/tablet/mobile, sidebar expandido, drawer cerrado y abierto, Reportes y Notificaciones. La aplicación no tiene rail plegable productivo: “colapsado” corresponde a sidebar oculto con botón Menú; no se agregó navegación nueva.
- Reporte PDF descargado por la UI: **9 páginas**, **64 HR visibles**, sin registros privados; EDIE descargado por HTTP autenticado: 1 página; EDIE con ocho destinatarios: 2 páginas. Todos renderizados y revisados: escudo sin deformación/transparencia incorrecta, sin solapamientos ni cortes, cabeceras de continuación correctas. El mayor espacio de cabecera institucional modifica solo distribución de páginas, no datos.
- Evidencia local no versionada: %TEMP%/codex-branding-qa-20261015. Credencial sintética privada no incluida en commits. Originales verificados por SHA256 después de la integración.

No quedan logos provisionales en las superficies revisadas. Las variantes no usadas de identidad permanente están documentadas; los textos de gestión están solo en el respaldo externo. Pendiente aceptación visual del usuario. **No push ni deploy.**
