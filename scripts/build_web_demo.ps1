# Compila la demo para Apache con API en /api. No instala ni despliega.
# Uso desde cualquier directorio: powershell -File scripts/build_web_demo.ps1
# Instrucciones: deploy/apache/README.md
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $repositoryRoot
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get fallo (codigo $LASTEXITCODE)."
    }

    flutter build web --release --dart-define=API_BASE_URL=/api
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build web fallo (codigo $LASTEXITCODE)."
    }

    Write-Host 'Demo compilada en build/web con API_BASE_URL=/api.'
    Write-Host 'Publicacion manual: ver deploy/apache/README.md.'
} finally {
    Pop-Location
}
