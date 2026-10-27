# Arquitectura final de autorización — Correspondencia GAM Sipe Sipe

Estado: Fases 1–3 implementadas en develop, sin commit, push ni despliegue.
Head Alembic versionable: k1b2c3d4e5f6.
Cadena independiente: g2b3c4d5e6f7 -> i1b2c3d4e5f6 -> j1b2c3d4e5f6 -> k1b2c3d4e5f6.
H1 y la integración de RR.HH. se excluyen del commit. Revalidación: AUTHORIZATION_RRHH_SEPARATION.md.
Las bases habituales y producción no fueron migradas.

## Entidades y responsabilidades

User es la cuenta de acceso. Su estado activo es obligatorio. Employee vincula la cuenta con una
persona institucional y aporta la unidad actual. Unit delimita el ámbito institucional de trabajo.
Position representa el cargo y referencia PositionHierarchy; no concede alcance por su nombre.
PositionHierarchy contiene código, nombre, rank y estado; solamente su rank autoriza la emisión restringida.

Role agrupa permisos funcionales; UserRole asigna roles. UserPermission agrega concesiones directas,
con auditoría de asignación. Permission es el catálogo de capacidades. No existen denies.

```text
                        UserRole               RolePermission
User ---------------------> Role --------------------> Permission
 |                                                        ^
 +---------------- UserPermission -------------------------+
 |
 +--> Employee --> Unit actual
          |
          +--> Position --> PositionHierarchy (rank, active)

Permisos efectivos = RolePermission de roles activos UNION UserPermission
SUPERADMIN activo  = todos los Permission registrados

LECTURA    permiso de alcance --> filtro SQL central --> datos visibles
CREACION   permiso especifico AND contexto activo AND minimo de jerarquia
MUTACION   permiso operativo AND contexto activo AND responsabilidad AND estado
```

SUPERADMIN es la única excepción técnica de rol del resolvedor: recibe todos los permisos.
No crea Employee, Unit, Position ni Hierarchy ficticios. Una cuenta técnica sin Employee puede
administrar el sistema y leer globalmente con read.all; no puede emitir, derivar, concluir,
reabrir ni gestionar adjuntos como funcionario.

OPERADOR es el rol base vacío: sus capacidades se conceden expresamente por usuario o por configuración
de RolePermission. La herramienta de migración no mezcla permisos de todos los MANAGER en OPERADOR.
Los roles custom existentes también se respetan.

## Lectura centralizada

| Permiso | Alcance |
|---|---|
| correspondence.read.own | Asignación directa en su unidad vigente y seguimiento personal de documentos creados o derivados por el usuario |
| correspondence.read.unit | Documentos actualmente a cargo de su unidad institucional; no concede seguimiento de otras unidades por sí solo |
| correspondence.read.all | Lectura institucional global, incluso para una cuenta técnica sin Employee |

Los permisos se acumulan por unión. Sin un permiso de lectura no existe acceso a documentos, aunque
haya relaciones anteriores. El seguimiento personal se conserva fuera de la unidad con read.own.
Un receptor anterior que no creó ni derivó el documento no obtiene seguimiento personal permanente.

visibility.py es la autoridad SQL. Se reutiliza en detalle, movimientos, listados, adjuntos,
PDF, dashboard y reportes. Las bandejas siguen siendo operativas: Mi bandeja filtra la asignación
personal vigente y De mi unidad filtra la unidad. Enviados conserva la relación personal,
intersectada con un alcance autorizado. La lectura global se ofrece en la consulta general/reportes,
sin inventar una bandeja personal o unidad para una cuenta técnica.

## Operaciones: permiso AND responsabilidad AND estado

| Operación | Permiso | Responsabilidad |
|---|---|---|
| Derivar | correspondence.derive | Responsable directo o alcance de unidad autorizado, dentro de la unidad responsable vigente |
| Concluir | correspondence.conclude | can_operate actual; no desplaza a otro responsable directo activo |
| Reabrir | correspondence.reopen | La misma regla de responsabilidad, con documento concluido |
| Agregar/eliminar adjuntos | correspondence.attachments.manage | can_operate y documento activo, sin desplazar al responsable activo |

En todos los casos la cuenta y Employee/Position/Unit deben estar activos.
El alcance de unidad procede de read.unit o read.all sobre la unidad real del actor.
Un permiso funcional nunca sustituye la responsabilidad institucional. Read.all no habilita mutaciones
en otra unidad. Si el funcionario responsable cambió de unidad, debe corregirse la asignación del
trámite desde la unidad responsable vigente.

Un lector de unidad puede derivar un documento asignado a un compañero si tiene derive.
Ese mismo lector no puede concluirlo, reabrirlo ni gestionar sus adjuntos mientras el otro
responsable esté activo. La unidad puede operar trámites sin usuario o con responsable inactivo,
si tiene el permiso operativo correspondiente.

Derivar/concluir/adjuntos requieren estado ACTIVE; reabrir requiere CONCLUDED.
La derivación conserva bloqueo de fila, validación de destino y exactamente un movimiento nuevo por acción.
Las descargas solo necesitan visibilidad y vigencia de las filas correspondientes; no attachments.manage.

## Reportes, dashboard y notificaciones

reports.view habilita el módulo, pero no amplía el alcance. Los datos y exportaciones CSV/XLSX/PDF
intersectan los mismos permisos de lectura. Read.all habilita filtros institucionales globales;
read.unit solamente permite la unidad del Employee. Dashboard utiliza la misma política.

Las notificaciones se destinan al usuario directamente asignado con lectura válida o a lectores
autorizados de la unidad, con contexto activo. No se difunden a toda la institución por read.all.
Se excluye al actor. El índice movimiento/usuario evita duplicados.
Notificaciones anteriores se conservan, pero listado, contador y marcado ocultan las vinculadas a
documentos a los que el usuario ya no tiene acceso. Una notificación nunca concede visibilidad.

## Creación y jerarquía — sin rediseño de Fase 2

| Código | Permiso | Mínimo |
|---|---|---|
| COMUNICADO_INTERNO | correspondence.create.internal_communication | Sin mínimo superior |
| INFORME | correspondence.create.report | Sin mínimo superior |
| MEMORANDUM | correspondence.create.memorandum | JEFE |
| CIRCULAR | correspondence.create.circular | DIRECTOR |

La autoridad es siempre User -> Employee -> Position -> PositionHierarchy del actor autenticado,
aunque el formulario seleccione otra persona como origen. Se compara rank con el mínimo referenciado
por el tipo documental. SUPERADMIN/read.all no evitan la jerarquía.

El catálogo de creación ya viene filtrado por backend. Flutter no replica comparaciones jerárquicas.
Código, perfil, mínimo y permiso del tipo son estructurales protegidos. Los UUID anteriores se conservan.
EDIE/NOTA y demás tipos históricos permanecen consultables según alcance; no se convierten a otros tipos.

## Capacidades Flutter y administración

El backend devuelve can_derive, can_conclude, can_reopen y can_manage_attachments,
que incluyen permiso, contexto, responsabilidad y estado. can_operate conserva el significado de
responsabilidad y no se interpreta por sí solo como permiso de mutación.
Los campos nuevos ausentes se interpretan como false. DTO, repository, mapper y copyWith los preservan.

Los controles de detalle y adjuntos usan estas capacidades. Reportes sigue usando reports.view.
La sesión ya devuelve los permisos efectivos y el contexto institucional, incluida jerarquía.
Las bandejas reciben la capacidad de unidad del backend, nunca del nombre del cargo.

El catálogo se agrupa en Correspondencia - Lectura, Correspondencia - Creación,
Correspondencia - Operación, Reportes, Administración, Configuración y Otros.
El permiso legacy de creación está etiquetado como legado.

La asignación de SUPERADMIN requiere otro SUPERADMIN y no se permite autoasignación de ese rol.
Administrar permisos directos exige users.manage + roles.assign y no permite conceder capacidades
que el actor no tiene. Un administrador delegado no puede consolidar en sí mismo nuevas concesiones
administrativas directas heredadas de roles. La continuidad del último administrador funcional
se verifica bajo los mismos bloqueos administrativos existentes.

## Transición de can_view_unit_correspondence

La columna de Position se conserva para datos/clientes anteriores. K1 copia una vez su valor true
a UserPermission(read.unit) de las cuentas vinculadas existentes. También formaliza read.own y las
cuatro operaciones que antes eran implícitas para usuarios existentes.
Los roles legacy reciben ese mínimo funcional para mantener su provisión temporal.

Después de k1 no existe OR con la columna ni se consulta para autorización.
Cambiar cargo o ese campo no agrega/revoca permisos del usuario.
La unidad a la que se aplica read.unit sigue siendo la del Employee actual; los traslados deben
acompañarse de revisión de permisos.

El interruptor del cargo queda de solo lectura, con una explicación hacia Permisos del usuario.
El nombre JSON can_view_unit_correspondence en contadores/contexto es una capacidad calculada desde
permisos; no es una lectura de la columna antigua.

No ejecutar seed_permissions periódicamente: es una transición de datos de Alembic de una sola aplicación.
La columna solo podrá retirarse cuando se auditen todas las bases/clientes y se confirme que no se
necesita en procedimientos de compatibilidad o rollback. Esta fase no la elimina.

## correspondence.create legacy

Se conserva el Permission y sus concesiones. Está deprecated: no autoriza CREATE por sí solo.
Fase 2 transportó la capacidad previa a los cuatro permisos específicos; Fase 3 mantiene esa estrategia.
Ningún endpoint utiliza el permiso legacy como alternativa para eludir jerarquía.

Retirarlo posteriormente requiere inventariar RolePermission/UserPermission y consumidores externos,
migrar los restantes y aprobar su retirada. Esta fase no borra ni normaliza concesiones reales.

## Migración controlada de roles

ADMIN no se convierte automáticamente a SUPERADMIN.
MANAGER y OPERATOR se convierten a OPERADOR conservando, por usuario, el conjunto efectivo anterior.
ADMIN se omite por defecto. Se puede incluir explícitamente por username para convertirlo a OPERADOR,
preservando sus capacidades previas, sin concederle SUPERADMIN.

Se conservan los roles custom, las concesiones directas existentes y las capacidades de cuentas inactivas
para no alterar una reactivación futura. No se eliminan los roles legacy del catálogo ni sus grants.
Durante la transición permanecen compatibles; para nuevas cuentas se debe usar OPERADOR con concesiones explícitas.

Herramienta: backend/scripts/migrate_authorization_roles.py. Ejecutar desde backend, en un entorno aprobado
con DATABASE_URL seleccionado explícitamente, tras respaldo y revisión de identidades/contexto.

```text
python scripts/migrate_authorization_roles.py --dry-run

# Solo tras revisar el JSON y autorizar ese entorno/lote:
python scripts/migrate_authorization_roles.py --apply --plan-sha256 HUELLA_REVISADA

# ADMIN explícito, siempre a OPERADOR; requiere otro dry-run con los mismos parámetros:
python scripts/migrate_authorization_roles.py --dry-run --include-admin USERNAME
python scripts/migrate_authorization_roles.py --apply --include-admin USERNAME --plan-sha256 HUELLA_REVISADA
```

Dry-run es también el modo predeterminado y abre una transacción PostgreSQL READ ONLY.
Muestra usuario, roles actuales/objetivo, permisos actuales/futuros y diferencias.
No escribe DB. La huella incluye el estado revisado; un plan cambiado se rechaza.

La aplicación usa transacción SERIALIZABLE y los bloqueos administrativos existentes.
Verifica continuidad, agrega solo los grants directos faltantes, cambia las membresías, comprueba
equivalencia después de flush y registra before_state/after_state por usuario en
authorization_migration_audits con batch_id y timestamp.
Si OPERADOR agregaría capacidades inesperadas, se bloquea el lote completo.
Cualquier error provoca rollback. Repetir el plan de cuentas ya convertidas no las vuelve a migrar.

La herramienta no cambia empleados, unidades, cargos, jerarquías, documentos, snapshots o permisos
globales del rol OPERADOR. No se ejecutó sobre la base habitual.

## Rollback conceptual

Si falla la transacción, no se aplica parte del lote.
Después de un commit, usar el batch auditado y el respaldo para diseñar una reversión explícita
de membresías y grants agregados, comprobar que no hubo cambios posteriores legítimos, validar continuidad
y equivalencia y ejecutar en una transacción. No eliminar concesiones posteriores por diferencia ciega.
Las filas de Role legacy se conservaron precisamente para permitir esa revisión.

No usar stamp/downgrade para simular una reversión de la política de permisos.
El downgrade de k1 se rechaza: volver a código antiguo necesita evaluar sus reglas implícitas,
además del esquema. Esta fase no incorpora un rollback automático destructivo.

## PDF y datos históricos

Los cuatro PDF operativos usan snapshots de emisión: actor y origen separados, destinatario,
cargo, unidad, jerarquía, fecha, numeración y contenido. Cambios posteriores de maestros no los alteran.
El logo y la plantilla visual son recursos del código; no son bytes congelados por documento.
Detalle/reportes pueden mostrar etiquetas actuales del catálogo o de maestros, como ya ocurría.

El renderer legacy no se modificó. La autoridad usa su snapshot cuando existe; en documentos antiguos
sin snapshot y en algunos nombres de origen/movimientos, el PDF legacy sigue resolviendo información
desde maestros actuales. Mantiene también su fecha de generación y movimientos disponibles a la consulta.
No se inventaron snapshots retroactivos. Esta limitación queda explícita, sin transformar históricos.

## Catálogo, comprobaciones y adopción

El catálogo definitivo y la auditoría de referencias están en AUTHORIZATION_PERMISSION_CATALOG.md.
Los resultados, archivos y estados Git están en PHASE3_QA_REPORT.md.

Antes de producción: revisar los usuarios reales y sus jerarquías/permisos, respaldar DB y adjuntos,
probar la cadena de migraciones con copia aprobada, revisar dry-run, resolver ADMIN explícitamente,
realizar smoke visual con perfiles reales de QA y autorizar por separado cualquier aplicación/despliegue.
RR.HH./biométrico y sus dos permisos previos quedan fuera de esta fase.

No commit. No push. No deploy. No migración de la base habitual.
