# Preparación y despliegue simple de Correspondencia

El flujo vigente es desarrollo -> build Flutter en PC -> copia de runtime al repo
deploy -> revisión/commit/push autorizados -> servidor pull/build/up -> Cloudflare.

No se publican ni transportan imágenes. El servidor construye backend y Apache
desde el repo deploy; no instala Flutter ni ejecuta pruebas.

Desde PowerShell en desarrollo:

```powershell
./scripts/prepare_deploy.ps1 -ExpectedSourceSha (git rev-parse HEAD)
```

El preparador exige develop y el SHA exacto, rechaza modificaciones funcionales
sin commit, ejecuta Flutter y paquetes, compila release con APP_ENV=production,
base / y API /api. -SkipTests permite omitir pruebas explícitamente;
-ValidateOnly verifica precondiciones sin modificar archivos ni compilar.
Después copia exclusivamente archivos backend versionados (app/Alembic/ini/
requirements), el build Flutter y las recetas runtime. No copia .env, storage,
dumps, tests, Website ni bytecode. Solo limpia las carpetas generadas backend/app,
backend/alembic y web/build del repo deploy; rechaza enlaces y destinos ajenos.
No hace staging, commit ni push.

Templates: deploy/Dockerfile.backend.runtime y deploy/Dockerfile.web.runtime.
El segundo copia el frontend precompilado: no tiene etapa Flutter. Ambos usan
UID/GID 10001 y permiten raíz read-only, /tmp temporal y storage persistente.
El backend conserva imports y migraciones compartidas con RRHH; no se altera su
funcionalidad ni se inicia worker biométrico. Head actual n1b2c3d4e5f6.

Los Dockerfiles multistage anteriores y validate_production_images.py siguen
disponibles para pruebas de desarrollo; no forman parte del flujo del servidor.
Las instrucciones operativas vigentes están en README y docs del repo deploy.
Los datos y secretos permanecen en servidor, fuera de los archivos versionados.

Después de preparar, validar docker compose config/build y el smoke aislado
desde el repo deploy. Revisar allí el diff completo antes de autorizar commit.
No operar contra volúmenes habituales durante las pruebas. No ejecutar
migraciones ni deploy en servidor como consecuencia automática del preparador.
