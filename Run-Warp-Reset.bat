@echo off
chcp 65001 >nul 2>&1
echo Starting Warp Reset Tool...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; .\Reset-Warp-Fixed.ps1}"
pause
