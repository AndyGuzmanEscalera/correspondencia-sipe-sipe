# Sirve el build web ya compilado en http://localhost:8080
Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

if (-not (Test-Path "build\web\index.html")) {
    Write-Host "Compilando web..."
    flutter build web
}

Write-Host "Abriendo servidor en http://localhost:8080"
Set-Location build\web
python -m http.server 8080
