@echo off
chcp 65001 >nul
:: 以管理员运行本文件，绕过 PowerShell 执行策略
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Right-click this file and choose "Run as administrator"
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-docker-virtualization.ps1"
pause
