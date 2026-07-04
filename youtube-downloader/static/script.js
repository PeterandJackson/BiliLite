/**
 * YouTube Downloader — 前端交互逻辑
 * 使用 SSE (Server-Sent Events) 实现实时进度推送
 */

// ── DOM 引用 ────────────────────────────────────────────
const $ = (sel) => document.querySelector(sel);

const urlInput       = $("#urlInput");
const btnPaste       = $("#btnPaste");
const btnFetch       = $("#btnFetch");
const infoCard       = $("#infoCard");
const thumbImg       = $("#thumbImg");
const infoTitle      = $("#infoTitle");
const infoDuration   = $("#infoDuration");
const infoUploader   = $("#infoUploader");
const qualitySelect  = $("#qualitySelect");
const dirInput       = $("#dirInput");
const proxyInput     = $("#proxyInput");
const btnBrowse      = $("#btnBrowse");
const progressCard   = $("#progressCard");
const progressFill   = $("#progressFill");
const percentText    = $("#percentText");
const speedText      = $("#speedText");
const etaText        = $("#etaText");
const btnDownload    = $("#btnDownload");
const btnDownloadTxt = $("#btnDownloadText");
const statusText     = $("#statusText");

// 弹窗
const proxyModal     = $("#proxyModal");
const proxyModalBody = $("#proxyModalBody");
const btnModalClose  = $("#btnModalClose");

let currentTaskId  = null;
let isDownloading  = false;
let proxyChecked   = false;  // 本次会话是否已检测过代理
let proxyIsOk      = false;  // 代理是否通

// ── 初始化 ──────────────────────────────────────────────
function init() {
    fetch("/api/default-dir", { method: "POST" }).catch(() => {});
    dirInput.value = "C:\\Users\\Administrator\\Downloads";

    btnPaste.addEventListener("click", onPaste);
    btnFetch.addEventListener("click", onFetch);
    btnBrowse.addEventListener("click", onBrowse);
    btnDownload.addEventListener("click", onDownload);
    urlInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") onFetch();
    });

    // 弹窗关闭
    btnModalClose.addEventListener("click", () => {
        proxyModal.style.display = "none";
    });
    proxyModal.addEventListener("click", (e) => {
        if (e.target === proxyModal) proxyModal.style.display = "none";
    });
}

// ── 代理检测 ────────────────────────────────────────────
async function checkProxy() {
    const proxy = proxyInput.value.trim();
    if (!proxy) {
        return true; // 没填代理就跳过检测
    }
    if (proxyChecked) {
        return proxyIsOk;
    }

    setStatus("🔍 正在检测代理连接...", "info");
    try {
        const res = await fetch("/api/check-proxy", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ proxy }),
        });
        const data = await res.json();
        proxyChecked = true;
        proxyIsOk = data.ok;

        if (!data.ok) {
            showProxyModal(data.message);
            setStatus("⚠️ 代理不通，请检查后重试", "warning");
        } else {
            setStatus("✅ 代理连接正常", "success");
        }
        return data.ok;
    } catch (e) {
        proxyChecked = true;
        proxyIsOk = false;
        showProxyModal("无法连接到后端服务器");
        return false;
    }
}

function showProxyModal(msg) {
    proxyModalBody.textContent = msg || "检测不到代理连接，请先开启代理软件（如 Clash Verge、V2RayN 等），然后在代理设置栏填入正确的代理地址。";
    proxyModal.style.display = "flex";
}

// ── 粘贴 ────────────────────────────────────────────────
async function onPaste() {
    try {
        const text = await navigator.clipboard.readText();
        if (text) {
            urlInput.value = text.trim();
            setStatus("📋 已粘贴，点击获取信息", "info");
        }
    } catch {
        setStatus("⚠️ 无法访问剪贴板，请手动粘贴", "warning");
    }
}

// ── 获取视频信息 ────────────────────────────────────────
async function onFetch() {
    const url = urlInput.value.trim();
    if (!url) return setStatus("⚠️ 请先输入视频 URL", "warning");

    // 检查代理
    const proxyOk = await checkProxy();
    if (!proxyOk) return;

    setStatus("🔍 正在获取视频信息...", "info");
    btnFetch.disabled = true;
    btnFetch.textContent = "⏳ 获取中...";
    infoCard.style.display = "none";

    try {
        const res = await fetch("/api/info", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ url, proxy: proxyInput.value.trim() }),
        });
        const data = await res.json();

        if (data.ok) {
            infoCard.style.display = "block";
            if (data.thumbnail) {
                thumbImg.src = data.thumbnail;
                thumbImg.parentElement.style.display = "";
            } else {
                thumbImg.parentElement.style.display = "none";
            }
            infoTitle.textContent = data.title;
            infoDuration.textContent = "⏱ " + data.duration_str;
            infoUploader.textContent = "👤 " + data.uploader;
            setStatus("✅ 信息获取成功，可以选择画质开始下载", "success");
        } else {
            infoCard.style.display = "none";
            setStatus("❌ " + data.error, "error");
            // 如果失败且报了网络错，可能是代理问题
            if (data.error.includes("代理") || data.error.includes("timeout") || data.error.includes("Connection")) {
                showProxyModal("获取视频信息失败，请检查代理是否开启或代理地址是否正确。\n\n" + data.error);
            }
        }
    } catch (e) {
        setStatus("❌ 网络错误，请检查连接和代理", "error");
        showProxyModal("请求失败，可能是代理未开启或网络不通。");
    } finally {
        btnFetch.disabled = false;
        btnFetch.textContent = "🔍 获取信息";
    }
}

// ── 浏览文件夹 ──────────────────────────────────────────
async function onBrowse() {
    try {
        if ("showDirectoryPicker" in window) {
            const handle = await window.showDirectoryPicker({ mode: "readwrite" });
            dirInput.value = handle.name;
        } else {
            const path = prompt("请输入或粘贴保存路径:", dirInput.value);
            if (path) dirInput.value = path.trim();
        }
    } catch (e) {
        if (e.name !== "AbortError") {
            const path = prompt("请输入或粘贴保存路径:", dirInput.value);
            if (path) dirInput.value = path.trim();
        }
    }
}

// ── 下载 / 取消 ─────────────────────────────────────────
async function onDownload() {
    if (isDownloading) {
        if (currentTaskId) {
            await fetch("/api/cancel/" + currentTaskId, { method: "POST" });
        }
        setStatus("⏹ 正在取消...", "warning");
        return;
    }

    const url = urlInput.value.trim();
    if (!url) return setStatus("⚠️ 请先输入视频 URL", "warning");

    // 检查代理
    const proxyOk = await checkProxy();
    if (!proxyOk) return;

    const quality = qualitySelect.value;
    const outputDir = dirInput.value.trim();

    setStatus("📥 正在启动下载...", "info");
    btnDownload.disabled = true;

    try {
        const res = await fetch("/api/download", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ url, quality, output_dir: outputDir, proxy: proxyInput.value.trim() }),
        });
        const data = await res.json();

        if (data.ok) {
            currentTaskId = data.task_id;
            enterDownloadMode();
            listenProgress(data.task_id);
        } else {
            setStatus("❌ " + data.error, "error");
            btnDownload.disabled = false;
        }
    } catch (e) {
        setStatus("❌ 请求失败: " + e.message, "error");
        btnDownload.disabled = false;
    }
}

// ── SSE 监听进度 ────────────────────────────────────────
function listenProgress(taskId) {
    const es = new EventSource("/api/progress/" + taskId);

    es.onmessage = (event) => {
        const msg = JSON.parse(event.data);

        switch (msg.type) {
            case "progress":
                updateProgress(msg.percent, msg.speed, msg.eta);
                break;
            case "complete":
                updateProgress(100, "", "");
                es.close();
                onDownloadComplete(msg);
                break;
            case "error":
                es.close();
                onDownloadError(msg.message);
                break;
            case "cancelled":
                es.close();
                onDownloadCancelled(msg.message);
                break;
            case "heartbeat":
                break;
        }
    };

    es.onerror = () => {
        if (!isDownloading) es.close();
    };
}

// ── 进度更新 ────────────────────────────────────────────
function updateProgress(percent, speed, eta) {
    progressCard.style.display = "block";
    progressFill.style.width = percent + "%";
    percentText.textContent = percent + "%";
    speedText.textContent = speed ? "⚡ " + speed : "";
    etaText.textContent = eta ? "⏱ 剩余 " + eta : "";
    if (percent > 0) {
        setStatus("📥 下载中... " + percent + "%", "info");
    }
}

// ── 下载模式切换 ────────────────────────────────────────
function enterDownloadMode() {
    isDownloading = true;
    btnDownload.classList.add("cancelling");
    btnDownloadTxt.textContent = "取消下载";
    btnDownload.disabled = false;
    urlInput.disabled = true;
    btnFetch.disabled = true;
    qualitySelect.disabled = true;
    progressCard.style.display = "block";
    progressFill.style.width = "0%";
    percentText.textContent = "0%";
    speedText.textContent = "";
    etaText.textContent = "";
}

function exitDownloadMode() {
    isDownloading = false;
    currentTaskId = null;
    btnDownload.classList.remove("cancelling");
    btnDownloadTxt.textContent = "开始下载";
    btnDownload.disabled = false;
    urlInput.disabled = false;
    btnFetch.disabled = false;
    qualitySelect.disabled = false;
}

// ── 完成 / 错误 / 取消 ──────────────────────────────────
function onDownloadComplete(msg) {
    exitDownloadMode();
    setStatus("✅ 下载完成！" + msg.filename, "success");
    progressFill.style.width = "100%";
    percentText.textContent = "100%";
    if (confirm("下载完成！是否打开文件夹？\n\n" + msg.filename)) {
        fetch("/api/open-folder", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ dirname: msg.dirname }),
        }).catch(() => {});
    }
}

function onDownloadError(message) {
    exitDownloadMode();
    setStatus("❌ " + message, "error");
    progressCard.style.display = "none";
    // 网络错误大概率是代理问题
    if (/timeout|Connection|unreachable|resolve/i.test(message)) {
        showProxyModal("下载失败，很可能是代理问题。\n\n" + message);
    }
}

function onDownloadCancelled(message) {
    exitDownloadMode();
    setStatus("⏹ " + message, "info");
    progressCard.style.display = "none";
}

// ── 状态栏 ──────────────────────────────────────────────
function setStatus(text, type) {
    statusText.textContent = text;
    statusText.className = "status " + (type || "");
}

// ── 启动 ────────────────────────────────────────────────
init();
