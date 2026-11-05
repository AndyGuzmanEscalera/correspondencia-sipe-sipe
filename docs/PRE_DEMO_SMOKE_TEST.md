# Smoke test pre-demo — Correspondencia GAM Sipe Sipe

Fecha objetivo: 6 de noviembre de 2026. Ejecutar únicamente sobre una base QA/local aislada con identidades ficticias. No registrar contraseñas en este archivo.

Estados permitidos: `PENDIENTE`, `OK`, `FALLA`, `BLOQUEADO`.

## Actores de demostración

1. SUPERADMIN técnico.
2. OPERADOR / FUNCIONARIO: lectura propia y creación de Hoja de Ruta, Comunicado e Informe.
3. JEFE: lectura de unidad, Memorándum, derivar y concluir.
4. DIRECTOR: lectura de unidad, Circular, Memorándum, derivar, concluir y reportes.

Las credenciales deben entregarse por un canal seguro y temporal; nunca incluirlas en Git, capturas o documentos compartidos.

## Checklist funcional

| Estado | Caso | Pasos mínimos | Resultado esperado | Observación |
|---|---|---|---|---|
| PENDIENTE | Login | Ingresar con cada actor | Acceso válido; menú y acciones según permisos | |
| PENDIENTE | Sesión | Recargar navegador y consultar `/auth/me` | Sesión restaurada y permisos efectivos vigentes | |
| PENDIENTE | Crear usuario | Crear OPERADOR vinculado a funcionario | Cuenta creada sin exponer hash/contraseña | |
| PENDIENTE | Editar usuario | Cambiar datos y guardar | Datos persistidos y lista actualizada | |
| PENDIENTE | Permisos | Asignar `read.unit`, `reports.view`, `derive` | `/auth/me`, menú y acciones reflejan permisos tras refresco controlado | |
| PENDIENTE | Cambio contraseña | Editar usuario, nueva y confirmación | Hash actualizado; contraseña anterior falla y nueva funciona | |
| PENDIENTE | Jerarquía | Verificar FUNCIONARIO, JEFE y DIRECTOR | Restricciones documentales dependen del actor autenticado | |
| PENDIENTE | Hoja de Ruta | Completar PARA, DE, referencia, contenido, fecha, hora y hojas | Guarda como `ROUTE_SHEET`, genera HR, snapshot y detalle correctos | |
| PENDIENTE | Comunicado | Crear con permiso correspondiente | Documento y PDF correctos | |
| PENDIENTE | Informe | Crear con permiso correspondiente | Documento y PDF correctos | |
| PENDIENTE | Memorándum | Crear como JEFE; intentar como FUNCIONARIO | JEFE autorizado; FUNCIONARIO rechazado | |
| PENDIENTE | Circular | Crear como DIRECTOR; intentar como JEFE | DIRECTOR autorizado; JEFE rechazado | |
| PENDIENTE | Búsqueda | Buscar CITE, HR, asunto, referencia, origen, destino y contenido | Coincidencias dentro del alcance; sin fuga entre unidades | |
| PENDIENTE | Derivación | Derivar a funcionario y a unidad | Responsable y movimiento actualizados una vez | |
| PENDIENTE | Notificación | Revisar asignación, derivación, conclusión y reapertura | Receptor correcto, badge/listado sin duplicados | |
| PENDIENTE | Concluir | Concluir como responsable autorizado | Estado `CONCLUDED`, movimiento y bloqueo de mutaciones | |
| PENDIENTE | Reabrir | Reabrir documento concluido | Estado `ACTIVE`, movimiento y notificación | |
| PENDIENTE | Adjuntos | Subir, descargar y dar de baja | Bytes íntegros; baja lógica conserva histórico | |
| PENDIENTE | Reportes | Filtrar por fechas, funcionario, unidad, tipo y estado | `reports.view` habilita módulo sin ampliar alcance de lectura | |
| PENDIENTE | PDF | Abrir los cinco tipos documentales | Logos, actor, PARA, DE, referencia, contenido y numeración correctos | |
| PENDIENTE | Logout | Cerrar sesión y volver a ruta protegida | Cookie/sesión revocada y redirección a login | |

## Recorrido de 15 minutos

1. Login como OPERADOR y mostrar cargo/permisos.
2. Mostrar Dashboard y crear Hoja de Ruta.
3. Abrir PDF, derivar a JEFE y buscar por HR/asunto.
4. Cambiar a JEFE, revisar notificación y concluir.
5. Crear Memorándum.
6. Cambiar a DIRECTOR y crear Circular.
7. Mostrar reporte por unidad/funcionario y exportación.
8. Como SUPERADMIN, mostrar permisos directos frente a heredados.

## Regla de salida

- Cualquier P0 o P1 en `FALLA` bloquea el despliegue/demo hasta corrección o decisión explícita.
- P2/P3 se documentan para después del 9 de noviembre.
- No desplegar, migrar ni limpiar datos sin aprobación final y respaldo verificado.
