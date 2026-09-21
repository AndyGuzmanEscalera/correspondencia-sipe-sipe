# Desarrollo local: backend (Docker) + Flutter Web en puerto 5000.
Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

Write-Host "1) Levantando backend + postgres (Docker)..."
docker compose up -d postgres backend

Write-Host "2) Esperando API en http://localhost:8000/health ..."
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
  try {
    $resp = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 2
    if ($resp.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 2
}

if (-not $ready) {
  Write-Warning "Backend aun no responde. Revisa: docker compose logs backend"
} else {
  Write-Host "Backend OK."
}

Write-Host "3) Flutter Web en http://localhost:5000 ..."
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8000
