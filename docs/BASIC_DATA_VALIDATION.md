# Validación de datos básicos en el entorno local

13/10/2026. Backend activo: contenedor sipe_correspondencia_backend, puerto 8000.

## Causa y corrección

La app ejecutaba el WIP de Employee con work_shift_id, pero la base permanecía en e1f2a3b4c5d6. El GET /admin/employees y las respuestas que resolvían funcionarios fallaban con UndefinedColumn/500. La corrección anterior del guard de eliminación no sincronizaba el resto del modelo.

Se creó un respaldo pg_dump completo y se aplicaron las dos migraciones pendientes del código local activo (f2a3b4c5d6e7 y a3b4c5d6e7f8), sin reset ni borrado de registros. No se modificó ni committeó el código WIP de Turnos/RR.HH./Website. La revisión local actual es a3b4c5d6e7f8. Esto es una reparación del entorno de desarrollo, no un deploy ni una nueva entrega del WIP.

El núcleo Correspondencia committeado sigue teniendo head f2a3b4c5d6e7; no confundir su artefacto QA con esta copia local que ejecuta WIP.

## Comprobaciones contra la base real

| Recurso | Listados HTTP reales | Crear | Leer/buscar | Editar | Baja lógica | Restaurar |
| --- | --- | --- | --- | --- | --- | --- |
| Unidades | 200 | 201 | 200 | 200 | 200 | 200 |
| Cargos | 200 | 201 | 200 | 200 | 200 | 200 |
| Funcionarios | 200 | 201 | 200 | 200 | 200 | 200 |
| Usuarios | 200 | 201 | 200 | 200 | 200 | 200 |
| Tipos documentales | 200 | 201 | 200 | 200 | 200 | 200 |

- Se hicieron 21 solicitudes por red al servidor activo: Activos/Eliminados/Todos de los cinco recursos, catálogos y /auth/me. CORS devolvió el Origin esperado, incluyendo el listado de Funcionarios que antes fallaba.
- Se hicieron 75 comprobaciones HTTP de CRUD con TestClient, código/configuración activos y la misma base real, en una transacción externa con savepoints y rollback. No se ejecutaron mutaciones de prueba contra los registros del usuario.
- Búsqueda, paginación, ocultar eliminados, conservación por ID y restauración: correctos.
- Baja con dependencias activas: 409, sin cambiar estado. ID inexistente: 404. Payload inválido: 422.
- Las huellas completas de las cinco tablas antes/después del CRUD coinciden: las pruebas no dejaron registros ni cambios persistentes.
- Recarga de Flutter tras baja/restauración: corrección 473db9a, cubierta por las 25 regresiones ya ejecutadas. Suites anteriores: 194 Administración y 426 Flutter núcleo, sin fallos.
- No se dispuso de un navegador conectado para inspección visual manual. Los resultados de esta verificación son de respuestas HTTP y CRUD transaccional, no una afirmación de pruebas visuales manuales.

Respaldo y log están en el directorio temporal local codex-crud-live-20261013; no se versionan datos, secretos ni tokens. Mantener el respaldo hasta la aceptación del usuario.

## Uso

El backend ya está actualizado. Volver a abrir el listado o recargar la pestaña para descartar el estado de error anterior. Eliminar sigue siendo lógico y actualiza el listado sin esperar el cierre del mensaje de éxito. No ejecutar scripts de reset/clean.
