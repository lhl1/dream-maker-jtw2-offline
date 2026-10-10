@echo off
setlocal
cd /d "%~dp0Data"
start "" "%~dp0Data\flashplayer_32_sa.exe" "%~dp0Data\_start_.swf"
endlocal
