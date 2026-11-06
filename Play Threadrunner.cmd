@echo off
cd /d "%~dp0"
if exist "builds\windows\Threadrunner.exe" (
  start "Threadrunner" "builds\windows\Threadrunner.exe"
  exit /b 0
)
if exist ".tools\godot\Godot_v4.7.2-stable_win64.exe" (
  start "Threadrunner" ".tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
  exit /b 0
)
echo Local engine/build missing. Read README.md for setup.
pause
