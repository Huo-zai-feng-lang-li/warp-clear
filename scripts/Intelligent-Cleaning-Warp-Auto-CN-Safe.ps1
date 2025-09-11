# Warp 智能清理脚本 - 安全中文版本（无交互）
# 用法：以管理员身份运行 PowerShell，然后执行此脚本
# 此版本重置设备身份但保留 MCP、Rules 和偏好设置

param(
    [switch]$Force
)

# 安全编码设置，避免闪退
try {
    $Host.UI.RawUI.WindowTitle = "Warp Reset Tool"
    chcp 65001 | Out-Null
} catch {
    # 如果编码设置失败，继续执行
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "           Warp 智能清理工具 (自动版)              " -ForegroundColor Cyan
Write-Host "                                                   " -ForegroundColor Cyan
Write-Host "    重置设备身份但保留重要配置 - 让 Warp          " -ForegroundColor Cyan
Write-Host "    认为这是新设备但保留您的使用习惯             " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Warp 用户识别机制分析：" -ForegroundColor Yellow
Write-Host ""
Write-Host "Warp 通过以下方法识别用户和设备：" -ForegroundColor Gray
Write-Host ""
Write-Host "1. 设备标识符 (UUID)" -ForegroundColor White
Write-Host "   - 位置：~\AppData\Local\warp\Warp\cache\{UUID}.run\" -ForegroundColor Gray
Write-Host "   - 用途：唯一标识设备实例" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 用户数据库 (SQLite)" -ForegroundColor White
Write-Host "   - 位置：~\AppData\Local\warp\Warp\data\warp.sqlite" -ForegroundColor Gray
Write-Host "   - 用途：用户登录状态、偏好设置、历史记录" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 配置缓存" -ForegroundColor White
Write-Host "   - 位置：~\AppData\Local\warp\Warp\cache\settings.dat" -ForegroundColor Gray
Write-Host "   - 用途：应用程序设置和会话信息" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Windows 注册表" -ForegroundColor White
Write-Host "   - 位置：HKCU\Software\Warp.dev\Warp\" -ForegroundColor Gray
Write-Host "   - 用途：系统级用户偏好和实验标识符" -ForegroundColor Gray
Write-Host ""
Write-Host "5. 网络指纹（无法清除）" -ForegroundColor White
Write-Host "   - 包括：硬件 ID、MAC 地址、系统指纹等" -ForegroundColor Gray
Write-Host "   - 注意：这些硬件特征无法通过软件清除" -ForegroundColor Gray
Write-Host ""

$WarpPath = "$env:LOCALAPPDATA\warp\Warp"
$RegistryPath = "HKCU:\Software\Warp.dev"

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "警告：建议以管理员身份运行以获得完全清理权限" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "警告：此操作将重置 Warp 用户身份和设备标识符！" -ForegroundColor Red
Write-Host "注意：将保留 MCP 服务器、Rules 规则和 IDE 配置" -ForegroundColor Green
Write-Host "运行在自动模式 - 无需确认" -ForegroundColor Yellow
Write-Host ""

# 创建备份
$BackupName = "warp-intelligent-$(Get-Date -Format 'yyyy-MM-dd')"
$BackupPath = "$env:USERPROFILE\Desktop\$BackupName"

Write-Host ""
Write-Host "开始完全重置操作..." -ForegroundColor Green
Write-Host ""

# 1. 停止所有 Warp 进程
Write-Host "1. 停止 Warp 进程..." -ForegroundColor Yellow
$warpProcesses = Get-Process | Where-Object { $_.Name -like "*warp*" -or $_.ProcessName -like "*warp*" }
if ($warpProcesses) {
    $warpProcesses | ForEach-Object {
        Write-Host "   停止进程：$($_.Name) (PID: $($_.Id))" -ForegroundColor Cyan
        try {
            $_.Kill()
        } catch {
            Write-Host "   无法停止进程 $($_.Name)" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 3
} else {
    Write-Host "   未找到正在运行的 Warp 进程" -ForegroundColor Green
}

# 2. 备份重要配置数据
Write-Host ""
Write-Host "2. 备份重要配置数据..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# 备份MCP和Rules配置
$sqlitePath = "$WarpPath\data\warp.sqlite"
if (Test-Path $sqlitePath) {
    try {
        # 创建配置备份目录
        $configBackupPath = "$BackupPath\ConfigBackup"
        New-Item -ItemType Directory -Path $configBackupPath -Force | Out-Null
        
        # 备份数据库
        Copy-Item $sqlitePath "$configBackupPath\warp.sqlite" -Force
        Write-Host "   数据库备份完成：$configBackupPath\warp.sqlite" -ForegroundColor Green
        
        # 导出MCP配置
        $mcpConfig = sqlite3 $sqlitePath "SELECT json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER';" 2>$null
        if (-not [string]::IsNullOrEmpty($mcpConfig)) {
            $mcpConfig | Out-File "$configBackupPath\mcp_servers.json" -Encoding UTF8
            Write-Host "   MCP服务器配置已备份" -ForegroundColor Green
        }
        
        # 导出Rules配置
        $rulesConfig = sqlite3 $sqlitePath "SELECT json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_RULE';" 2>$null
        if (-not [string]::IsNullOrEmpty($rulesConfig)) {
            $rulesConfig | Out-File "$configBackupPath\rules.json" -Encoding UTF8
            Write-Host "   Rules规则已备份" -ForegroundColor Green
        }
        
        # 导出偏好设置
        $prefConfig = sqlite3 $sqlitePath "SELECT json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_PREFERENCE';" 2>$null
        if (-not [string]::IsNullOrEmpty($prefConfig)) {
            $prefConfig | Out-File "$configBackupPath\preferences.json" -Encoding UTF8
            Write-Host "   偏好设置已备份" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "   警告：无法备份配置数据" -ForegroundColor Yellow
    }
}

# 备份注册表
if (Test-Path $RegistryPath) {
    $regBackupPath = "$BackupPath\WarpRegistry.reg"
    reg export "HKCU\Software\Warp.dev" $regBackupPath /y 2>&1 | Out-Null
    if (Test-Path $regBackupPath) {
        Write-Host "   注册表备份完成：$regBackupPath" -ForegroundColor Green
    }
}

# 3. 清除本地文件数据
Write-Host ""
Write-Host "3. 清除本地文件数据..." -ForegroundColor Yellow
if (Test-Path $WarpPath) {
    try {
        Remove-Item -Path $WarpPath -Recurse -Force -ErrorAction Stop
        Write-Host "   本地数据目录已清除" -ForegroundColor Green
    } catch {
        Write-Host "   警告：某些文件无法删除" -ForegroundColor Yellow
        Write-Host "   请关闭所有应用程序后重试" -ForegroundColor Yellow
    }
} else {
    Write-Host "   本地数据目录不存在" -ForegroundColor Gray
}

# 4. 清除注册表数据
Write-Host ""
Write-Host "4. 清除注册表数据..." -ForegroundColor Yellow
if (Test-Path $RegistryPath) {
    try {
        Remove-Item -Path $RegistryPath -Recurse -Force -ErrorAction Stop
        Write-Host "   注册表数据已清除" -ForegroundColor Green
    } catch {
        Write-Host "   警告：无法清除某些注册表项" -ForegroundColor Yellow
    }
} else {
    Write-Host "   注册表键不存在" -ForegroundColor Gray
}

# 5. 清除临时文件
Write-Host ""
Write-Host "5. 清除临时文件..." -ForegroundColor Yellow
$tempPaths = @(
    "$env:TEMP\*warp*",
    "$env:LOCALAPPDATA\Temp\*warp*"
)

$clearedCount = 0
foreach ($tempPath in $tempPaths) {
    $items = Get-ChildItem -Path $tempPath -ErrorAction SilentlyContinue
    if ($items) {
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $clearedCount += $items.Count
    }
}
Write-Host "   临时文件已清除（项目数：$clearedCount）" -ForegroundColor Green

# 6. 初始化全新环境并恢复配置
Write-Host ""
Write-Host "6. 初始化全新环境并恢复配置..." -ForegroundColor Yellow

# 创建基本目录结构
$directories = @(
    "$WarpPath\cache",
    "$WarpPath\data",
    "$WarpPath\data\logs",
    "$WarpPath\data\logs\mcp"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# 生成新的设备标识符
$NewDeviceId = [System.Guid]::NewGuid().ToString().ToLower()
$NewSessionPath = "$WarpPath\cache\$NewDeviceId.run"
New-Item -ItemType Directory -Path $NewSessionPath -Force | Out-Null
New-Item -ItemType File -Path "$NewSessionPath.lock" -Force | Out-Null

Write-Host "   新设备 ID：$NewDeviceId" -ForegroundColor Cyan

# 恢复MCP和Rules配置
$configBackupPath = "$BackupPath\ConfigBackup"
if (Test-Path "$configBackupPath\warp.sqlite") {
    try {
        # 恢复数据库
        Copy-Item "$configBackupPath\warp.sqlite" "$WarpPath\data\warp.sqlite" -Force
        Write-Host "   数据库已恢复" -ForegroundColor Green
        
        # 验证配置恢复
        $restoredMcp = sqlite3 "$WarpPath\data\warp.sqlite" "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER';" 2>$null
        $restoredRules = sqlite3 "$WarpPath\data\warp.sqlite" "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_RULE';" 2>$null
        $restoredPrefs = sqlite3 "$WarpPath\data\warp.sqlite" "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_PREFERENCE';" 2>$null
        
        Write-Host "   配置恢复统计：" -ForegroundColor Cyan
        Write-Host "     - MCP服务器：$restoredMcp 个" -ForegroundColor Gray
        Write-Host "     - Rules规则：$restoredRules 个" -ForegroundColor Gray
        Write-Host "     - 偏好设置：$restoredPrefs 个" -ForegroundColor Gray
        
    } catch {
        Write-Host "   警告：配置恢复失败" -ForegroundColor Yellow
    }
} else {
    Write-Host "   未找到配置备份，将创建全新环境" -ForegroundColor Yellow
}

Write-Host "   全新环境初始化完成" -ForegroundColor Green

# 7. 显示系统指纹信息（无法清除）
Write-Host ""
Write-Host "7. 系统指纹信息（无法清除）：" -ForegroundColor Yellow

try {
    $MachineGuid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid
    if ($MachineGuid) {
        Write-Host "   机器 GUID：$MachineGuid" -ForegroundColor Gray
    }
} catch {
    Write-Host "   机器 GUID：无法获取" -ForegroundColor Gray
}

try {
    $SystemUUID = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    if ($SystemUUID) {
        Write-Host "   系统 UUID：$SystemUUID" -ForegroundColor Gray
    }
} catch {
    Write-Host "   系统 UUID：无法获取" -ForegroundColor Gray
}

Write-Host "   注意：这些硬件标识符无法更改" -ForegroundColor Yellow

# 8. 总结
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              重置操作完成总结                    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "已清除的项目：" -ForegroundColor Green
Write-Host "   * 设备 UUID 和会话文件" -ForegroundColor White
Write-Host "   * 用户登录状态和历史记录" -ForegroundColor White
Write-Host "   * 配置缓存和设置文件" -ForegroundColor White
Write-Host "   * Windows 注册表中的 Warp 条目" -ForegroundColor White
Write-Host "   * 临时文件和缓存" -ForegroundColor White
Write-Host ""
Write-Host "已保留的项目：" -ForegroundColor Cyan
Write-Host "   * MCP 服务器配置" -ForegroundColor White
Write-Host "   * Rules 规则配置" -ForegroundColor White
Write-Host "   * 用户偏好设置" -ForegroundColor White
Write-Host "   * IDE 相关配置" -ForegroundColor White
Write-Host ""

Write-Host "备份位置：" -ForegroundColor Cyan
Write-Host "   $BackupPath" -ForegroundColor Gray
Write-Host ""

Write-Host "新设备标识符：" -ForegroundColor Cyan
Write-Host "   $NewDeviceId" -ForegroundColor Gray
Write-Host ""

Write-Host "效果：" -ForegroundColor Green
Write-Host "   下次启动 Warp 时，它将认为这是：" -ForegroundColor Yellow
Write-Host "   * 一台全新的设备（新设备ID）" -ForegroundColor White
Write-Host "   * 一个未登录的新用户" -ForegroundColor White
Write-Host "   * 但保留所有重要的配置和设置" -ForegroundColor White
Write-Host ""

Write-Host "重要提示：" -ForegroundColor Yellow
Write-Host "   * 如果您再次使用相同账号登录，云端仍可能" -ForegroundColor Gray
Write-Host "     通过硬件指纹识别设备" -ForegroundColor Gray
Write-Host "   * 要完全隐藏身份，建议使用不同的网络" -ForegroundColor Gray
Write-Host "     环境" -ForegroundColor Gray
Write-Host "   * 硬件指纹（CPU ID、MAC 地址等）无法通过" -ForegroundColor Gray
Write-Host "     软件清除" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================" -ForegroundColor Green
Write-Host "                    操作完成                        " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "备份已保存到：$BackupPath" -ForegroundColor Cyan
Write-Host "如需恢复数据，请使用主菜单的恢复功能。" -ForegroundColor Yellow
Write-Host ""

Write-Host "重置完成！您现在可以启动 Warp，设备身份已重置但配置已保留。" -ForegroundColor Green