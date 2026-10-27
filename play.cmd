@echo off
rem GLM Arcade launcher - starts a local server (needed for PWA install + offline mode) and opens the game.
cd /d "%~dp0"
set PORT=8137

where node >nul 2>nul
if %errorlevel%==0 (
  start "GLM Arcade" cmd /c "timeout /t 1 >nul & start "" http://localhost:%PORT%/ & node server.js %PORT%"
  exit /b
)

where py >nul 2>nul
if %errorlevel%==0 (
  start "GLM Arcade" cmd /c "timeout /t 1 >nul & start "" http://localhost:%PORT%/ & py server.py %PORT%"
  exit /b
)

where python >nul 2>nul
if %errorlevel%==0 (
  start "GLM Arcade" cmd /c "timeout /t 1 >nul & start "" http://localhost:%PORT%/ & python server.py %PORT%"
  exit /b
)

start "GLM Arcade" powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 1; Start-Process 'http://localhost:%PORT%/'; & '%~dp0server.ps1' %PORT%"
