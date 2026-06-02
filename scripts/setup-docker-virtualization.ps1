# Fix Docker Desktop "virtualization support was not detected" (Windows 11 Home OK)
# Run as Administrator:
#   Right-click scripts\setup-docker-virtualization.cmd -> Run as administrator
# Or:
#   powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Develop\AskLens\scripts\setup-docker-virtualization.ps1"
# Reboot is required before starting Docker Desktop.

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host ">> $Msg" -ForegroundColor Cyan
}

function Enable-WindowsFeature([string]$Name) {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction SilentlyContinue
    if (-not $feature) {
        Write-Host "  [SKIP] Feature not found: $Name" -ForegroundColor DarkGray
        return
    }
    if ($feature.State -eq "Enabled") {
        Write-Host "  [OK] Already enabled: $Name" -ForegroundColor Green
        return
    }
    Write-Host "  [ENABLE] $Name ..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName $Name -All -NoRestart | Out-Null
}

Write-Host ""
Write-Host "=== AskLens: Docker virtualization setup ===" -ForegroundColor Cyan
Write-Host "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
Write-Host ""

Write-Step "1/4 Check CPU virtualization (BIOS)"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if (-not $cpu.VirtualizationFirmwareEnabled) {
    Write-Host "[FAIL] Virtualization is disabled in BIOS (Intel VT-x / AMD-V)." -ForegroundColor Red
    Write-Host "Reboot into BIOS, enable Intel VT-x or AMD SVM, save, then run this script again." -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] VirtualizationFirmwareEnabled = True" -ForegroundColor Green

Write-Step "2/4 Enable Windows optional features (WSL2 + VM Platform)"
Enable-WindowsFeature "Microsoft-Windows-Subsystem-Linux"
Enable-WindowsFeature "VirtualMachinePlatform"
Enable-WindowsFeature "HypervisorPlatform"

Write-Step "3/4 Set hypervisor launch type and install WSL2"
$bcd = bcdedit /enum "{current}" 2>&1 | Out-String
if ($bcd -notmatch "hypervisorlaunchtype\s+auto") {
    Write-Host "  [SET] bcdedit hypervisorlaunchtype auto" -ForegroundColor Yellow
    bcdedit /set hypervisorlaunchtype auto | Out-Null
} else {
    Write-Host "  [OK] hypervisorlaunchtype = auto" -ForegroundColor Green
}

$wslExe = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($wslExe) {
    Write-Host "  [RUN] wsl --install --no-distribution" -ForegroundColor Yellow
    wsl --install --no-distribution 2>&1 | ForEach-Object { Write-Host "    $_" }
    wsl --set-default-version 2 2>&1 | ForEach-Object { Write-Host "    $_" }
} else {
    Write-Host "  [WARN] wsl.exe not found. After reboot, enable WSL in Optional Features." -ForegroundColor Yellow
}

Write-Step "4/4 Done"
Write-Host ""
Write-Host "REBOOT REQUIRED before Docker Desktop will work." -ForegroundColor Yellow
Write-Host ""
Write-Host "After reboot:" -ForegroundColor Cyan
Write-Host "  1. Docker Desktop -> Settings -> General -> Use the WSL 2 based engine"
Write-Host "  2. Settings -> Resources -> WSL Integration -> enable default distro"
Write-Host "  3. From repo root: .\scripts\start-local.ps1"
Write-Host ""
Write-Host "Verify (after reboot):" -ForegroundColor DarkGray
Write-Host "  Get-ComputerInfo | Select-Object HyperVisorPresent"
Write-Host "  wsl --status"
Write-Host ""

$answer = Read-Host "Reboot now? (Y/N)"
if ($answer -match '^[Yy]') {
    shutdown /r /t 30 /c "AskLens Docker virtualization setup - reboot in 30s"
    Write-Host "Reboot in 30 seconds. Cancel: shutdown /a" -ForegroundColor Yellow
}
