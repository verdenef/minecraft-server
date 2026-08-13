@echo off
title Ferium Mod Manager Launcher
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0script\MOD_MANAGER.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [CRITICAL ERROR] The Mod Manager exited with error code %ERRORLEVEL%.
    pause
)
