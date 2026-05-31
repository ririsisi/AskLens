# Stop AskLens local Docker middleware
# Usage: .\scripts\stop-local.ps1

$ErrorActionPreference = "Stop"
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ComposeDir = Join-Path $RepoRoot "deploy\local"

$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path $dockerBin) {
    $env:PATH = "$dockerBin;$env:PATH"
}

Write-Host ""
Write-Host "=== Stopping AskLens middleware ===" -ForegroundColor Cyan

Push-Location $ComposeDir
try {
    if (Test-Path ".\.env") {
        docker compose --env-file .\.env down
    } else {
        docker compose down
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] docker compose down failed." -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Middleware stopped." -ForegroundColor Green
} finally {
    Pop-Location
}
