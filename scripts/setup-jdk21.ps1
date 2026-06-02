# 安装 / 检测 JDK 21（与 AskLens-backend pom.xml 一致）
# 用法: .\scripts\setup-jdk21.ps1

$ErrorActionPreference = "Stop"

function Find-Jdk21Home {
    $candidates = @(
        ${env:JAVA_HOME},
        "D:\Develop\jdk-21",
        "C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot"
    )
    foreach ($root in $candidates) {
        if ($root -and (Test-Path (Join-Path $root "bin\java.exe"))) {
            $ver = & (Join-Path $root "bin\java.exe") -version 2>&1 | Out-String
            if ($ver -match '"21\.') { return $root }
        }
    }
    $ms = Get-ChildItem "C:\Program Files\Microsoft" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "jdk-21*" } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($ms -and (Test-Path (Join-Path $ms.FullName "bin\java.exe"))) {
        return $ms.FullName
    }
    return $null
}

$jdkHome = Find-Jdk21Home
if (-not $jdkHome) {
    Write-Host "未检测到 JDK 21，尝试 winget 安装 Microsoft OpenJDK 21 ..." -ForegroundColor Yellow
    winget install -e --id Microsoft.OpenJDK.21 --accept-package-agreements --accept-source-agreements
    $jdkHome = Find-Jdk21Home
}

if (-not $jdkHome) {
    Write-Host "[失败] 仍未找到 JDK 21。请手动安装后更新 .vscode/settings.json 中的路径。" -ForegroundColor Red
    exit 1
}

Write-Host "JDK 21: $jdkHome" -ForegroundColor Green
& (Join-Path $jdkHome "bin\java.exe") -version
Write-Host ""
Write-Host "请将以下路径写入 .vscode/settings.json（从 settings.json.example 复制后修改）：" -ForegroundColor Cyan
Write-Host "  java.jdt.ls.java.home / JAVA_HOME / java.configuration.runtimes[0].path"
Write-Host "  => $jdkHome"
