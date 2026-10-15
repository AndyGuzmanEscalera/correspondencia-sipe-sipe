# Arquitectura oficial API/CORS

## Contrato por entorno

| Entorno | Flutter Web | Backend/CORS | Cookie de refresh |
| --- | --- | --- | --- |
| DEV | `http://localhost:8000` por defecto; `API_BASE_URL` configurable | Solo `localhost` y `127.0.0.1`, HTTP(S), cualquier puerto | HttpOnly, SameSite=Lax, Path=/auth, Secure=false en HTTP |
| QA | `/api` | Mismo origen mediante Apache; CORS externo vacío por defecto | Apache reescribe Path a /api/auth; Secure=true si QA usa HTTPS |
| Producción | `/api` | Mismo origen mediante Apache; CORS externo vacío por defecto | HttpOnly, SameSite=Lax, Path público /api/auth, Secure=true; HTTPS obligatorio |

`packages/correspondencia_api/lib/src/core/network/api_config.dart` es la única
fuente de selección de URL para los clientes Dio principal y refresh. En debug
el entorno predeterminado es development; un build web release siempre usa
`/api`, incluso si recibe por error un API_BASE_URL absoluto. En web debug,
`APP_ENV=qa` o `APP_ENV=production` también selecciona `/api`. Los clientes nativos
conservan la URL configurable porque no tienen origen de navegador.

DEV:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5000
# Alternativa DEV explícita para otro puerto local:
flutter run -d chrome --web-hostname localhost --web-port 5001 --dart-define=API_BASE_URL=http://localhost:8001
```

Usar el mismo nombre local en frontend y API para que SameSite=Lax sea compatible
con la cookie: localhost con localhost, o 127.0.0.1 con 127.0.0.1. CORS no elimina
las restricciones de cookies del navegador.

QA:

```powershell
.\scripts\build_web_demo.ps1
# Equivalente: flutter build web --release --dart-define=APP_ENV=qa
```

Producción: `flutter build web --release`. No hace falta definir un host.
**No existe una IP fija en runtime productivo.** El navegador resuelve `/api`
contra su origen actual; cambiar el host externo no requiere recompilar.

## CORS y variables del backend

`APP_ENV` admite development, qa o production. En development se ignoran los
overrides externos CORS y se usa exclusivamente:

```text
^https?://(localhost|127\.0\.0\.1)(:\d+)?$
```

Credentials=true, métodos y headers permitidos mediante `["*"]`. Los origins
nunca son wildcard con credentials. Las respuestas de error seguro 500 conservan
CORS porque este middleware envuelve SafeErrorMiddleware.

En qa/production, CORS_ALLOW_ORIGINS y CORS_ALLOW_ORIGIN_REGEX quedan vacíos por
defecto. Solo sirven para compatibilidad externa deliberada, con origins
restringidos por env; no registrar la IP externa del servidor para la propia app.
Sin configuración externa no se instala CORS: las peticiones same-origin
funcionan y un preflight externo no recibe Access-Control-Allow-Origin.

COOKIE_SECURE vacío selecciona false en development/qa y true en production.
Para QA HTTPS establecer COOKIE_SECURE=true. Production rechaza false; no usar
production en HTTP. COOKIE_SAMESITE=lax evita cross-site innecesario; None sin
Secure se rechaza. COOKIE_PATH=/auth debe mantenerse en el backend. La cookie
no lleva Domain: es host-only, HttpOnly y la elimina logout con los mismos atributos.

Docker Compose solo cambia defaults de estas variables; no se alteran servicios,
puertos, volúmenes, Postgres ni rutas funcionales.

## Apache y rutas

```apache
ProxyRequests Off
ProxyPreserveHost On
ProxyPass        /api/ http://127.0.0.1:8000/
ProxyPassReverse /api/ http://127.0.0.1:8000/
ProxyPassReverseCookiePath /auth /api/auth
```

127.0.0.1 es loopback interno del servidor. El navegador no debe usar IP:8000 en
QA/producción. La regla SPA excluye /api/. Apache elimina el prefijo una vez:
`/api/auth/refresh` llega a `/auth/refresh`; los Endpoints Dart no incluyen /api.
La cookie emitida y la de eliminación se traducen ambas a Path=/api/auth.
No configurar además COOKIE_PATH=/api/auth, pues duplicaría la traducción.
El VirtualHost HTTP versionado sirve QA HTTP; producción debe usar su VirtualHost
TLS con las mismas reglas de proxy. No se instaló ni modificó Apache en Debian.

Referencias: [FastAPI CORS](https://fastapi.tiangolo.com/tutorial/cors/),
[Apache proxy/cookie path](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypassreversecookiepath).

## Auditoría de direcciones

Búsqueda en lib/, packages/correspondencia_api/lib/, backend/app/, deploy/,
scripts/, .env.example, README.md y docs/ de IP privadas, localhost:8000,
127.0.0.1, baseUrl, apiUrl y /api:

| Clasificación | Hallazgos relevantes | Acción |
| --- | --- | --- |
| Runtime DEV | ApiConfig default localhost:8000; scripts run_dev/run_chrome; comentario de CredentialsInterceptor | Mantener solo para desarrollo; override DEV configurable |
| Runtime QA/PROD | ApiConfig /api; ApiClient usa esa única base; Endpoints auth/dashboard/notificaciones/reportes/adjuntos sin prefijo | Siempre relativo al origen actual; sin IP LAN ni host externo |
| Infraestructura interna | Proxy Apache 127.0.0.1:8000; config PostgreSQL localhost; Compose hostname postgres | Correctos; no son direcciones del navegador productivo |
| Documentación | deploy/apache/README, QA_CHECKLIST y este contrato | Ejemplos de desarrollo y descripción del proxy; los resultados QA anteriores son históricos |
| Tests | Loopback y direcciones externas ficticias en contratos y fixtures | Prueban aceptación/rechazo, cookies y resolución de rutas; no son runtime |

No se encontraron IP privadas fijas en runtime. La coincidencia 10.0 en un radio
del tema es un número de UI, no una IP. Imports de api_method.dart no son URLs.
El antiguo default de Flutter no distinguía release: omitir dart-define enviaba
producción a localhost:8000. El regex DEV ya existía, pero se podía reemplazar
con env y admitir orígenes externos; los ejemplos invitaban a mezclar listas
fijas y regex externo. Se corrigen esas causas de configuración; un error de
red por sí solo no prueba CORS ni sustituye revisar la respuesta OPTIONS.

## Verificación

Backend: tests/test_network_configuration.py cubre preflight local/exterior,
compatibilidad externa explícita, wildcard inválido y atributos de cookie.
Se conserva test_internal_error_cors.py. Paquete API: api_config_test.dart usa
los Endpoints reales y ambos clientes para login/refresh/me/logout/dashboard,
notificaciones, reportes, CSV/XLSX/PDF y adjuntos; evita /api/api.
Los tests Chrome con APP_ENV=qa/production pasan incluso con un override absoluto
incorrecto. Consultar QA_CHECKLIST para los resultados ejecutados de este lote.
