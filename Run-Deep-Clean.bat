@echo off
chcp 65001 >nul 2>&1
echo Starting Warp Deep Clean Scanner...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; .\Deep-Clean-Warp.ps1}"
pause
