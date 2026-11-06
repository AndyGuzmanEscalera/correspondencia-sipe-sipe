# Consulta pública de Hoja de Ruta

La consulta ciudadana en `/correspondencia/consulta` requiere únicamente el número
oficial de Hoja de Ruta (ejemplo `HR-2026-000123`). No solicita C.I. ni documento.
El formulario de registro y sus datos del solicitante permanecen sin cambios.

`POST /public/correspondence/track` (externamente `/api/public/correspondence/track`)
recibe `{"route_sheet_number":"HR-2026-000123"}`. Se normalizan espacios externos y
mayúsculas. El campo anterior `document_number` se acepta para compatibilidad,
pero no se utiliza para la búsqueda.

Se publican solo hojas externas activas con snapshot ROUTE_SHEET, incluidas las
que no tienen hash del documento. No se habilitan documentos internos ni otros
comportamientos. Los inexistentes, eliminados o no elegibles responden found=false.

La respuesta contiene HR, estado público, referencia, fechas, unidad actual y
recorrido resumido. No expone personas, identificadores internos, C.I., hashes,
instrucciones, comentarios privados, adjuntos ni URLs de archivos. Los movimientos
anulados y tipos sin mapeo público se excluyen. Cache-Control: no-store.

Se mantiene el límite de 10 intentos por IP cada 60 segundos. Es local a cada
proceso; varias réplicas requieren limitación central. Configurar proxies de
confianza para resolver la IP real. CAPTCHA queda fuera del alcance.

No se requiere otra migración ni el secreto HMAC para consultar. Se conservan las
columnas y configuración existentes para no alterar el registro administrativo.
La referencia publicada debe contener información apta para consulta ciudadana.
