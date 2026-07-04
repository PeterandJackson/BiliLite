# 🎬 YouTube 视频下载器

浏览器中使用的 YouTube 视频下载工具，现代化暗色界面，开箱即用。

## 快速开始

```bash
pip install -r requirements.txt
python app.py
```

浏览器打开 **http://127.0.0.1:5000**

## 功能

- 🎨 暗色主题 Web 界面
- 🔍 粘贴链接一键获取视频信息
- 🎯 多画质：最佳质量 / 1080p / 720p / 480p / 360p
- 📊 实时下载进度（进度条 + 速度 + 剩余时间）
- 🧵 后台下载，不卡界面，支持取消
- 🔑 代理检测弹窗提醒

## 注意

- 项目自带 ffmpeg.exe，不需要额外安装
- 国内用户需要开启代理才能访问 YouTube

## 打包

```bash
build.bat
# 输出: dist/YouTube-Downloader.exe
```
