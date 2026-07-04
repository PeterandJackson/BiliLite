@echo off
chcp 65001 >nul
echo ========================================
echo   YouTube Downloader Web - 打包工具
echo ========================================
echo.
echo [1/3] 正在安装 PyInstaller...
pip install pyinstaller -q
echo.
echo [2/3] 正在打包为单个 exe 文件...
pyinstaller --onefile --windowed --name "YouTube-Downloader" ^
    --add-data "templates;templates" ^
    --add-data "static;static" ^
    --hidden-import=yt_dlp ^
    --hidden-import=flask ^
    --hidden-import=jinja2 ^
    app.py
echo.
echo [3/3] 打包完成！
echo.
echo 输出文件在: dist\YouTube-Downloader.exe
echo.
pause
