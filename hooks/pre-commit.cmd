@echo off
REM Pre-commit hook wrapper for WinHarden
REM Calls PowerShell validation script

setlocal enabledelayedexpansion

REM Get the directory where this script is located
set "HOOK_DIR=%~dp0"

REM Call PowerShell with the validation logic
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HOOK_DIR%pre-commit.ps1"

REM Exit with the same code as PowerShell
exit /b !ERRORLEVEL!
