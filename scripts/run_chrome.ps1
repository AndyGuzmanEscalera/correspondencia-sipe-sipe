# Levanta el demo en Google Chrome (Web).
Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

Write-Host "Iniciando correspondencia_sipe_sipe en Chrome..."
Write-Host "La primera compilacion puede tardar 30-60 segundos."

flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8000
