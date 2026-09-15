# Inicializa la base de datos PostgreSQL ejecutando los scripts SQL en orden.
# Requiere psql instalado y accesible en PATH.

param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Database = "correspondencia_sipe",
    [string]$User = "sipe_app"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$schemaPath = Join-Path $root "database\schema"
$seedsPath = Join-Path $root "database\seeds"

$scripts = @(
    "001_extensions.sql",
    "002_catalogs.sql",
    "003_auth.sql",
    "004_employees.sql",
    "005_correspondence.sql",
    "006_audit.sql",
    "007_indexes.sql"
)

Write-Host "Inicializando base de datos '$Database' en ${HostName}:${Port}..."

foreach ($script in $scripts) {
    $file = Join-Path $schemaPath $script
    Write-Host "  -> $script"
    psql -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -f $file
}

$seedFile = Join-Path $seedsPath "001_initial_catalogs.sql"
Write-Host "  -> 001_initial_catalogs.sql"
psql -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -f $seedFile

Write-Host "Base de datos inicializada correctamente."
