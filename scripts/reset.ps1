# Warp 标准重置 - 在线运行版本
# 用法: irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/reset.ps1 | iex

Write-Host "正在下载并执行标准重置脚本..." -ForegroundColor Yellow
Write-Host ""

try {
    $scriptUrl = "https://raw.githubusercontent.com/Huo-zai-feng-lang-li/warp-clear/main/scripts/Reset-Warp-Fixed-Auto-CN-Safe.ps1"
    Write-Host "下载地址: $scriptUrl" -ForegroundColor Gray
    Write-Host ""
    
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
