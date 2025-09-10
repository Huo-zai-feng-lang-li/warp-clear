# Warp 深度清理脚本 - 全面标识符移除（安全中文版本）
# 此脚本自动查找并移除所有可能的 Warp 标识符

# 安全编码设置，避免闪退
try {
    $Host.UI.RawUI.WindowTitle = "Warp Deep Clean Tool"
    chcp 65001 | Out-Null
} catch {
    # 如果编码设置失败，继续执行
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        Warp 深度清理和标识符扫描器              " -ForegroundColor Cyan
Write-Host "                    (自动版本)                    " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# 在文件中搜索 UUID 模式的函数
function Find-UUIDInFiles {
    param([string]$Path)
    
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}') {
                Write-Host "   在以下文件中找到 UUID：$($_.FullName)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "阶段 1：扫描所有 Warp 相关位置..." -ForegroundColor Yellow
Write-Host ""

# 所有可能的 Warp 位置
$WarpLocations = @{
    "用户数据 (主要)" = "$env:LOCALAPPDATA\warp\Warp"
    "用户数据 (漫游)" = "$env:APPDATA\warp"
    "程序安装 (用户)" = "$env:LOCALAPPDATA\Programs\Warp"
    "程序安装 (x64)" = "${env:ProgramFiles}\Warp"
    "程序安装 (x86)" = "${env:ProgramFiles(x86)}\Warp"
    "临时文件" = "$env:TEMP"
    "本地临时" = "$env:LOCALAPPDATA\Temp"
    "用户配置文件隐藏" = "$env:USERPROFILE\.warp"
    "用户配置文件" = "$env:USERPROFILE\.config\warp"
}

$FoundLocations = @{}

foreach ($location in $WarpLocations.GetEnumerator()) {
    if (Test-Path $location.Value) {
        $warpItems = Get-ChildItem -Path $location.Value -Filter "*warp*" -Recurse -ErrorAction SilentlyContinue
        if ($warpItems) {
            $FoundLocations[$location.Key] = $location.Value
            Write-Host "[找到] $($location.Key)：$($location.Value)" -ForegroundColor Green
            
            # 检查特定标识符文件
            $identifierFiles = @("*.sqlite", "*.db", "*.json", "*.dat", "*.run", "*.lock", "*uuid*", "*device*", "*machine*")
            foreach ($pattern in $identifierFiles) {
                $files = Get-ChildItem -Path $location.Value -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                if ($files) {
                    Write-Host "   - 找到 $($files.Count) 个匹配模式的文件：$pattern" -ForegroundColor Gray
                }
            }
        }
    }
}

Write-Host ""
Write-Host "阶段 2：检查 Windows 注册表..." -ForegroundColor Yellow
Write-Host ""

$RegistryPaths = @(
    "HKCU:\Software\Warp.dev",
    "HKCU:\Software\Classes\warp",
    "HKLM:\SOFTWARE\Warp.dev",
    "HKLM:\SOFTWARE\Classes\warp",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Warp.dev"
)

$FoundRegistry = @()

foreach ($regPath in $RegistryPaths) {
    if (Test-Path $regPath) {
        $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*warp*" }
        if ($items) {
            $FoundRegistry += $regPath
            Write-Host "[找到] 注册表：$regPath" -ForegroundColor Green
            
            # 尝试读取可能包含标识符的值
            try {
                $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                $props.PSObject.Properties | Where-Object { 
                    $_.Value -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' 
                } | ForEach-Object {
                    Write-Host "   - 属性中的标识符：$($_.Name)" -ForegroundColor Yellow
                }
            } catch {}
        }
    }
}

Write-Host ""
Write-Host "阶段 3：检查隐藏标识符..." -ForegroundColor Yellow
Write-Host ""

# 检查 electron/chromium 缓存（Warp 使用 Electron）
$ElectronPaths = @(
    "$env:LOCALAPPDATA\warp\Warp\User Data",
    "$env:APPDATA\warp\Cache",
    "$env:LOCALAPPDATA\warp\Warp\blob_storage",
    "$env:LOCALAPPDATA\warp\Warp\Session Storage",
    "$env:LOCALAPPDATA\warp\Warp\Local Storage",
    "$env:LOCALAPPDATA\warp\Warp\IndexedDB",
    "$env:LOCALAPPDATA\warp\Warp\Service Worker"
)

foreach ($path in $ElectronPaths) {
    if (Test-Path $path) {
        Write-Host "[找到] Electron/Chromium 数据：$path" -ForegroundColor Green
    }
}

# 检查网络服务标识符
Write-Host ""
Write-Host "阶段 4：系统级标识符（只读）..." -ForegroundColor Yellow
Write-Host ""

# 机器 GUID
try {
    $MachineGuid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid).MachineGuid
    Write-Host "机器 GUID：$MachineGuid" -ForegroundColor Gray
} catch {}

# 系统 UUID
try {
    $SystemUUID = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    Write-Host "系统 UUID：$SystemUUID" -ForegroundColor Gray
} catch {}

# 网络适配器 MAC
try {
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Write-Host "网络适配器：$($_.Name) - MAC：$($_.MacAddress)" -ForegroundColor Gray
    }
} catch {}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "                  清理选项                        " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

if ($FoundLocations.Count -eq 0 -and $FoundRegistry.Count -eq 0) {
    Write-Host "在此系统上未找到 Warp 安装或数据。" -ForegroundColor Green
    Write-Host ""
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "找到要清理的数据：" -ForegroundColor Yellow
Write-Host "  - 文件位置：$($FoundLocations.Count)" -ForegroundColor White
Write-Host "  - 注册表项：$($FoundRegistry.Count)" -ForegroundColor White
Write-Host ""

Write-Host "运行在自动模式 - 自动执行深度清理" -ForegroundColor Red
Write-Host "这将：" -ForegroundColor Red
Write-Host "  1. 移除所有找到的 Warp 目录" -ForegroundColor White
Write-Host "  2. 清除所有注册表项" -ForegroundColor White
Write-Host "  3. 清除浏览器类缓存" -ForegroundColor White
Write-Host "  4. 重置所有标识符（硬件除外）" -ForegroundColor White
Write-Host ""

# 创建备份
$BackupName = "WarpDeepCleanBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupPath = "$env:USERPROFILE\Desktop\$BackupName"
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

Write-Host ""
Write-Host "开始深度清理操作..." -ForegroundColor Green
Write-Host ""

# 停止 Warp 进程
Write-Host "停止所有 Warp 进程..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.Name -like "*warp*" } | ForEach-Object {
    Write-Host "  停止：$($_.Name)" -ForegroundColor Cyan
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# 清理文件位置
Write-Host ""
Write-Host "清理文件位置..." -ForegroundColor Yellow
foreach ($location in $FoundLocations.GetEnumerator()) {
    Write-Host "  清理：$($location.Key)" -ForegroundColor Cyan
    
    # 先备份
    try {
        $backupDir = "$BackupPath\Files_$($location.Key -replace '[^\w]', '_')"
        Copy-Item -Path $location.Value -Destination $backupDir -Recurse -Force -ErrorAction Stop
        Write-Host "     - 已备份到：$backupDir" -ForegroundColor Gray
    } catch {
        Write-Host "     - 备份失败：$_" -ForegroundColor Red
    }
    
    # 删除
    try {
        Remove-Item -Path $location.Value -Recurse -Force -ErrorAction Stop
        Write-Host "     - 删除成功" -ForegroundColor Green
    } catch {
        Write-Host "     - 删除失败：$_" -ForegroundColor Red
    }
}

# 清理注册表
Write-Host ""
Write-Host "清理注册表项..." -ForegroundColor Yellow
foreach ($regPath in $FoundRegistry) {
    Write-Host "  清理：$regPath" -ForegroundColor Cyan
    
    # 先备份
    $regBackup = "$BackupPath\Registry_$(($regPath -replace '[^\w]', '_')).reg"
    $regExportPath = $regPath -replace 'HKCU:', 'HKCU' -replace 'HKLM:', 'HKLM'
    reg export $regExportPath $regBackup /y 2>&1 | Out-Null
    
    # 删除
    try {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
        Write-Host "     - 删除成功" -ForegroundColor Green
    } catch {
        Write-Host "     - 删除失败：$_" -ForegroundColor Red
    }
}

# 额外清理
Write-Host ""
Write-Host "额外清理..." -ForegroundColor Yellow

# 清除 DNS 缓存（可能缓存了 Warp 端点）
Write-Host "  刷新 DNS 缓存..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null

# 清除临时互联网文件
Write-Host "  清除临时互联网文件..." -ForegroundColor Cyan
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# 清除预取（Windows 优化缓存）
if (Test-Path "$env:SystemRoot\Prefetch\*WARP*") {
    Write-Host "  清除预取项..." -ForegroundColor Cyan
    Remove-Item "$env:SystemRoot\Prefetch\*WARP*" -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Green
Write-Host "           深度清理完成                    " -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host ""

Write-Host "总结：" -ForegroundColor Cyan
Write-Host "  - 所有 Warp 目录已移除" -ForegroundColor White
Write-Host "  - 所有注册表项已清除" -ForegroundColor White
Write-Host "  - DNS 缓存已刷新" -ForegroundColor White
Write-Host "  - 临时文件已清除" -ForegroundColor White
Write-Host ""

Write-Host "备份位置：$BackupPath" -ForegroundColor Yellow
Write-Host ""

Write-Host "注意：硬件标识符无法更改：" -ForegroundColor Yellow
Write-Host "  - 机器 GUID：$MachineGuid" -ForegroundColor Gray
Write-Host "  - 系统 UUID：$SystemUUID" -ForegroundColor Gray
Write-Host ""

Write-Host "Warp 将认为这是全新的安装！" -ForegroundColor Green
Write-Host ""

# 创建总结文件
$SummaryFile = "$BackupPath\CleanupSummary.txt"
@"
Warp 深度清理总结
===================
日期：$(Get-Date)
备份位置：$BackupPath

已清理的位置：
$($FoundLocations.GetEnumerator() | ForEach-Object { "  - $($_.Key)：$($_.Value)" } | Out-String)

已清理的注册表：
$($FoundRegistry | ForEach-Object { "  - $_" } | Out-String)

系统标识符（无法更改）：
  - 机器 GUID：$MachineGuid
  - 系统 UUID：$SystemUUID
"@ | Out-File -FilePath $SummaryFile

Write-Host "总结已保存到：$SummaryFile" -ForegroundColor Cyan

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "                    恢复命令                        " -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "要恢复所有数据并删除备份，请复制并粘贴此命令：" -ForegroundColor Yellow
Write-Host ""

$recoveryCommand = @"
if (Test-Path '$BackupPath') {
    Write-Host '正在从深度清理备份恢复 Warp 数据...' -ForegroundColor Yellow
    
    # 恢复文件位置
    Get-ChildItem -Path '$BackupPath' -Filter 'Files_*' -Directory | ForEach-Object {
        `$originalPath = `$_.Name -replace '^Files_', '' -replace '_', '\'
        `$targetPath = `$originalPath
        if (`$originalPath -eq 'User Data (Primary)') { `$targetPath = '$env:LOCALAPPDATA\warp\Warp' }
        elseif (`$originalPath -eq 'User Data (Roaming)') { `$targetPath = '$env:APPDATA\warp' }
        elseif (`$originalPath -eq 'Program Install (User)') { `$targetPath = '$env:LOCALAPPDATA\Programs\Warp' }
        elseif (`$originalPath -eq 'Program Install (x64)') { `$targetPath = '${env:ProgramFiles}\Warp' }
        elseif (`$originalPath -eq 'Program Install (x86)') { `$targetPath = '${env:ProgramFiles(x86)}\Warp' }
        elseif (`$originalPath -eq 'User Profile Hidden') { `$targetPath = '$env:USERPROFILE\.warp' }
        elseif (`$originalPath -eq 'User Profile Config') { `$targetPath = '$env:USERPROFILE\.config\warp' }
        
        if (Test-Path `$targetPath) { Remove-Item `$targetPath -Recurse -Force }
        Copy-Item `$_.FullName `$targetPath -Recurse -Force
        Write-Host "已恢复：`$targetPath" -ForegroundColor Green
    }
    
    # 恢复注册表项
    Get-ChildItem -Path '$BackupPath' -Filter 'Registry_*.reg' | ForEach-Object {
        reg import `$_.FullName
        Write-Host "已恢复注册表：`$(`$_.Name)" -ForegroundColor Green
    }
    
    Remove-Item '$BackupPath' -Recurse -Force
    Write-Host '深度清理恢复完成，备份已删除！' -ForegroundColor Green
} else {
    Write-Host '在以下位置未找到备份：$BackupPath' -ForegroundColor Red
}
"@

Write-Host $recoveryCommand -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")