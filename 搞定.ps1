# ================================================
#   ClothingAR 一步到位
#   GitHub 云编译 -> 签名 -> IPA 到桌面
# ================================================
$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = Get-Location }
Set-Location $scriptDir
$RepoName = "ClothingAR"
$desktop = [Environment]::GetFolderPath("Desktop")

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ClothingAR  一键搞定" -ForegroundColor Cyan
Write-Host "  代码 -> GitHub -> 云编译 -> 签名 -> IPA" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "当前目录: $scriptDir" -ForegroundColor Gray
Write-Host ""

# ==========================================
# 0. 生成 pbxproj
# ==========================================
Write-Host "=== [0/5] 生成 Xcode 工程 ===" -ForegroundColor Yellow
if (Test-Path ".\gen_pbxproj.py") {
    python gen_pbxproj.py 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "pbxproj 生成失败，继续尝试..." -ForegroundColor Yellow
    }
} else {
    Write-Host "gen_pbxproj.py 不存在，跳过" -ForegroundColor Yellow
}
Write-Host ""

# ==========================================
# [1/5] 登录 GitHub
# ==========================================
Write-Host "=== [1/5] 登录 GitHub ===" -ForegroundColor Yellow

$authed = $false
try {
    $null = gh auth status 2>&1
    $authed = ($LASTEXITCODE -eq 0)
} catch { }

if (-not $authed) {
    Write-Host "即将弹出浏览器，授权登录即可"
    Write-Host ""
    Start-Sleep -Seconds 1
    gh auth login --web --git-protocol https --hostname github.com
    if ($LASTEXITCODE -ne 0) {
        Write-Host "再来一次..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        gh auth login --web --git-protocol https --hostname github.com
        if ($LASTEXITCODE -ne 0) {
            Write-Host "登录失败。手动运行: gh auth login --web" -ForegroundColor Red
            Read-Host "按回车退出"
            exit 1
        }
    }
}
Write-Host "[OK] 已登录 GitHub" -ForegroundColor Green
Write-Host ""

# ==========================================
# [2/5] 推送代码
# ==========================================
Write-Host "=== [2/5] 推送代码到 GitHub ===" -ForegroundColor Yellow

$user = (gh api user --jq '.login' 2>&1).Trim()
if (-not $user) {
    Write-Host "获取用户名失败，请确认已登录 GitHub" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}
Write-Host "GitHub 用户: $user"
$repoUrl = "https://github.com/$user/$RepoName"

# 确保 git remote
$remotes = git remote 2>&1
if (-not $remotes -or $remotes -notmatch "origin") {
    git remote add origin $repoUrl 2>$null
}

# 切换到 main 分支
git branch -M main 2>$null

# 添加所有文件（排除 .gitignore 中的）
git add -A 2>&1 | Out-Null
git commit -m "ClothingAR: initial commit" 2>&1 | Out-Null

# 创建或推送
$exists = $false
try { $null = gh repo view "$user/$RepoName" 2>&1; $exists = ($LASTEXITCODE -eq 0) } catch { }

if (-not $exists) {
    Write-Host "创建仓库 + 推送中..."
    gh repo create $RepoName --public --source . --push 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gh 创建失败，直接 git push..." -ForegroundColor Yellow
        git push -u origin main 2>&1
        if ($LASTEXITCODE -ne 0) {
            git push -u origin main --force 2>&1
        }
    }
} else {
    Write-Host "仓库已存在，推送更新..."
    git push -u origin main 2>&1
}
Write-Host "[OK] 代码已推送: $repoUrl" -ForegroundColor Green
Write-Host ""

# ==========================================
# [3/5] 触发编译
# ==========================================
Write-Host "=== [3/5] 触发云端编译 ===" -ForegroundColor Yellow

gh workflow run build.yml --repo "$user/$RepoName" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "无法自动触发，需要手动操作:" -ForegroundColor Yellow
    Write-Host "  $repoUrl/actions" -ForegroundColor Cyan
    Start-Process "$repoUrl/actions"
    Write-Host ""
    Write-Host "打开网页后 -> 点左侧 Build iOS IPA -> Run workflow -> 绿色按钮"
    Write-Host ""
    Read-Host "确认 workflow 正在运行后，按回车继续"
} else {
    Write-Host "[OK] Workflow 已触发" -ForegroundColor Green
}
Write-Host ""

# ==========================================
# [4/5] 等待编译 + 下载
# ==========================================
Write-Host "=== [4/5] 等待 macOS 云端编译 ===" -ForegroundColor Yellow
Write-Host "大约需要 5-8 分钟，耐心等待..."
Write-Host ""

$maxWait = 24       # 最多等 12 分钟
$waited = 0
$done = $false

while (-not $done -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 30
    $waited++

    $runs = gh run list --repo "$user/$RepoName" --workflow build.yml --limit 1 --json status,conclusion,databaseId 2>$null | ConvertFrom-Json

    if (-not $runs -or @($runs).Count -eq 0) {
        Write-Host "  [$waited/$maxWait] 等待 workflow 排队..."
        continue
    }

    $run = @($runs)[0]
    $runId = $run.databaseId
    $status = $run.status
    $conclusion = $run.conclusion

    Write-Host "  [$waited/$maxWait] 状态=$status  结论=$conclusion"

    if ($status -eq "completed") {
        if ($conclusion -eq "success") {
            Write-Host ""
            Write-Host "[OK] 编译成功！下载中..." -ForegroundColor Green
            gh run download $runId --repo "$user/$RepoName" -n "ClothingAR-unsigned" --dir . 2>&1
            $done = $true
        } elseif ($conclusion -eq "failure") {
            Write-Host ""
            Write-Host "[FAIL] 编译失败" -ForegroundColor Red
            Write-Host "查看详情: $repoUrl/actions/runs/$runId"
            Start-Process "$repoUrl/actions/runs/$runId"
            Read-Host "按回车退出"
            exit 1
        } else {
            Write-Host "  结论: $conclusion, 再等下..."
        }
    }
}

if (-not $done) {
    Write-Host ""
    Write-Host "超时了。手动去下载:" -ForegroundColor Yellow
    Write-Host "  $repoUrl/actions"
    Start-Process "$repoUrl/actions"
    Read-Host "下载好 ClothingAR-unsigned.ipa 放到项目目录后，按回车继续签名"
}

if (-not (Test-Path ".\ClothingAR-unsigned.ipa")) {
    Write-Host "没找到 ClothingAR-unsigned.ipa" -ForegroundColor Red
    Write-Host "请手动下载并放到: $scriptDir"
    Read-Host "放好后按回车"
}
if (-not (Test-Path ".\ClothingAR-unsigned.ipa")) {
    Write-Host "还是没有. 退出" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

$ipaSize = [math]::Round((Get-Item ".\ClothingAR-unsigned.ipa").Length / 1MB, 1)
Write-Host "[OK] ClothingAR-unsigned.ipa ($ipaSize MB)" -ForegroundColor Green
Write-Host ""

# ==========================================
# [5/5] 签名
# ==========================================
Write-Host "=== [5/5] 签名 ===" -ForegroundColor Yellow
Write-Host ""

# 找 zsign
$zsignPath = ".\zsign.exe"
if (-not (Test-Path $zsignPath)) {
    Write-Host "下载 zsign 签名工具..."
    $zsignZip = ".\_zsign.zip"

    $urls = @(
        "https://github.com/zhlynn/zsign/releases/download/v2.0/zsign_win64.zip",
        "https://github.com/zhlynn/zsign/releases/latest/download/zsign_win64.zip"
    )
    $downloaded = $false
    foreach ($u in $urls) {
        try {
            Invoke-WebRequest -Uri $u -OutFile $zsignZip -ErrorAction Stop
            $downloaded = $true
            break
        } catch { }
    }

    if (-not $downloaded) {
        Write-Host "自动下载失败" -ForegroundColor Red
        Write-Host "请手动下载 zsign: https://github.com/zhlynn/zsign/releases"
        Write-Host "把 zsign.exe 放到: $scriptDir"
        Read-Host "放好后按回车"
    } else {
        Expand-Archive -Path $zsignZip -DestinationPath . -Force
        Remove-Item $zsignZip -Force
    }
}

if (-not (Test-Path $zsignPath)) {
    Write-Host "仍然没有 zsign.exe" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}
Write-Host "[OK] zsign 就绪" -ForegroundColor Green

# 找证书和描述文件
$p12 = Get-ChildItem -Path $scriptDir -Filter "*.p12" | Select-Object -First 1
$mp  = Get-ChildItem -Path $scriptDir -Filter "*.mobileprovision" | Select-Object -First 1

if (-not $p12 -or -not $mp) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host " 还需要两样东西:"
    Write-Host ""
    Write-Host "  1. 证书 .p12 文件"
    Write-Host "  2. 描述文件 .mobileprovision"
    Write-Host ""
    Write-Host " 放到这个目录:"
    Write-Host "  $scriptDir"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "放好后按回车继续"

    $p12 = Get-ChildItem -Path $scriptDir -Filter "*.p12" | Select-Object -First 1
    $mp  = Get-ChildItem -Path $scriptDir -Filter "*.mobileprovision" | Select-Object -First 1
}

if (-not $p12 -or -not $mp) {
    Write-Host "缺少签名材料，退出" -ForegroundColor Red
    Write-Host "准备好后运行: .\搞定.ps1"
    Read-Host "按回车退出"
    exit 1
}

Write-Host "证书: $($p12.Name)" -ForegroundColor Gray
Write-Host "描述: $($mp.Name)" -ForegroundColor Gray
Write-Host ""

$pass = Read-Host "证书密码"

Write-Host ""
Write-Host "签名中..."
$result = & $zsignPath -k $p12.FullName -p $pass -m $mp.FullName -o ".\ClothingAR.ipa" ".\ClothingAR-unsigned.ipa" 2>&1
Write-Host $result

if ($LASTEXITCODE -eq 0 -and (Test-Path ".\ClothingAR.ipa")) {
    # 复制到桌面
    Copy-Item ".\ClothingAR.ipa" $desktop -Force
    $final = [math]::Round((Get-Item ".\ClothingAR.ipa").Length / 1MB, 1)

    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
    Write-Host "            全部完成!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ClothingAR.ipa  ($final MB)" -ForegroundColor White
    Write-Host "  ↓ 桌面上 ↓" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "安装:" -ForegroundColor Yellow
    Write-Host "  爱思助手 -> 连接iPhone -> 应用游戏 -> 导入安装"
    Write-Host "  AltStore -> 直接打开 IPA"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "签名失败" -ForegroundColor Red
    Write-Host "检查: 密码 / 证书和描述文件是否匹配 / zsign 版本"
}
Read-Host "按回车退出"
