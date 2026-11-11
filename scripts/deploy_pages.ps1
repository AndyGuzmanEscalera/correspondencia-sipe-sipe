[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ApiBaseUrl
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$project = 'sipesipe-correspondencia'
$wranglerVersion = '4.160.1'
function Checked {
    $program = $args[0]
    $toolArguments = @($args | Select-Object -Skip 1)
    & $program @toolArguments
    if ($LASTEXITCODE -ne 0) { throw "Falló: $program" }
}
Push-Location $root
try {
    $branch = & git -c "safe.directory=$($root.Replace('\','/'))" branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'develop') { throw 'Pages requiere develop.' }
    $sha = & git -c "safe.directory=$($root.Replace('\','/'))" rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer el SHA.' }
    if (-not $ApiBaseUrl) {
        # One authoritative production endpoint, shared with both Dio clients.
        $config = Get-Content -LiteralPath (Join-Path $root 'packages/correspondencia_api/lib/src/core/network/api_config.dart') -Raw
        $match = [regex]::Match($config, "productionBaseUrl\s*=\s*'([^']+)'")
        if (-not $match.Success) { throw 'No se encontró ApiConfig.productionBaseUrl.' }
        $ApiBaseUrl = $match.Groups[1].Value
    }
    $uri = [Uri]$ApiBaseUrl
    if (-not $uri.IsAbsoluteUri -or $uri.Scheme -ne 'https' -or $uri.AbsolutePath -ne '/api' -or
        $uri.Query -or $uri.Fragment -or $uri.UserInfo -or $uri.IsLoopback) {
        throw 'Pages requiere una URL HTTPS pública, sin credenciales y terminada en /api.'
    }
    if (-not $DryRun) {
        if (-not $env:CLOUDFLARE_API_TOKEN -or -not $env:CLOUDFLARE_ACCOUNT_ID) {
            throw 'Falta autenticación no interactiva preparada. Usa -DryRun; no se abrirá login.'
        }
        $dirty = @(& git -c "safe.directory=$($root.Replace('\','/'))" status --porcelain -- lib packages assets web pubspec.yaml pubspec.lock scripts/deploy_pages.ps1)
        if ($dirty.Count) { throw 'Revisar y versionar los cambios frontend antes de publicar.' }
    }
    Checked flutter analyze --no-fatal-infos
    Checked flutter test --reporter expanded
    Push-Location (Join-Path $root 'packages/correspondencia_api')
    try {
        Checked flutter test test/api_config_test.dart --dart-define=APP_ENV=production "--dart-define=API_BASE_URL=$ApiBaseUrl" --reporter expanded
    } finally { Pop-Location }
    Checked flutter pub get --enforce-lockfile
    Checked flutter build web --release --no-pub --base-href=/ --pwa-strategy=none --dart-define=APP_ENV=production "--dart-define=API_BASE_URL=$ApiBaseUrl"
    $build = Join-Path $root 'build/web'
    foreach ($name in @('index.html','main.dart.js','flutter_bootstrap.js','_redirects')) {
        if (-not (Test-Path -LiteralPath (Join-Path $build $name) -PathType Leaf)) { throw "Falta build/web/$name" }
    }
    if (Test-Path -LiteralPath (Join-Path $build '404.html')) { throw '404.html desactiva el fallback SPA nativo de Pages.' }
    $html = [IO.File]::ReadAllText((Join-Path $build 'index.html'))
    $js = [IO.File]::ReadAllText((Join-Path $build 'main.dart.js'))
    if (-not $html.Contains('<base href="/">') -or -not $js.Contains($ApiBaseUrl)) { throw 'Base href o endpoint compilado incorrectos.' }
    if ($js.Contains('http://localhost:8000') -or $js.Contains('/correspondencia/correspondencia/')) { throw 'Build no productivo.' }
    $redirects = @(Get-Content -LiteralPath (Join-Path $build '_redirects') | Where-Object { $_.Trim() -and -not $_.StartsWith('#') })
    $expected = @('/correspondencia/login /login 301','/correspondencia/consulta /consulta 301','/consulta-publica /consulta 301')
    if (@(Compare-Object $expected $redirects).Count) { throw '_redirects no coincide con las rutas canónicas.' }
    foreach ($file in (Get-ChildItem -LiteralPath $build -File -Recurse -Force)) {
        if ($file.Length -gt 25MB) { throw "Asset supera el límite de Pages: $($file.Name)" }
        if ($file.Name -match '^(\.env($|\.)|credentials.*\.json$|id_rsa|id_ed25519|cloudflared)' -or
            $file.Extension -in @('.pem','.key','.dump','.sql','.sqlite')) { throw 'Archivo privado dentro del build.' }
    }
    # Redaction lists legitimately contain secret FIELD NAMES; reject embedded
    # values, private keys and DB URLs rather than the names of protected fields.
    $secretAssignment = '(JWT_ACCESS_SECRET|PUBLIC_TRACKING_HMAC_SECRET|CLOUDFLARE_API_TOKEN)["'']?\s*[:=]\s*["''][^"'']{16,}'
    if ($js -match '-----BEGIN .*PRIVATE KEY-----|postgres(?:ql)?(?:\+\w+)?://' -or $js -match $secretAssignment -or
        $js -match 'eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}') {
        throw 'Se detectó configuración privada en el JavaScript.'
    }
    Write-Output "Build Pages validado: $build; API pública $ApiBaseUrl"
    Write-Output "Comando: npx --yes wrangler@$wranglerVersion pages deploy build/web --project-name=$project --branch=develop"
    if ($DryRun) {
        Write-Output 'DRY RUN: no se llamó a Wrangler, no hubo autenticación ni cambios Cloudflare.'
        return
    }
    $nodeVersion = & node --version
    if ($LASTEXITCODE -ne 0 -or [version]($nodeVersion.TrimStart('v')) -lt [version]'22.12.0') { throw 'Wrangler requiere Node >=22.12.0.' }
    # Isolated cwd: Wrangler must not auto-load the private backend .env or a
    # configuration from another project. Only build/web is uploaded.
    $temporary = Join-Path ([IO.Path]::GetTempPath()) ('corr-pages-' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($temporary) | Out-Null
    $oldCI = $env:CI
    $oldMetrics = $env:WRANGLER_SEND_METRICS
    Push-Location $temporary
    try {
        $env:CI = 'true'
        $env:WRANGLER_SEND_METRICS = 'false'
        Checked npx --yes "wrangler@$wranglerVersion" pages deploy $build "--project-name=$project" --branch=develop "--commit-hash=$sha"
    } finally {
        Pop-Location
        $env:CI = $oldCI
        $env:WRANGLER_SEND_METRICS = $oldMetrics
        # Only this freshly created temporary directory, checked before deletion.
        $resolved = [IO.Path]::GetFullPath($temporary)
        if ($resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase) -and
            [IO.Path]::GetFileName($resolved) -match '^corr-pages-[a-f0-9]{32}$') {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
} finally { Pop-Location }
