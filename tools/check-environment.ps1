# Warp 清理工具集 - 环境检查脚本
# 用于检查系统兼容性和运行环境

# 设置控制台编码
try {
    $Host.UI.RawUI.WindowTitle = "Warp 清理工具集 - 环境检查"
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 忽略编码设置错误
}

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              Warp 清理工具集 - 环境检查                  " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 检查 PowerShell 版本
Write-Host "1. PowerShell 版本检查" -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
$psVersionOK = $psVersion.Major -ge 5
Write-Host "   版本: $psVersion" -ForegroundColor $(if($psVersionOK){"Green"}else{"Red"})
Write-Host "   状态: $(if($psVersionOK){"✓ 兼容"}else{"✗ 需要 5.1 或更高版本"})" -ForegroundColor $(if($psVersionOK){"Green"}else{"Red"})
Write-Host ""

# 检查操作系统
Write-Host "2. 操作系统检查" -ForegroundColor Yellow
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = [System.Environment]::OSVersion.Version
$osVersionOK = $osVersion.Major -ge 10
Write-Host "   系统: $($osInfo.Caption)" -ForegroundColor $(if($osVersionOK){"Green"}else{"Yellow"})
Write-Host "   版本: $($osVersion)" -ForegroundColor $(if($osVersionOK){"Green"}else{"Yellow"})
Write-Host "   状态: $(if($osVersionOK){"✓ 兼容"}else{"⚠ 建议 Windows 10 或更高版本"})" -ForegroundColor $(if($osVersionOK){"Green"}else{"Yellow"})
Write-Host ""

# 检查管理员权限
Write-Host "3. 权限检查" -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "   管理员权限: $(if($isAdmin){"是"}else{"否"})" -ForegroundColor $(if($isAdmin){"Green"}else{"Yellow"})
Write-Host "   状态: $(if($isAdmin){"✓ 已获取"}else{"⚠ 建议以管理员身份运行"})" -ForegroundColor $(if($isAdmin){"Green"}else{"Yellow"})
Write-Host ""

# 检查执行策略
Write-Host "4. 执行策略检查" -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
$policyOK = $executionPolicy -in @("Unrestricted", "RemoteSigned", "Bypass")
Write-Host "   当前策略: $executionPolicy" -ForegroundColor $(if($policyOK){"Green"}else{"Yellow"})
Write-Host "   状态: $(if($policyOK){"✓ 允许执行"}else{"⚠ 可能需要调整 (工具会自动处理)"})" -ForegroundColor $(if($policyOK){"Green"}else{"Yellow"})
Write-Host ""

# 检查 Warp 安装
Write-Host "5. Warp 客户端检查" -ForegroundColor Yellow
$warpPath = "$env:LOCALAPPDATA\warp"
$warpInstalled = Test-Path $warpPath
Write-Host "   安装路径: $warpPath" -ForegroundColor Gray
Write-Host "   安装状态: $(if($warpInstalled){"已安装"}else{"未安装"})" -ForegroundColor $(if($warpInstalled){"Green"}else{"Yellow"})
Write-Host "   状态: $(if($warpInstalled){"✓ 检测到 Warp"}else{"⚠ 未检测到 Warp (可能未安装或安装在其他位置)"})" -ForegroundColor $(if($warpInstalled){"Green"}else{"Yellow"})
Write-Host ""

# 检查工具文件完整性
Write-Host "6. 工具文件检查" -ForegroundColor Yellow
$requiredFiles = @(
    "start.bat",
    "tools\main.ps1",
    "scripts\Deep-Clean-Warp-Auto-CN-Safe.ps1",
    "scripts\Reset-Warp-Fixed-Auto-CN-Safe.ps1",
    "scripts\Secondary-UID-Migration-Auto-CN-Safe.ps1"
)

$allFilesOK = $true
foreach ($file in $requiredFiles) {
    $exists = Test-Path $file
    $allFilesOK = $allFilesOK -and $exists
    Write-Host "   $file : $(if($exists){"✓"}else{"✗"})" -ForegroundColor $(if($exists){"Green"}else{"Red"})
}
Write-Host "   状态: $(if($allFilesOK){"✓ 所有文件完整"}else{"✗ 缺少必要文件"})" -ForegroundColor $(if($allFilesOK){"Green"}else{"Red"})
Write-Host ""

# 总体评估
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    环境检查结果                          " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$overallOK = $psVersionOK -and $allFilesOK
if ($overallOK) {
    Write-Host "✓ 环境检查通过！可以正常使用 Warp 清理工具集。" -ForegroundColor Green
} else {
    Write-Host "⚠ 环境检查发现问题，请查看上述详细信息。" -ForegroundColor Yellow
}

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "建议：为获得最佳效果，请以管理员身份运行工具。" -ForegroundColor Yellow
}

if (-not $warpInstalled) {
    Write-Host ""
    Write-Host "提示：未检测到 Warp 客户端，清理工具仍可运行但可能无实际效果。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
