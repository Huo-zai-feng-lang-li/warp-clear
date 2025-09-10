# Warp清理工具 - 在线运行版本
# 用法: irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/run-warp-clean.ps1 | iex

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("reset", "deep", "migrate", "help")]
    [string]$Action = "help"
)

# 安全编码设置
try {
    $Host.UI.RawUI.WindowTitle = "Warp Clean Tool - Online"
    chcp 65001 | Out-Null
} catch {}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "           Warp 清理工具 - 在线版本              " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

if ($Action -eq "help") {
    Write-Host "可用命令:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 标准重置 (推荐):" -ForegroundColor Green
    Write-Host "   irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/run-warp-clean.ps1 | iex -Action reset" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 深度清理:" -ForegroundColor Green
    Write-Host "   irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/run-warp-clean.ps1 | iex -Action deep" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. UID迁移 (登录新账号后):" -ForegroundColor Green
    Write-Host "   irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/run-warp-clean.ps1 | iex -Action migrate" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. 显示帮助:" -ForegroundColor Green
    Write-Host "   irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/run-warp-clean.ps1 | iex" -ForegroundColor Gray
    Write-Host ""
    Write-Host "注意: 建议以管理员身份运行PowerShell" -ForegroundColor Yellow
    Write-Host ""
    return
}

Write-Host "正在下载并执行 $Action 脚本..." -ForegroundColor Yellow
Write-Host ""

try {
    $scriptUrl = "https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/"
    
    switch ($Action) {
        "reset" {
            $scriptUrl += "Reset-Warp-Fixed-Auto-CN-Safe.ps1"
            Write-Host "执行标准重置..." -ForegroundColor Green
        }
        "deep" {
            $scriptUrl += "Deep-Clean-Warp-Auto-CN-Safe.ps1"
            Write-Host "执行深度清理..." -ForegroundColor Green
        }
        "migrate" {
            $scriptUrl += "Secondary-UID-Migration-Auto-CN-Safe.ps1"
            Write-Host "执行UID迁移..." -ForegroundColor Green
        }
    }
    
    Write-Host "下载地址: $scriptUrl" -ForegroundColor Gray
    Write-Host ""
    
    # 下载并执行脚本
    $scriptContent = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop
    Invoke-Expression $scriptContent.Content
    
} catch {
    Write-Host "错误: 无法下载或执行脚本" -ForegroundColor Red
    Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "请检查网络连接或稍后重试" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
