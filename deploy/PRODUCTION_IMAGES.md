# Imágenes productivas de Correspondencia

Estas recetas se construyen desde el repositorio de desarrollo. El repositorio
`correspondencia-sipe-sipe-deploy` consume las imágenes; no compila fuentes.
No usar el Compose de desarrollo para validar este contrato productivo.

## Archivos y contextos

| Imagen | Dockerfile | Contexto | Runtime |
|---|---|---|---|
| Backend | backend/Dockerfile.prod | backend/ | Python 3.12, UID/GID 10001, /app, puerto 8000 |
| Web | deploy/Dockerfile.web | raíz del repo | Apache, UID/GID 10001, puerto 8080 |

Los Dockerfile-specific ignores usan listas permitidas. No envían Website, Git,
.env, dumps, storage, venv, node_modules, caches, pruebas ni builds anteriores.
El contexto web admite solo pubspec/lock, lib, assets, web y lib/pubspec de los
paquetes locales, además de su configuración Apache. El contexto backend admite
app, Alembic/ini y los dos requirements runtime. Ambos Dockerfiles de desarrollo
y sus comportamientos se conservan.

La imagen backend incluye todos los imports actuales de main.py, incluso RRHH,
sin cambios funcionales, y el grafo Alembic completo de 24 revisiones.
La única head es n1b2c3d4e5f6. No omitir h1 ni el merge m1.

## Recursos documentales

Los renderers están en app/modules/correspondence/pdf. Hoja de Ruta y
Encadenamiento usan el formulario institucional; Comunicado, Informe, Memorándum
y Circular usan el renderer operativo; las exportaciones usan report_pdf.
Todos están incluidos con app/assets/branding/sipe_sipe_crest.png.
Utilizan fuentes Helvetica incorporadas en ReportLab; no necesitan fuentes del
host. El recurso oficial se resuelve respecto al módulo instalado, no al cwd.
Una personalización opcional de INSTITUTIONAL_LOGO_PATH requiere un recurso
montado explícitamente; no forma parte del contrato predeterminado.

## Builds locales (PowerShell desde la raíz)

```powershell
$revision = git rev-parse HEAD
docker build --platform linux/amd64 -f backend/Dockerfile.prod --build-arg SOURCE_REVISION=$revision --build-arg RELEASE_VERSION=local-test --build-arg SOURCE_DIRTY=true -t correspondencia-backend:test backend
docker build --platform linux/amd64 -f deploy/Dockerfile.web --build-arg SOURCE_REVISION=$revision --build-arg RELEASE_VERSION=local-test --build-arg SOURCE_DIRTY=true -t correspondencia-web:test .
python scripts/validate_production_images.py --backend-tests
```

Se requiere Docker Desktop Linux activo. Si docker no está en PATH, definir DOCKER
con la ruta completa de docker.exe para el validador Python.

El SDK Flutter está fijado a 3.22.3 y al commit upstream completo
b0850beeb25f6d5b10426284f506557f66181b36, verificado después del clone.
pub get exige pubspec.lock. El build es release, APP_ENV=production, base href=/,
API relativa /api (por ApiConfig) y service worker deshabilitado para evitar una
caché de aplicación que contradiga no-store. No se guarda build/web en Git.

Las tres imágenes base están fijadas por digest en los Dockerfiles. Se pueden
actualizar mediante argumentos PYTHON_IMAGE, FLUTTER_BUILDER_IMAGE y HTTPD_IMAGE.
Los repositorios apt y dependencias Python transitivas siguen la resolución de
los requirements existentes: no se promete reproducibilidad binaria completa.
Actualizar/lockear transitivas y analizar vulnerabilidades es una tarea distinta.

## Contrato de runtime y deploy

Backend: no ENTRYPOINT especial; CMD Uvicorn sin reload ni confianza implícita
en proxies. Compose lo reemplaza por --proxy-headers y
--forwarded-allow-ips 172.30.237.10, que es la IP fija de Apache.
No hay Alembic, seeds ni creación de usuarios al arrancar.
Las migraciones son una operación explícita del operador después del backup.

Storage usa /app/storage, preparado con propietario 10001:10001. Un volumen
externo existente debe tener permisos compatibles antes de arrancar.
Los datos PostgreSQL, storage y .env real pertenecen exclusivamente al servidor.
Filesystem raíz read-only, tmpfs /tmp y almacenamiento persistente son compatibles.
Los healthchecks pertenecen a Compose. /health/database exige verificar el JSON
status=ok/database=connected: su código HTTP por sí solo no demuestra conexión.

Web: Apache incluye conf/extra/correspondencia.conf, sin Listen 80 ni duplicación
de Listen 8080. Carga proxy, proxy_http, rewrite, headers y remoteip.
CMD httpd-foreground; dispone de curl, sh e id. No contiene SDK Flutter.
Los logs van a stdout/stderr y PID/runtime a /tmp.

deploy/apache/correspondencia.image.conf es una copia byte a byte del contrato
apache/correspondencia.conf del repo deploy. Su montaje productivo puede
reemplazarla en la misma ruta. Mantener ambas copias sincronizadas de forma
deliberada al revisar futuras versiones.
Proxy /api/ -> backend:8000/, cookie /auth -> /api/auth, fallback SPA,
Cache-Control no-store, max-age=0 y cabeceras de seguridad.
El servicio asume HTTPS externo: no cambiar COOKIE_SECURE para probar HTTP.
La IP confiable de Cloudflare/host gateway es 172.30.237.1 según deploy; comprobar
el salto real y que el subnet no se solape en el servidor durante otra fase.

## Validación descartable

`scripts/validate_production_images.py` nunca lee .env local. Genera credenciales
sintéticas y nombres únicos. Crea una red edge temporal, una red data interna,
PostgreSQL 16 sin puertos publicados y un volumen storage temporal. Solo web
expone un puerto asignado al azar en 127.0.0.1. Reproduce el proxy con IPs fijas
dentro de su propia red; nunca usa los servicios o volúmenes habituales.

Comprueba migración desde cero, Alembic heads/current, import/OpenAPI, startup,
health/database, UID/GID, raíz read-only, storage writable y siete PDFs
sintéticos sin mounts de fuentes. Comprueba Apache/config/modules, SPA/rutas,
assets, caché, /api, consulta pública sin información real y cookie de logout.
También verifica el recorrido desde el host por el puerto loopback temporal.
Es un smoke HTTP, no sustituye una prueba visual de navegador ni un login real.

Con --backend-tests crea además un contenedor de pruebas descartable separado:
copia tests/ y el único script necesario para el dry-run de autorización,
instala requirements-dev y ejecuta pytest tests/. RRHH tests_rrhh no se ejecuta.
No se agregan tests ni herramientas de desarrollo a la imagen final. El runner
accede temporalmente al registro de paquetes; después se desconecta esa red.
Toda conexión de BD apunta exclusivamente al PostgreSQL generado por esta prueba.
El finally borra solo contenedores/redes/volúmenes creados por ese proceso.

Opcional: --backend-only --backend-tests permite validar backend antes de web.
Ejecutar Flutter test, las tres suites de paquetes y flutter analyze en el repo
de desarrollo, nunca contra una base habitual. Los tests Flutter no usan DB.

## Identidad de release

SOURCE_REVISION recibe un SHA Git completo; RELEASE_VERSION recibe la versión
del release. Los labels OCI source/revision/version están en ambas imágenes.
SOURCE_DIRTY=true identifica únicamente builds locales con cambios pendientes.
Después de un commit autorizado, reconstruir desde ese SHA limpio con
SOURCE_DIRTY=false y una versión concreta. No etiquetar un WIP como release.
Esta preparación no autoriza git add, commit, push, docker push ni despliegues.

Nombres de destino futuros:
- ghcr.io/andyguzmanescalera/correspondencia-sipe-sipe-backend
- ghcr.io/andyguzmanescalera/correspondencia-sipe-sipe-web

No usar latest para releases. La publicación futura deberá registrar los digests
de ambas imágenes en el repo deploy y ejecutar sus verificaciones/backup/rollback
controlado. La validación local no verifica servidor, DNS, TLS ni Cloudflare.
