# ============================================
# BiliLite Windows 签名脚本 (PowerShell)
# 依赖: zsign.exe (放到同目录下)
# ============================================
#
# 用法:
#   .\sign.ps1 -P12Path ".\cert.p12" -Password "你的密码" -ProvisionPath ".\app.mobileprovision"
#
# 准备材料:
#   1. cert.p12       — Apple Developer 证书 (Keychain导出)
#   2. .mobileprovision — 描述文件 (Apple Developer 后台下载)
#   3. zsign.exe      — https://github.com/zhlynn/zsign/releases
# ============================================

param(
    [Parameter(Mandatory=$true)]
    [string]$P12Path,

    [Parameter(Mandatory=$true)]
    [string]$Password,

    [Parameter(Mandatory=$true)]
    [string]$ProvisionPath,

    [string]$InputIPA = ".\BiliLite-unsigned.ipa",
    [string]$OutputIPA = ".\BiliLite.ipa",
    [string]$ZsignPath = ".\zsign.exe"
)

$ErrorActionPreference = "Stop"

# 检查文件
if (-not (Test-Path $InputIPA)) {
    Write-Error "❌ 未找到 IPA: $InputIPA — 先从 GitHub Actions 下载"
    exit 1
}
if (-not (Test-Path $P12Path)) {
    Write-Error "❌ 未找到证书: $P12Path"
    exit 1
}
if (-not (Test-Path $ProvisionPath)) {
    Write-Error "❌ 未找到描述文件: $ProvisionPath"
    exit 1
}
if (-not (Test-Path $ZsignPath)) {
    Write-Error "❌ 未找到 zsign.exe: $ZsignPath — 从 https://github.com/zhlynn/zsign/releases 下载"
    exit 1
}

Write-Host "🔐 正在签名 BiliLite..."
Write-Host "   证书: $P12Path"
Write-Host "   描述: $ProvisionPath"
Write-Host "   输入: $InputIPA"
Write-Host "   输出: $OutputIPA"
Write-Host ""

& $ZsignPath `
    -k $P12Path `
    -p $Password `
    -m $ProvisionPath `
    -o $OutputIPA `
    $InputIPA

if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputIPA)) {
    $size = (Get-Item $OutputIPA).Length / 1MB
    Write-Host ""
    Write-Host "========================================"
    Write-Host "✅ 签名完成！"
    Write-Host "   $OutputIPA ({0:N1} MB)" -f $size
    Write-Host "========================================"
    Write-Host ""
    Write-Host "📱 安装方式:"
    Write-Host "   • AltStore / SideStore → 直接导入 IPA"
    Write-Host "   • 爱思助手 → 连接 iPhone → 应用游戏 → 导入安装"
    Write-Host "   • 3uTools → 同上"
} else {
    Write-Error "❌ 签名失败"
    exit 1
}
