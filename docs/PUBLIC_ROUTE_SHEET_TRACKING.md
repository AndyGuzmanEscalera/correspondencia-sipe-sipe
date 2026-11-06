# Consulta pública de Hoja de Ruta

Ruta ciudadana: `/correspondencia/consulta`. El alias anterior
`/consulta-publica` redirige a ella. No requiere sesión ni menú administrativo.

## Contrato y privacidad

`POST /public/correspondence/track` (externamente `/api/public/correspondence/track`
mediante el proxy Apache existente) recibe `route_sheet_number` y
`document_number` en JSON. No reutiliza la búsqueda interna.

La respuesta usa una lista explícita de campos: HR, estado público, referencia,
recepción, unidad actual, última actualización y movimientos públicos.
No devuelve personas, identificadores internos, instrucciones, observaciones,
adjuntos, hashes ni documento del solicitante. Los movimientos anulados y los
tipos sin mapeo público se excluyen. No se almacenan respuestas en caché.

HR inexistente, documento incorrecto/inválido, registro histórico, eliminación
lógica o comportamiento documental incompatible producen el mismo resultado
`found: false`. Los errores de validación públicos no reproducen el input.

## Registro y conservación

En hojas externas, ingresar C.I./documento habilita el seguimiento. Dejarlo vacío
lo deshabilita; el formulario lo explica. La API requiere opt-in mediante
`enable_public_tracking: true` y documento válido. Solo ROUTE_SHEET externo sin
funcionario de origen admite el opt-in. La creación captura HMAC-SHA256 y últimos
cuatro caracteres en columnas separadas. El documento administrativo existente
no se usa para comparar consultas públicas ni se duplica en el snapshot público.
No hay endpoint de edición de correspondencia en este lote.

La normalización quita espacios, puntos y guiones; elimina el departamento
emisor reconocido al final (p. ej. `12.345.678 CBBA` → `12345678`). Conserva
letras y complementos del identificador. Acepta 4–24 caracteres normalizados,
con entrada máxima de 30. HR se compara exactamente, tras trim y mayúsculas.

## Configuración y migración

Migración aditiva `n1b2c3d4e5f6`, hija de `m1b2c3d4e5f6`. Los registros anteriores
quedan con hash nulo y no se habilitan automáticamente. No inferir documentos.

Configurar `PUBLIC_TRACKING_HMAC_SECRET` con al menos 32 bytes aleatorios en el
gestor de secretos o `.env` excluido de Git. Es independiente del secreto JWT.
Sin él, la consulta y el opt-in fallan cerrados (503); el resto del registro sigue
disponible sin opt-in. Conservarlo estable: rotarlo invalida los verificadores;
no hay recálculo automático de históricos. No registrar su valor ni documentos.

La nueva versión del modelo requiere aplicar n1 en el entorno correspondiente
antes de usarla. Las validaciones del desarrollo se realizan en DB temporal;
no se migra automáticamente la base habitual ni QA.

## Protección y operación

Límite de 10 intentos por IP en 60 segundos, incluyendo entradas inválidas,
con almacenamiento acotado y respuesta 429 / Retry-After. Solo se usa la IP
resuelta por el servidor ASGI: no se interpreta X-Forwarded-For arbitrariamente.
En producción configurar explícitamente proxies de confianza y comprobar que
se resuelve la IP real del ciudadano. El limitador es local a cada proceso;
para varios workers o réplicas agregar un almacén compartido o límite central
en el proxy. CAPTCHA y código de seguimiento independiente quedan para otra fase.

La referencia es un campo publicado deliberadamente: registrar allí solo texto
apto para el solicitante. Contenido e instrucciones internas permanecen privados.
