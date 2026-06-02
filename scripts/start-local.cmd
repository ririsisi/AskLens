@echo off
REM AskLens local middleware (no PowerShell execution policy change required)
REM Usage from repo root:  scripts\start-local.cmd
REM Or double-click this file in Explorer.

chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"
exit /b %ERRORLEVEL%
