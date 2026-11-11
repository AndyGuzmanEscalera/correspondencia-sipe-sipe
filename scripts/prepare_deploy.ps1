[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedSourceSha,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$')][string]$Release,
    [switch]$SkipTests,
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$source = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$target = [IO.Path]::GetFullPath('C:\dev\correspondencia-sipe-sipe-deploy').TrimEnd('\')
$utf8 = [Text.UTF8Encoding]::new($false)

function Git-Source {
    $out = & git -c "safe.directory=$($source.Replace('\','/'))" -C $source @args
    if ($LASTEXITCODE -ne 0) { throw 'Falló la comprobación Git del desarrollo.' }
    return $out
}
function Write-Utf8([string]$path, [string]$content) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    [IO.File]::WriteAllText($path, $content, $utf8)
}
function Assert-NoLinks([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    if ((Get-Item -Force -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "No se permiten enlaces en el runtime: $path"
    }
    $links = @(Get-ChildItem -Force -Recurse -LiteralPath $path |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
    if ($links.Count -gt 0) { throw "Hay enlaces dentro de $path; no se eliminará ni copiará." }
}
function Clear-Runtime([string]$relative) {
    if ($relative -notin @('backend/app','backend/alembic','web/build')) { throw 'Destino de limpieza no permitido.' }
    $absolute = [IO.Path]::GetFullPath((Join-Path $target $relative))
    if (-not $absolute.StartsWith($target + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'La limpieza sale del repositorio deploy.'
    }
    Assert-NoLinks $absolute
    # Only these generated runtime folders, never .git, .env, backend/storage or backups.
    if (Test-Path -LiteralPath $absolute) { Remove-Item -LiteralPath $absolute -Recurse -Force }
    [IO.Directory]::CreateDirectory($absolute) | Out-Null
}
function Flutter-Checked {
    & flutter @args
    if ($LASTEXITCODE -ne 0) { throw "Falló Flutter: $($args -join ' ')" }
}
if ($source -ne 'C:\dev\correspondencia_sipe_sipe') { throw 'Este preparador solo opera en el desarrollo autorizado.' }
foreach ($root in @($source,$target)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw "No existe el repositorio: $root" }
    if ((Get-Item -Force -LiteralPath $root).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'No usar repositorios enlazados.' }
}
if ((Git-Source branch --show-current) -ne 'develop') { throw 'Se requiere develop.' }
$sha = Git-Source rev-parse HEAD
if ($sha -ne $ExpectedSourceSha) { throw "SHA inesperado: $sha" }
if (-not $Release) { $Release = 'qa-' + $sha.Substring(0,12) }
# A release must copy committed functional source. Packaging scripts may still be under review.
$runtimePaths = @('backend/app','backend/alembic','backend/alembic.ini','backend/requirements.txt',
    'backend/requirements-biometric.txt','lib','packages','assets','web','pubspec.yaml','pubspec.lock')
$dirty = @(Git-Source status --porcelain --untracked-files=all -- @runtimePaths)
if ($dirty.Count -gt 0) { throw 'Hay cambios funcionales sin commit en los orígenes runtime. Revisarlos antes de preparar.' }
foreach ($relative in @('backend/app','backend/alembic','lib','packages','assets','web')) {
    Assert-NoLinks (Join-Path $source $relative)
}
foreach ($relative in @('backend','web','backend/app','backend/alembic','web/build')) {
    Assert-NoLinks (Join-Path $target $relative)
}
$runtimeFiles = @(Git-Source ls-files -- backend/app backend/alembic backend/alembic.ini backend/requirements.txt backend/requirements-biometric.txt)
if ($runtimeFiles.Count -lt 20) { throw 'Inventario backend incompleto.' }
foreach ($relative in $runtimeFiles) {
    if ($relative -match '(^|/)(\.env[^/]*|__pycache__|tests[^/]*|website)(/|$)|\.(pyc|pyo|dump|pem|key)$') {
        throw "Archivo no permitido en runtime: $relative"
    }
}
if ($ValidateOnly) {
    Write-Output "Validación sin cambios: develop $sha; $($runtimeFiles.Count) archivos backend; destino $target"
    return
}
Push-Location $source
try {
    if (-not $SkipTests) {
        Flutter-Checked test --reporter expanded
        foreach ($package in @('correspondencia_api','correspondencia_repository','failures')) {
            Push-Location (Join-Path 'packages' $package)
            try { Flutter-Checked test --reporter expanded } finally { Pop-Location }
        }
    } else { Write-Warning 'Pruebas omitidas explícitamente con -SkipTests.' }
    Flutter-Checked pub get --enforce-lockfile
    Flutter-Checked build web --release --no-pub --dart-define=APP_ENV=production --dart-define=API_BASE_URL=/api --base-href=/ --pwa-strategy=none
} finally { Pop-Location }
if ((Git-Source rev-parse HEAD) -ne $sha) { throw 'HEAD cambió durante el build; no se copiará el runtime.' }
$dirty = @(Git-Source status --porcelain --untracked-files=all -- @runtimePaths)
if ($dirty.Count -gt 0) { throw 'Los orígenes runtime cambiaron durante el build.' }
$build = Join-Path $source 'build/web'
Assert-NoLinks $build
$html = [IO.File]::ReadAllText((Join-Path $build 'index.html'))
$js = [IO.File]::ReadAllText((Join-Path $build 'main.dart.js'))
if (-not $html.Contains('<base href="/">') -or -not $js.Contains('"/api"')) { throw 'Base href o API incorrecta.' }
if ($js.Contains('http://localhost:8000') -or $js.Contains('/correspondencia/correspondencia/')) { throw 'El build contiene rutas no productivas.' }
# Build and source checks complete before touching the existing deploy runtime.
foreach ($relative in @('backend/app','backend/alembic','web/build')) { Clear-Runtime $relative }
foreach ($relative in $runtimeFiles) {
    $destination = Join-Path $target $relative
    [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
    Copy-Item -LiteralPath (Join-Path $source $relative) -Destination $destination
}
Get-ChildItem -Force -LiteralPath $build | Where-Object Name -ne '.last_build_id' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $target 'web/build') -Recurse
}
foreach ($item in @(
    @('deploy/Dockerfile.backend.runtime','backend/Dockerfile'),
    @('deploy/Dockerfile.web.runtime','web/Dockerfile')
)) {
    $template = [IO.File]::ReadAllText((Join-Path $source $item[0]))
    Write-Utf8 (Join-Path $target $item[1]) ($template.Replace('__SOURCE_SHA__',$sha).Replace('__RELEASE__',$Release))
}
[IO.Directory]::CreateDirectory((Join-Path $target 'web/apache')) | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'deploy/apache/correspondencia.image.conf') -Destination (Join-Path $target 'web/apache/correspondencia.conf')
$manifest = [ordered]@{
    release=$Release; source_sha=$sha; alembic_head='n1b2c3d4e5f6'
    build_date=[DateTimeOffset]::UtcNow.ToString('o'); status='prepared'
    notes='Flutter compilado en PC; backend runtime compartido; sin publicación ni deploy.'
}
Write-Utf8 (Join-Path $target 'release.json') (($manifest | ConvertTo-Json) + "`n")
# Verify delivery, not just the local Docker context: ignored source would vanish on server pull.
$deliveryPaths = @($runtimeFiles) + @(Get-ChildItem -LiteralPath (Join-Path $target 'web/build') -File -Recurse |
    ForEach-Object { $_.FullName.Substring($target.Length + 1).Replace('\','/') })
$ignored = @($deliveryPaths | & git -c "safe.directory=$($target.Replace('\','/'))" -C $target check-ignore --stdin)
if ($LASTEXITCODE -gt 1) { throw 'No se pudo verificar la inclusión Git del runtime.' }
if ($ignored.Count -gt 0) { throw ("Git está excluyendo runtime necesario: " + ($ignored -join ', ')) }
Write-Output "Runtime preparado desde $sha. Sin commit ni push. Falta smoke local del deploy."
& git -c "safe.directory=$($target.Replace('\','/'))" -C $target diff --stat
& git -c "safe.directory=$($target.Replace('\','/'))" -C $target status --short
