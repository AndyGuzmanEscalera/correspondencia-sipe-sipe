# Cierre de Correspondencia — 16/10/2026

Repositorio: `C:\dev\correspondencia_sipe_sipe`, rama `develop`.
HEAD inicial: `c6566d1e830379883f3f942a1588b2cb333578b7`. Referencia remota inicial: `e7f50aa4d8d818e0bc6384110016dd4478b919de`.
Este lote no ejecuta push ni deploy. No cambia Website ni Turnos/RR.HH., no envía correo y no aplica cambios a la base habitual.

## Resultado y límite

Se consolidaron los 31 archivos previos del cierre, se corrigió la presentación de hora Bolivia, se centralizó la redacción de credenciales y se protegió la continuidad administrativa. El código queda validado contra bases PostgreSQL nuevas aisladas, sin Turnos.

**P0 pendiente si se reutiliza la base habitual:** su revisión `a3b4c5d6e7f8` no pertenece al grafo actual. Tiene datos persistidos de Turnos y requiere una reconciliación aprobada y ensayada sobre copia. No está habilitado un upgrade ordinario de esa base. Véase [plan detallado](DB_RECONCILIATION_PLAN.md). No se creó migration bridge ni se cambió su revisión.

## Ocho commits locales que ya existían

```text
c6566d1 feat(settings): agrega correo institucional configurable
12da769 feat(correspondence): permite derivación por alcance de unidad
5617802 docs(deploy): documenta estrategia api y cors definitiva
f76f19b test(cors): valida orígenes locales y rutas api por entorno
ba5871d fix(network): adopta api same-origin para qa y producción
a7a6b58 docs(qa): registra validación final de branding
b1c1ca5 fix(reports): usa escudo oficial en PDFs institucionales
6c3a98a refactor(branding): aplica identidad oficial del GAM Sipe Sipe
```

## Inventario previo: 25 modified + 6 untracked

Clasificación por responsabilidad principal: A=9, B=1, C=7, D=3, E=11, F=0. Los tests de un cambio funcional se clasifican E. No se identificaron archivos ajenos; los 31 se conservaron y consolidaron con stage explícito. El primer commit consolida 27 archivos y el segundo los cuatro del polling, incluido su test.

| Archivo | Estado inicial | Clasificación |
|---|---|---|
| `backend/app/modules/correspondence/document_type_profiles.py` | modified | A — cierre funcional actual |
| `backend/app/modules/correspondence/pdf/encadenamiento_pdf.py` | modified | B — PDF EDIE |
| `lib/core/app/views/app_body.dart` | modified | D — notificaciones/polling |
| `lib/core/platform/file_download_platform_stub.dart` | modified | A — cierre funcional actual |
| `lib/core/platform/file_download_platform_web.dart` | modified | A — cierre funcional actual |
| `lib/core/platform/file_download_service.dart` | modified | A — cierre funcional actual |
| `lib/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart` | modified | A — cierre funcional actual |
| `lib/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart` | modified | A — cierre funcional actual |
| `lib/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart` | modified | A — cierre funcional actual |
| `lib/features/correspondence/detail/views/correspondence_detail_body.dart` | modified | C — branding/UI |
| `lib/features/correspondence/detail/widgets/correspondence_detail_header.dart` | modified | C — branding/UI |
| `lib/features/correspondence/detail/widgets/correspondence_info_section.dart` | modified | C — branding/UI |
| `lib/features/correspondence/detail/widgets/correspondence_info_tile.dart` | modified | C — branding/UI |
| `lib/features/correspondence/domain/document_type_profiles.dart` | modified | A — cierre funcional actual |
| `lib/features/home/side_menu/widgets/side_menu_widget.dart` | modified | C — branding/UI |
| `lib/features/inbox/cubit/inbox_entry_cubit.dart` | modified | A — cierre funcional actual |
| `lib/features/inbox/views/inbox_entry_body.dart` | modified | C — branding/UI |
| `lib/features/notifications/cubit/notifications_cubit.dart` | modified | D — notificaciones/polling |
| `lib/shared/widgets/app_form_dialog.dart` | modified | C — branding/UI |
| `test/features/correspondence/correspondence_document_actions_cubit_test.dart` | modified | E — pruebas |
| `test/features/correspondence/detail/correspondence_detail_body_test.dart` | modified | E — pruebas |
| `test/features/correspondence/detail/correspondence_detail_header_test.dart` | modified | E — pruebas |
| `test/features/correspondence/document_type_profiles_test.dart` | modified | E — pruebas |
| `test/features/inbox/inbox_entry_body_test.dart` | modified | E — pruebas |
| `test/features/inbox/inbox_entry_cubit_test.dart` | modified | E — pruebas |
| `backend/tests/test_chaining_catalog_code.py` | untracked | E — pruebas |
| `backend/tests/test_encadenamiento_legal_layout.py` | untracked | E — pruebas |
| `lib/features/notifications/views/notifications_monitor.dart` | untracked | D — notificaciones/polling |
| `test/features/correspondence/detail/correspondence_info_layout_test.dart` | untracked | E — pruebas |
| `test/features/notifications/notifications_polling_test.dart` | untracked | E — pruebas |
| `test/shared/widgets/desktop_scrollbar_regression_test.dart` | untracked | E — pruebas |

Los SHA-256 y el status originales se registraron fuera del repositorio en `%TEMP%/codex-closure-20261016/initial.json` antes de editar.

## Política temporal y auditoría de presentación

- DB/API conservan instantes UTC. No hubo cambios de almacenamiento, payloads ni migraciones de datos.
- Backend: helper `app/core/institutional_time.py` con `ZoneInfo("America/La_Paz")`; EDIE lo usa al imprimir FECHA/HORA. Reportes comparte la misma constante institucional. Instantes históricos sin zona se interpretan como UTC en el helper backend.
- Flutter: `institutionalDate` convierte el instante original a UTC y presenta UTC−04:00, independiente de la zona del navegador. Un offset explícito −04:00 no se aplica dos veces. El valor desplazado es solo presentación y no se persiste.
- Detalle, adjuntos, fecha de listado y render genérico dateTime usan el helper. Movimientos, notificaciones y otras superficies que ya lo usaban lo conservan. Las fechas civiles sin hora no se desplazan; el listado de Correspondencia aplica explícitamente la fecha institucional porque proviene de un timestamp.
- Pruebas: 15/10/2026 15:32Z → 15/10/2026 11:32; 16/10/2026 02:05Z → 15/10/2026 22:05. El detalle y el PDF verifican resultados de presentación, no solo el helper.

## N.º HOJAS y PDF EDIE

No existe un campo funcional de hojas/fojas en el modelo o snapshot documental. `total_pages` corresponde a paginación de respuestas de listados; no representa hojas físicas. Los adjuntos tampoco constituyen ese dato.

Se conserva intencionalmente `N.º HOJAS: —`, sin nueva columna, inferencia ni conteo automático de PDF. El builder documenta la decisión. Se mantiene Legal **612 × 1008 puntos**, escudo oficial, PARA/DE/REFERENCIA, primer destinatario, derivaciones unit-only o con funcionario, espacios de firma/sello/proveído y continuaciones. Los tests de PDF comprueban hora Bolivia, N.º hojas desconocido y generación multipágina. No hubo otro rediseño.

## Logger

`AppLogger.sanitize` es la autoridad compartida por ApiLogger y logs de errores. Oculta valores completos de password, initial_password, new_password, current_password, token, access_token, refresh_token, authorization, cookie y secret, además de variantes equivalentes y claves adicionales sensibles. Reconoce mayúsculas, camelCase, guiones y underscores; procesa mapas/listas y JSON anidado.

Los mensajes API con prefijo y JSON mantienen los campos normales, con secretos `***`. Para texto no estructurado se oculta el resto de la línea desde la clave sensible para evitar filtraciones parciales, incluidas comillas escapadas/incompletas. No se cambió ningún flujo de contraseñas.

## Continuidad administrativa

- Backend rechaza autobaja con HTTP 409: «No puede desactivar su propia cuenta.» Flutter oculta Eliminar para la cuenta en sesión.
- Una cuenta administradora operativa debe estar activa y reunir **todos** los permisos `master_data.users.manage`, `master_data.roles.assign`, `system.settings.manage`, mediante la unión de sus roles activos. No se autorizan acciones por nombres ADMIN/MANAGER/OPERATOR.
- Si existe funcionario vinculado, funcionario, cargo y unidad deben estar activos. Se admite la cuenta bootstrap sin funcionario, conforme al modelo actual de autenticación.
- No se permite desactivar al último administrador operativo ni quitarle roles críticos sin alternativa válida. Las reducciones de capacidad comparten bloqueo transaccional de las filas de permisos críticos para serializar estas operaciones.
- Las demás restricciones de baja lógica se conservan. No se extienden privilegios de MANAGER/OPERATOR ni la regla de derivación a otras mutaciones.
- Diez pruebas backend cubren autobaja, último administrador, alternativa válida/no válida, usuario normal, bajas sucesivas y retirada de roles. Una prueba Flutter comprueba visibilidad de la acción por cuenta.

## Consolidación funcional previa

Se conservaron apertura del PDF generado mediante bytes autenticados, tratamiento del código completo de Encadenamiento, detalle adaptable, página independiente de derivación, bandeja de unidad por defecto y estilos institucionales. Las notificaciones consultan cada 60 segundos y presentan novedades mediante el monitor, con pruebas de deduplicación/ciclo de vida. La consolidación no altera permisos de reportes, correo institucional ni arquitectura same-origin/CORS.

## Validación final

| Comprobación | Resultado |
|---|---|
| Backend, `pytest tests/` | **396 passed**, 0 fallos; 2 deprecaciones de dependencias |
| Flutter, `flutter test` | **540 passed**, 0 fallos |
| correspondencia_api | **41 passed** |
| correspondencia_repository | **31 passed** |
| failures | **6 passed** |
| `flutter analyze` | **0 errors / 0 warnings / 98 infos** previos; exit 1 por infos |
| `git diff --check` | Correcto |
| `alembic heads` | Una sola head: **g2b3c4d5e6f7** |
| PostgreSQL nuevo, upgrade desde cero | Correcto, sin Turnos |
| Backend real HTTP en base vacía | /health 200, /health/database 200, /auth/login 200, /auth/me 200, /admin/employees 200 |

Backend se ejecutó en PostgreSQL temporal `closure_qa`. El arranque HTTP se comprobó en una segunda DB nueva `closure_smoke`, migrada desde cero; se creó exclusivamente una cuenta ficticia con rol y permiso de lectura de Funcionarios. Su listado vacío devolvió 200 y cero registros, no error del servidor. Se verificó ausencia de `work_shifts` y `employees.work_shift_id`. No se usó la DB habitual para tests o seeds. No se repitió smoke Chrome en este lote; la cobertura UI aquí es por widgets y la de arranque por HTTP.

Evidencia local: `%TEMP%/codex-closure-20261016/` (backend.log, flutter-final.log, logs por paquete, analyzer-final.log, smoke.log y snapshots de auditoría read-only antes/después). No se versionan credenciales ni datos privados de fixtures.

## Commits del lote anteriores a esta documentación

```text
b9e1d8f fix(correspondence): consolida ajustes finales de detalle y PDF
a1a827c feat(notifications): consulta novedades cada 60 segundos
80eca5c fix(datetime): normaliza presentación institucional a hora Bolivia
f6f2fd7 fix(logging): oculta credenciales sensibles en logs
c430799 fix(admin): protege continuidad de cuentas administrativas
```

El commit de esta documentación se identifica por `docs(db): documenta reconciliación de base local con develop`. HEAD final e índice/status se informan después de crearlo; no se incluye un hash autorreferencial en este archivo.

## Pendiente antes del deploy

- **P0 condicional a reutilizar la base habitual:** decidir y ensayar su reconciliación o una transferencia controlada de Correspondencia a una base limpia, preservando los datos existentes. El esquema auditado y los datos de Turnos permanecieron iguales al repetir la lectura al terminar las validaciones.
- P1 solicitados de hora, logger y protección de bajas administrativas quedan resueltos y cubiertos por tests.
- Los 98 infos del analyzer y las dos deprecaciones permanecen registrados. No son errores/warnings nuevos.
- Publicación y deploy requieren una instrucción posterior. No se accedió a Debian ni se modificó Apache del servidor. El correo institucional sigue siendo solo configuración; no se agregó SMTP ni envío.
