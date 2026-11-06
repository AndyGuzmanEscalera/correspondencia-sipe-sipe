# Notificaciones entre equipos

La fuente de verdad es PostgreSQL (`notifications`), no el almacenamiento del
navegador. La transacción de creación/derivación/conclusión/reapertura persiste
la entrega con unicidad por movimiento y usuario. La asignación inicial usa
el primer movimiento DERIVED y se presenta como ASSIGNED.

`NotificationsMonitor`, montado una sola vez alrededor del router, consulta
inmediatamente con sesión y cada `pollInterval = Duration(seconds: 10)`.
`GET /notifications` devuelve la página, estados leídos y contador no leído.
El badge usa ese contador; las llegadas se detectan por ID y muestran un aviso
con acción Ver. Abrir el panel no marca automáticamente todo como leído.
`POST /notifications/{id}/read` y `/notifications/read-all` persisten la lectura.

El panel abierto se actualiza sin cerrarlo. Si muestra otra página, el poll
consulta también esa página conservando la navegación. Las consultas idénticas
en curso se comparten y los cambios de página se serializan. El temporizador
no inicia otro poll mientras el anterior o una actualización manual está activo.

Logout limpia sesión, badge y lista antes de esperar HTTP. Se cancela el timer;
las respuestas antiguas se descartan por generación/sesión, y las solicitudes
en cola de una sesión anterior no se envían. No es posible retirar una petición
ya recibida por el servidor. Otro login crea una nueva línea base silenciosa.

Al navegar dentro de la aplicación sigue activo. Al pasar a segundo plano se
pausa; al volver consulta inmediatamente. El navegador puede limitar timers:
10 segundos es el intervalo nominal en una ventana activa, más latencia de red,
no una garantía de entrega con una pestaña suspendida o sin conexión.

Destinatarios: responsable directo con permiso de lectura, más usuarios activos
de la unidad destino con alcance de unidad. Se excluye al actor. Para concluir
y reabrir se considera la unidad/responsabilidad de origen del movimiento.
No se envía indiscriminadamente a toda la institución. Lista, contador, lectura
y detalle vuelven a aplicar autorización; una notificación nunca otorga acceso.

Los fallos de fondo no muestran diálogos ni detienen el timer; se vuelve a
intentar en el siguiente intervalo. Autenticación y refresh usan el cliente
existente. Los diagnósticos normales del cliente siguen siendo solo de debug.

Demo: dos sesiones independientes, A deriva a B; dejar B activo sin tocarlo.
En aproximadamente 10 segundos más red aumenta el badge, aparece el aviso y
se actualiza el panel abierto. Leerlo disminuye el badge y persiste en DB.
