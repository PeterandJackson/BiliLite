@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
echo ================================================
echo   BiliLite 一键搞定
echo   代码- GitHub- 云编译- 签名- IPA
echo ================================================
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0搞定.ps1"
pause
