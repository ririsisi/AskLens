# 答镜AskLens 本地中间件启动（PostgreSQL + Elasticsearch + MinIO）
# 用法：.\scripts\start-local.ps1
# 后端/前端请自行在 Cursor 中启动（API Key 等环境变量在 launch.json 中配置）

$ErrorActionPreference = "Stop"
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ComposeDir = Join-Path $RepoRoot "deploy\local"

$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path $dockerBin) {
    $env:PATH = "$dockerBin;$env:PATH"
}

function Test-PortOpen {
    param([int]$Port)
    $result = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue
    return $result.TcpTestSucceeded
}

function Assert-DockerRunning {
    $oldErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $serverVersion = docker version --format "{{.Server.Version}}" 2>$null
    $ErrorActionPreference = $oldErrorAction
    if (-not $serverVersion) {
        Write-Host ""
        Write-Host "[错误] Docker 未运行，请先启动 Docker Desktop。" -ForegroundColor Red
        exit 1
    }
}

function Wait-ServiceHealthy {
    param(
        [string]$Name,
        [scriptblock]$Check,
        [int]$TimeoutSec = 120
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (& $Check) {
            Write-Host "  [OK] $Name" -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 2
    }
    throw "$Name 在 ${TimeoutSec}s 内未就绪，请查看: docker compose -f deploy/local/docker-compose.yml logs"
}

Write-Host ""
Write-Host "=== 答镜AskLens 中间件启动 ===" -ForegroundColor Cyan
Write-Host "项目目录: $RepoRoot"
Write-Host ""

Assert-DockerRunning

if (-not (Test-Path (Join-Path $ComposeDir ".env")) -and (Test-Path (Join-Path $ComposeDir ".env.example"))) {
    Copy-Item (Join-Path $ComposeDir ".env.example") (Join-Path $ComposeDir ".env")
    Write-Host "[提示] 已根据 .env.example 创建 deploy/local/.env（DaoCloud 镜像加速）" -ForegroundColor Yellow
}

if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
    throw "未找到 deploy/local/docker-compose.yml"
}

Write-Host "[1/2] 启动中间件 (PostgreSQL / Elasticsearch / MinIO) ..." -ForegroundColor Cyan
Push-Location $ComposeDir
try {
    if (Test-Path ".\.env") {
        docker compose --env-file .\.env up -d --build
    } else {
        docker compose up -d --build
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[错误] docker compose 失败，常见原因：" -ForegroundColor Red
        Write-Host "  1) 无法拉取镜像 - 检查 deploy/local/.env 中的 DOCKER_MIRROR" -ForegroundColor Yellow
        Write-Host "  2) 端口冲突 (5432/9200/9000) - 关闭占用端口的其他服务" -ForegroundColor Yellow
        throw "docker compose up failed"
    }
} finally {
    Pop-Location
}

Write-Host "[2/2] 等待中间件就绪 ..." -ForegroundColor Cyan
Wait-ServiceHealthy "PostgreSQL :5432" { Test-PortOpen -Port 5432 }
Wait-ServiceHealthy "Elasticsearch :9200" { Test-PortOpen -Port 9200 }
Wait-ServiceHealthy "MinIO :9000" { Test-PortOpen -Port 9000 }

Write-Host ""
Write-Host "中间件已就绪：" -ForegroundColor Green
Write-Host "  PostgreSQL    localhost:5432  (asklens / postgres / postgres)"
Write-Host "  Elasticsearch http://localhost:9200"
Write-Host "  MinIO 控制台  http://localhost:9001  (minioadmin / minioadmin)"
Write-Host ""
Write-Host "接下来请自行启动：" -ForegroundColor Cyan
Write-Host "  后端: Cursor F5 或 运行和调试 -> AskLens Backend (local)"
Write-Host "  前端: cd AskLens-frontend; npm run dev  -> http://127.0.0.1:3000"
Write-Host ""
Write-Host "停止中间件: .\scripts\stop-local.ps1" -ForegroundColor DarkGray
