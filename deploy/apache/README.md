# Demo Flutter con Apache y API en /api

Desarrollo conserva el default `http://localhost:8000`. La demo sirve Flutter en
la raiz del sitio y usa `API_BASE_URL=/api`, relativo al mismo origen. No se cambia
ApiConfig, Docker Compose, PostgreSQL ni el flujo de autenticacion.

## Build local

Desde la raiz del repositorio:

```powershell
.\scripts\build_web_demo.ps1
```

El script ejecuta `flutter pub get` y
`flutter build web --release --dart-define=API_BASE_URL=/api`, se detiene si falla
un comando y restaura el directorio de trabajo. Genera `build/web`; no copia
archivos al servidor ni configura servicios. Ese build usa /api: para volver a
generar uno local, compilar sin el define.

## Pruebas de configuracion

Desde `packages/correspondencia_api`:

```powershell
flutter test test/api_config_test.dart
flutter test --platform chrome --web-renderer html --dart-define=API_BASE_URL=/api test/api_config_test.dart
```

La segunda prueba usa Chrome con renderer HTML del SDK actual para la URL relativa.
Ambas verifican
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

Este VirtualHost es una demo HTTP. Una cookie Secure requiere HTTPS; para
publicacion con datos reales se necesita un VirtualHost TLS y revisar sus
valores de cookie. No cambies COOKIE_PATH a /api/auth en el backend con esta
regla: el prefijo publico lo agrega Apache.

El build incluye el working tree actual; los pendientes funcionales existentes
no quedan validados por estas pruebas. La validacion real de Apache y de cookies
en navegador requiere instalar y probar en el servidor.
