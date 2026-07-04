"""
YouTube 视频下载器 — Flask Web 后端
提供 REST API + SSE 实时进度推送
"""

import os
import re
import subprocess
import queue
import json
import socket
import urllib.request
import threading
from flask import Flask, render_template, request, jsonify, Response

import yt_dlp

app = Flask(__name__)

# ffmpeg 路径（项目目录下的 ffmpeg.exe）
FFMPEG_DIR = os.path.dirname(os.path.abspath(__file__))
FFMPEG_PATH = os.path.join(FFMPEG_DIR, "ffmpeg.exe")
if not os.path.exists(FFMPEG_PATH):
    FFMPEG_DIR = None  # 回退到系统 PATH

# ── 画质映射（需要 ffmpeg 合成视频+音频） ───
QUALITY_FORMATS = {
    "最佳质量": "bestvideo+bestaudio/best",
    "1080p": "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
    "720p": "bestvideo[height<=720]+bestaudio/best[height<=720]",
    "480p": "bestvideo[height<=480]+bestaudio/best[height<=480]",
    "360p": "bestvideo[height<=360]+bestaudio/best[height<=360]",
}

# ── 全局下载任务管理 ─────────────────────────────────────
_download_tasks = {}
_task_counter = 0


# ── 代理检测 ──────────────────────────────────────────────

def _test_proxy(proxy_url: str, timeout: int = 4) -> tuple[bool, str]:
    """
    测试代理是否可用。
    尝试通过代理访问 youtube.com，超时 4 秒。
    返回 (可用, 提示信息)
    """
    if not proxy_url:
        return False, "未设置代理地址"

    try:
        req = urllib.request.Request("https://www.youtube.com", method="HEAD")
        req.get_method = lambda: "HEAD"

        parts = proxy_url.split("://", 1)
        if len(parts) == 2:
            scheme, addr = parts
        else:
            scheme, addr = "http", parts[0]

        host, _, port_str = addr.partition(":")
        port = int(port_str) if port_str else (1080 if "socks" in scheme else 80)

        # 先用 TCP 测代理端口
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()

        if result != 0:
            return False, f"代理 {host}:{port} 端口不通，请检查代理是否开启"

        # 端口通，构造代理 handler 真正测试
        proxy_handler = urllib.request.ProxyHandler({scheme: proxy_url})
        opener = urllib.request.build_opener(proxy_handler)
        opener.open(req, timeout=timeout)
        return True, "代理连接正常"

    except urllib.request.URLError as e:
        return False, f"代理连接失败: 无法通过代理访问外网"
    except Exception as e:
        return False, f"代理检测异常: {e}"


# ── 路由：页面 ────────────────────────────────────────────

@app.route("/")
def index():
    return render_template("index.html", qualities=list(QUALITY_FORMATS.keys()))


# ── 路由：代理检测 ────────────────────────────────────────

@app.route("/api/check-proxy", methods=["POST"])
def api_check_proxy():
    data = request.get_json()
    proxy = data.get("proxy", "").strip()
    ok, msg = _test_proxy(proxy)
    return jsonify({"ok": ok, "message": msg})


# ── 路由：获取视频信息 ────────────────────────────────────

@app.route("/api/info", methods=["POST"])
def api_info():
    data = request.get_json()
    url = data.get("url", "").strip()
    proxy = data.get("proxy", "").strip()
    if not url:
        return jsonify({"ok": False, "error": "请输入视频 URL"}), 400

    try:
        opts = {
            "quiet": True,
            "no_warnings": True,
            "extract_flat": False,
            "socket_timeout": 10,
        }
        if FFMPEG_DIR:
            opts["ffmpeg_location"] = FFMPEG_DIR
        if proxy:
            opts["proxy"] = proxy
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)

        duration_sec = info.get("duration", 0) or 0
        minutes, seconds = divmod(duration_sec, 60)
        hours, minutes = divmod(minutes, 60)
        duration_str = (
            f"{hours}:{minutes:02d}:{seconds:02d}" if hours > 0
            else f"{minutes}:{seconds:02d}"
        )

        return jsonify({
            "ok": True,
            "title": info.get("title", "未知"),
            "duration_str": duration_str,
            "uploader": info.get("uploader", "未知"),
            "thumbnail": info.get("thumbnail", ""),
        })
    except Exception as e:
        msg = str(e)
        # 标记是否可能因为网络/代理
        hint = ""
        if any(kw in msg.lower() for kw in ["connection", "timeout", "unreachable", "resolve"]):
            hint = "（可能是代理未开启或网络不通）"
        return jsonify({"ok": False, "error": f"获取失败: {msg}{hint}"}), 400


# ── 路由：开始下载 ────────────────────────────────────────

@app.route("/api/download", methods=["POST"])
def api_download():
    global _task_counter
    data = request.get_json()
    url = data.get("url", "").strip()
    quality = data.get("quality", "1080p")
    proxy = data.get("proxy", "").strip()
    output_dir = data.get("output_dir", os.path.join(os.path.expanduser("~"), "Downloads"))

    if not url:
        return jsonify({"ok": False, "error": "请输入视频 URL"}), 400

    _task_counter += 1
    task_id = f"dl_{_task_counter}"
    q = queue.Queue()
    cancel_evt = threading.Event()

    thread = threading.Thread(
        target=_do_download,
        args=(task_id, url, quality, output_dir, q, cancel_evt, proxy),
        daemon=True,
    )
    _download_tasks[task_id] = {"queue": q, "cancel": cancel_evt, "thread": thread}
    thread.start()

    return jsonify({"ok": True, "task_id": task_id})


# ── 路由：取消下载 ────────────────────────────────────────

@app.route("/api/cancel/<task_id>", methods=["POST"])
def api_cancel(task_id):
    task = _download_tasks.get(task_id)
    if task:
        task["cancel"].set()
        return jsonify({"ok": True})
    return jsonify({"ok": False, "error": "任务不存在"}), 404


# ── 路由：获取默认下载目录 ──────────────────────────────

@app.route("/api/default-dir", methods=["POST"])
def api_default_dir():
    downloads = os.path.join(os.path.expanduser("~"), "Downloads")
    return jsonify({"ok": True, "path": downloads})


# ── 路由：打开文件夹 ──────────────────────────────────────

@app.route("/api/open-folder", methods=["POST"])
def api_open_folder():
    data = request.get_json()
    dirname = data.get("dirname", "")
    if dirname and os.path.isdir(dirname):
        try:
            if os.name == "nt":
                os.startfile(dirname)
            else:
                subprocess.Popen(["open", dirname])
            return jsonify({"ok": True})
        except Exception as e:
            return jsonify({"ok": False, "error": str(e)})
    return jsonify({"ok": False, "error": "目录不存在"})


# ── 路由：SSE 进度推送 ────────────────────────────────────

@app.route("/api/progress/<task_id>")
def api_progress(task_id):
    task = _download_tasks.get(task_id)
    if not task:
        return Response("data: {\"error\":\"任务不存在\"}\n\n", mimetype="text/event-stream")

    q = task["queue"]

    def generate():
        while True:
            try:
                msg = q.get(timeout=30)
                yield f"data: {json.dumps(msg)}\n\n"
                if msg.get("type") in ("complete", "error", "cancelled"):
                    break
            except queue.Empty:
                yield f"data: {json.dumps({'type': 'heartbeat'})}\n\n"

    return Response(generate(), mimetype="text/event-stream")


# ── 实际下载逻辑 ──────────────────────────────────────────

def _do_download(task_id, url, quality, output_dir, q, cancel_evt, proxy=""):
    format_str = QUALITY_FORMATS.get(quality, QUALITY_FORMATS["最佳质量"])

    def progress_hook(d):
        if cancel_evt.is_set():
            raise Exception("__CANCELLED__")

        status = d.get("status", "")
        if status == "downloading":
            total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
            downloaded = d.get("downloaded_bytes", 0)
            percent = int(downloaded / total * 100) if total > 0 else 0
            speed = d.get("speed") or 0
            eta = d.get("eta") or 0

            if speed > 1024 * 1024:
                speed_str = f"{speed / 1024 / 1024:.1f} MB/s"
            elif speed > 1024:
                speed_str = f"{speed / 1024:.1f} KB/s"
            else:
                speed_str = f"{speed:.0f} B/s"

            if eta > 60:
                eta_str = f"{eta // 60}分{eta % 60}秒"
            else:
                eta_str = f"{eta}秒"

            q.put({
                "type": "progress",
                "percent": percent,
                "speed": speed_str,
                "eta": eta_str,
            })

        elif status == "finished":
            q.put({"type": "progress", "percent": 100, "speed": "", "eta": "处理中..."})

    opts = {
        "format": format_str,
        "outtmpl": f"{output_dir}/%(title)s [%(height)sp].%(ext)s",
        "progress_hooks": [progress_hook],
        "quiet": True,
        "no_warnings": True,
        "windowsfilenames": True,
        "socket_timeout": 30,
        "ffmpeg_location": FFMPEG_DIR,
        "merge_output_format": "mp4",
    }
    if proxy:
        opts["proxy"] = proxy

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
            filepath = ydl.prepare_filename(info)

        if cancel_evt.is_set():
            q.put({"type": "cancelled", "message": "下载已取消"})
        else:
            q.put({
                "type": "complete",
                "filepath": filepath,
                "filename": os.path.basename(filepath),
                "dirname": os.path.dirname(filepath),
            })

    except Exception as e:
        msg = str(e)
        if "__CANCELLED__" in msg:
            q.put({"type": "cancelled", "message": "下载已取消"})
        else:
            q.put({"type": "error", "message": f"下载失败: {msg}"})
    finally:
        _download_tasks.pop(task_id, None)


# ── 入口 ──────────────────────────────────────────────────

if __name__ == "__main__":
    print("YouTube Downloader - Web")
    print("   Open: http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000, debug=True, threaded=True)
