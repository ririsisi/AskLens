@echo off
REM Stop AskLens local middleware (no execution policy change required)
REM Usage from repo root:  scripts\stop-local.cmd

chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-local.ps1"
exit /b %ERRORLEVEL%
