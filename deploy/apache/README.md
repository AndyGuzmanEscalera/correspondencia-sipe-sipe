# Flutter QA/producción con Apache y API same-origin

Contrato oficial: [API_NETWORK_ARCHITECTURE](../../docs/API_NETWORK_ARCHITECTURE.md).
DEV usa localhost:8000 configurable; web release y QA/production usan siempre /api.
No fijar IP LAN, hostname ni IP externa del Debian en Flutter.

## Build local

Desde la raiz del repositorio:

```powershell
.\scripts\build_web_demo.ps1
```

El script ejecuta `flutter pub get` y
`flutter build web --release --dart-define=APP_ENV=qa`, se detiene si falla
un comando y restaura el directorio de trabajo. Genera `build/web`; no copia
archivos al servidor ni configura servicios. Todo build web release usa /api automáticamente. Para desarrollo directo
utilizar flutter run en debug.

## Pruebas de configuracion

Desde `packages/correspondencia_api`:

```powershell
flutter test test/api_config_test.dart
flutter test --platform chrome --web-renderer html --dart-define=APP_ENV=qa test/api_config_test.dart
flutter test --platform chrome --web-renderer html --dart-define=APP_ENV=production test/api_config_test.dart
```

Las pruebas web usan Chrome con renderer HTML del SDK actual para la URL relativa.
Todas verifican
ApiConfig, las bases de los clientes principal y refresh, las rutas auth y
correspondencia y `withCredentials`. No verifican una cookie real ni Apache.

## Instalacion manual en el servidor (no realizada por el script)

Requisitos: Apache 2.4 en Linux con `rewrite`, `proxy`, `proxy_http` y
`authz_core` disponibles; backend existente accesible en `127.0.0.1:8000`.
La configuracion de logs usa la variable APACHE_LOG_DIR habitual en Debian/Ubuntu.

1. Copiar el contenido completo de `build/web/` a `/var/www/correspondencia/`.
2. Instalar `correspondencia.conf` como VirtualHost y seleccionar el sitio/dominio
   correspondiente; comprobar conflictos con otros VirtualHosts del puerto 80.
3. Validar la configuracion con `apachectl configtest` antes de habilitar/recargar
   Apache. No se ejecutan esos pasos desde este repositorio.

El fallback SPA preserva archivos/directorios existentes y excluye `/api/`.
`/api/auth/refresh` se envia a `http://127.0.0.1:8000/auth/refresh`. Se debe usar
`/api/` con barra para peticiones al prefijo; `/api` sin barra no tiene una regla
de proxy propia. La configuracion asume Flutter en `/`, no en un subdirectorio.

## Cookie de refresh

El backend mantiene `COOKIE_PATH=/auth`. Apache transforma el atributo Path
de Set-Cookie a `/api/auth` mediante `ProxyPassReverseCookiePath /auth /api/auth`.
El navegador envia la cookie a login/refresh/logout bajo `/api/auth`; Apache
entrega su valor al backend sin necesidad de cambiar auth. La misma traduccion
se aplica al Set-Cookie que elimina la cookie en logout. HttpOnly, SameSite y
Secure conservan los valores emitidos por el backend. `/api/auth/me` tambien
coincide con el Path, aunque la autenticacion de ese endpoint usa access token.

Referencia: [Apache mod_proxy](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypassreversecookiepath).

## Comprobacion posterior a la instalacion

- `/api/health` debe devolver JSON del backend, no index.html.
- Una ruta SPA debe servir Flutter y los assets existentes deben conservarse.
- Login debe emitir cookie HttpOnly con Path=/api/auth.
- Al recargar, deben completarse refresh y me; logout debe eliminar la cookie.

## Limites y riesgos

Este VirtualHost es QA HTTP (APP_ENV=qa, COOKIE_SECURE=false). Para
producción usar un VirtualHost TLS con estas mismas reglas, APP_ENV=production
y COOKIE_SECURE=true (predeterminado en production; false se rechaza). No cambies COOKIE_PATH a /api/auth en el backend con esta
regla: el prefijo publico lo agrega Apache.

El build incluye el working tree actual; los pendientes funcionales existentes
no quedan validados por estas pruebas. La validación en el servidor permanece pendiente hasta un deploy autorizado.
