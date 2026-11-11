# Cloudflare Pages — Correspondencia GAM Sipe Sipe

Estado: preparación local; no se modificaron Pages, DNS, Tunnel ni Debian.
Desarrollo: C:\dev\correspondencia_sipe_sipe. El repositorio deploy de Debian
conserva backend, PostgreSQL y el web container de recuperación.

## Arquitectura

Frontend: Flutter Web compilado en PC -> Pages -> https://correspondencia.sipesipe.gob.bo.
API: https://api-correspondencia.sipesipe.gob.bo/api -> túnel
sipe-sipe-correspondencia -> http://127.0.0.1:8080 -> proxy Apache /api/
-> FastAPI backend:8000 -> PostgreSQL interno.
Frontend se sirve íntegramente desde Pages; API y datos permanecen en Debian.
No se publica PostgreSQL ni se necesita exponer backend:8000 al host.

Recomendación inicial: reutilizar el gateway Apache probado de 8080 para la API,
sin cambiar puertos, paths, proxy confiable ni cookies durante esta transición.
El origen del túnel es http://127.0.0.1:8080, sin duplicar /api en el service URL.
El path /api está en la URL que consume Flutter y Apache lo elimina una vez.
Después puede sustituirse el contenedor web por un gateway solo API. Un túnel
directo al backend requeriría preparar /api en FastAPI o reescritura equivalente:
hoy sus rutas internas son /auth, /admin, etc. No apuntarlo directamente sin eso.

## Rutas y SPA

Canónicas: /login y /consulta. / conserva Splash/restauración de sesión.
El panel autenticado continúa en /correspondencia/home.
GoRouter mantiene una sola página por función y redirects de compatibilidad.

web/_redirects se incluye en build/web/_redirects:

```text
/correspondencia/login /login 301
/correspondencia/consulta /consulta 301
/consulta-publica /consulta 301
```

El fallback es el SPA nativo de Pages: no se incluye un 404.html de nivel raíz.
No agregar /* /index.html 200: las reglas de _redirects se aplican incluso cuando
existe un asset y esa regla capturaría JS, imágenes y fuentes.
Fuentes: [Pages SPA](https://developers.cloudflare.com/pages/configuration/serving-pages/),
[redirects](https://developers.cloudflare.com/pages/configuration/redirects/).
El script verifica ausencia de 404.html y las tres reglas exactas.

## API y build

APP_ENV y API_BASE_URL son los dart-defines reales existentes.
ApiConfig.productionBaseUrl es la única constante del endpoint productivo;
clientes principal y refresh usan esa configuración y withCredentials=true.
Producción predeterminada usa la API HTTPS separada. Desarrollo conserva
http://localhost:8000 configurable; QA/recovery puede usar /api explícitamente.

```powershell
flutter pub get --enforce-lockfile
flutter build web --release --base-href=/ --pwa-strategy=none --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api-correspondencia.sipesipe.gob.bo/api
./scripts/deploy_pages.ps1 -DryRun
```

El modo seco ejecuta analyze, tests, el contrato API de producción y build;
comprueba index.html, main.dart.js, _redirects, assets y secretos. No invoca
Wrangler ni requiere login. analyze usa --no-fatal-infos: errores y warnings
siguen fallando; los infos existentes se reportan.
El service worker se deshabilita para no retener builds anteriores.
build/web continúa ignorado por Git en desarrollo.

Los builds de recuperación Debian (prepare_deploy.ps1 y Dockerfile.web)
pasan API_BASE_URL=/api explícitamente. No sincronizar un build de Pages hacia
el web container: sus destinos API tienen propósitos diferentes.

## CORS y cookies

Backend ya admite una lista exacta configurable. Las plantillas quedan con:

```text
APP_ENV=production
CORS_ALLOW_ORIGINS=https://correspondencia.sipesipe.gob.bo
CORS_ALLOW_ORIGIN_REGEX=
CORS_ALLOW_CREDENTIALS=true
COOKIE_NAME=refresh_token
COOKIE_SECURE=true
COOKIE_SAMESITE=lax
COOKIE_PATH=/auth
```

No se cambia ningún .env real ni servicio desde esta preparación.
Aplicar la configuración en Debian/reiniciar backend será una acción posterior.
El validador deploy acepta orígenes HTTPS exactos y rechaza comodines, regex,
credenciales en URLs y credentials=false.

Ambos subdominios finales HTTPS pertenecen al mismo sitio; Lax puede conservarse
aunque sean distintos orígenes. Dio habilita credentials en ambos clientes.
La cookie es HttpOnly, Secure y host-only de la API, sin Domain=.sipesipe.gob.bo.
FastAPI conserva Path=/auth; Apache reescribe Set-Cookie a /api/auth y lo mismo
para logout. El frontend no lee la cookie; access token permanece en memoria.
La API conserva Cache-Control no-store mediante su gateway.
Referencia: [cookies SameSite](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie).

IMPORTANTE pages.dev: es un sitio diferente a sipesipe.gob.bo. No declarar como
comprobado un login/refresh de navegador desde pages.dev con cookies Lax.
Tras crear y confirmar propiedad del proyecto, se puede autorizar su origen
EXACTO para probar UI/consulta pública. No permitir *.pages.dev ni previews
arbitrarias. Para autenticación previa al corte usar un hostname QA del mismo
sitio sipesipe.gob.bo autorizado por separado, o probar después del corte con
rollback preparado. No bajar seguridad a SameSite=None en producción solo para
que pase un preview; además los navegadores pueden bloquear cookies de terceros.

## Proyecto Pages y publicación posterior

Proyecto Direct Upload: sipesipe-correspondencia; production branch: develop.
Node >=22.12.0. Wrangler fijado a 4.160.1.
No hay integración Git/build remoto: Flutter se compila en PC.

Creación MANUAL futura (requiere autorización y autenticación preparada):

```text
npx --yes wrangler@4.160.1 pages project create sipesipe-correspondencia --production-branch=develop
```

URL esperada después de crear/publicar, no comprobada en esta tarea:
https://sipesipe-correspondencia.pages.dev

El script de publicación requiere CLOUDFLARE_API_TOKEN y CLOUDFLARE_ACCOUNT_ID
en el entorno de la sesión, con permisos limitados a Pages del account correcto.
No escribirlos en .env del proyecto, código, dart-defines, logs ni Git.
El proyecto debe existir: no se crea automáticamente ni se abre un login.
El script exige develop y frontend versionado para publicar, usa CI no
interactivo y un cwd temporal sin el .env privado del backend.

```powershell
./scripts/deploy_pages.ps1
```

Equivalente Wrangler (solo después de las verificaciones):

```text
npx --yes wrangler@4.160.1 pages deploy build/web --project-name=sipesipe-correspondencia --branch=develop
```

[Contrato Wrangler](https://developers.cloudflare.com/workers/wrangler/commands/pages/).
No se ejecutó ninguno de estos comandos de creación/publicación.
La autenticación interactiva, si se elige, debe hacerse manualmente fuera del
script; este flujo automatizado usa credenciales preparadas en la sesión.

## Prueba local sin Cloudflare

```powershell
python scripts/test_pages_build.py
```

Sirve únicamente build/web con Wrangler pages dev en loopback/puertos temporales.
Usa cwd aislado sin .env de backend, elimina credenciales Cloudflare del proceso,
no publica proyecto ni ejecuta login y no solicita datos a la API.
Comprueba rutas directas/refresh SPA, tres redirects 301 sin loops y bytes de
assets reales. Termina únicamente el proceso creado por la prueba.

## Transición sin cortar el dominio activo

1. Revisar/aprobar los archivos; no hay commit/push automático.
2. Publicar Pages y validar primero assets, /login, /consulta y redirects en
   sipesipe-correspondencia.pages.dev. NO mover el dominio actual.
3. En una acción posterior autorizada, AGREGAR api-correspondencia.sipesipe.gob.bo
   al túnel existente, manteniendo todavía correspondencia.sipesipe.gob.bo.
   Ambos pueden apuntar transitoriamente al gateway Debian de 8080.
4. Preparar CORS en Debian, HTTPS API y pruebas de health, consulta y auth/cookies.
   La validación pages.dev de UI no demuestra autenticación cross-site.
5. Antes del corte, actualizar/probar el fallback Debian con rutas compatibles y
   API relativa usando prepare_deploy.ps1 desde la revisión aprobada. El bundle
   viejo conservado actualmente no se reemplaza por este trabajo.
6. Solo después de Pages/API validados: Workers & Pages -> sipesipe-correspondencia
   -> Custom domains -> correspondencia.sipesipe.gob.bo.
7. Resolver el registro anterior del Tunnel siguiendo la asociación de dominio de
   Pages. No borrar ni cambiar ese registro antes de los pasos previos.
8. Validar login, refresh, logout, consulta, adjuntos/PDF y guards con HTTPS real.
   Mantener backend/DB/web container durante la estabilización.
9. Solo después retirar la entrada frontend del túnel; la entrada API permanece.
   No detener el túnel completo ni afectar otros servicios.

No crear simplemente un CNAME antes de asociar el dominio al proyecto Pages.
Referencia: [dominios personalizados](https://developers.cloudflare.com/pages/configuration/custom-domains/).

## Rollback

Antes del corte: el dominio activo/Tunnel no se modificó; basta no asociarlo a
Pages. Para un frontend Pages defectuoso, seleccionar una versión anterior de
Pages o volver a publicar el artefacto aprobado, sin tocar DB ni backend.
Después del corte: restaurar, de forma autorizada, la asociación DNS/Tunnel
frontend documentada previamente hacia el web fallback. Mantener el hostname
API para clientes que ya cargaron Pages. No hacer downgrade de base.
Una reversión completa debe probar también /login y /consulta contra el fallback.
No eliminar el web container, sus assets ni datos durante esta preparación.

## Límites de la validación local

No se verifica ownership de Pages, credenciales, DNS, certificado API, túnel
activo ni cookies en un navegador contra producción. Esos pasos necesitan la
fase de publicación/infraestructura separada. Backend y DB no se trasladan a
Pages. El único contenido publicable es build/web y su configuración pública.
