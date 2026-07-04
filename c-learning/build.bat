@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   C 语言学习项目 - 一键编译脚本
echo ========================================
echo.

REM 查找 GCC 编译器
set GCC=
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_*") do (
    if exist "%%d\mingw64\bin\gcc.exe" (
        set "GCC=%%d\mingw64\bin\gcc.exe"
    )
)

if "%GCC%"=="" (
    echo [错误] 找不到 GCC 编译器！
    echo 请先安装：winget install BrechtSanders.WinLibs.POSIX.UCRT
    echo 安装后请重新打开终端再试。
    pause
    exit /b 1
)

echo 使用编译器：%GCC%
echo.

set SUCCESS=0
set FAIL=0

for /d %%p in (0*) do (
    if exist "%%p\main.c" (
        echo [编译] %%p\main.c ...
        "%GCC%" "%%p\main.c" -o "%%p\main.exe" -Wall 2>&1
        if !errorlevel! equ 0 (
            echo   [OK] 编译成功 - %%p\main.exe
            set /a SUCCESS+=1
        ) else (
            echo   [FAIL] 编译失败！
            set /a FAIL+=1
        )
        echo.
    )
)

echo ========================================
echo   编译完成：!SUCCESS! 个成功，!FAIL! 个失败
echo ========================================
echo.
echo 进入对应目录，运行 main.exe 来启动程序。
echo 例如：cd 01-hello-calc ^&^& main.exe
echo.

pause
