@echo off
chcp 65001 >nul
echo 正在编译：项目3 - 温度转换器 ...
gcc main.c -o main.exe -Wall
if %errorlevel% equ 0 (
    echo 编译成功！正在运行...
    echo.
    main.exe
) else (
    echo 编译失败，请检查代码是否有误。
)
pause
