# Warp 清理工具集 - 简化启动脚本

# 安全编码设置
try {
    $Host.UI.RawUI.WindowTitle = "Warp 清理工具集"
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 如果编码设置失败，继续执行
}

# 清屏
Clear-Host

# 显示主菜单
function Show-Menu {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                    Warp 清理工具集                        " -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "请选择要执行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Warp 深度清理 - ♻️ 全面扫描并移除所有标识符" -ForegroundColor Green
    Write-Host "  [2] Warp 智能清理 - 🌟 重置身份保留Rules、Mcp、Preference配置" -ForegroundColor Green
    Write-Host "  [3] 二次 UID 迁移 - ❤️ 登录新账号后执行" -ForegroundColor Green
    Write-Host "  [4] 恢复备份数据 - 从备份文件夹恢复清理前的数据" -ForegroundColor Magenta
    Write-Host "  [0] 退出程序" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# 恢复备份数据
function Restore-WarpBackup {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "                    Warp 数据恢复工具                      " -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""

    # 查找桌面上的备份文件夹
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $backupFolders = Get-ChildItem -Path $desktopPath -Directory | Where-Object { $_.Name -like "warp-*" } | Sort-Object Name -Descending

    if ($backupFolders.Count -eq 0) {
        Write-Host "未找到任何备份文件夹！" -ForegroundColor Red
        Write-Host "备份文件夹应该位于桌面，格式为：warp-类型-YYYY-MM-DD" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "按任意键返回主菜单..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Write-Host "找到以下备份文件夹：" -ForegroundColor Green
    Write-Host ""

    for ($i = 0; $i -lt $backupFolders.Count; $i++) {
        $folder = $backupFolders[$i]
        Write-Host "  [$($i + 1)] $($folder.Name)" -ForegroundColor Cyan
        Write-Host "      创建时间：$($folder.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  [0] 返回主菜单" -ForegroundColor Red
    Write-Host ""

    do {
        Write-Host "请选择要恢复的备份 (0-$($backupFolders.Count))：" -ForegroundColor Yellow -NoNewline
        $choice = Read-Host

        if ($choice -eq "0") {
            return
        }

        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $backupFolders.Count) {
            $selectedBackup = $backupFolders[$index]
            $backupPath = $selectedBackup.FullName

            Write-Host ""
            Write-Host "选择的备份：$($selectedBackup.Name)" -ForegroundColor Green
            Write-Host "备份路径：$backupPath" -ForegroundColor Gray
            Write-Host ""
            Write-Host "警告：恢复操作将覆盖当前的 Warp 配置！" -ForegroundColor Red
            Write-Host "确认要继续吗？输入 'y' 确认：" -ForegroundColor Yellow -NoNewline
            $confirm = Read-Host

            if ($confirm -eq "y") {
                Perform-Restore -BackupPath $backupPath
            } else {
                Write-Host "恢复操作已取消。" -ForegroundColor Yellow
            }
            break
        } else {
            Write-Host "无效的选择！请输入正确的编号。" -ForegroundColor Red
        }
    } while ($true)

    Write-Host ""
    $userChoice = Show-PostExecutionMenu
    return $userChoice
}

# 执行恢复操作
function Perform-Restore {
    param([string]$BackupPath)

    Write-Host ""
    Write-Host "开始恢复 Warp 数据..." -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor DarkGray

    try {
        # 停止 Warp 进程
        Write-Host "正在停止 Warp 进程..." -ForegroundColor Yellow
        Get-Process -Name "*warp*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        # 恢复文件
        $warpDataPath = "$env:LOCALAPPDATA\warp\Warp"
        $backupWarpPath = Join-Path $BackupPath "Warp"

        if (Test-Path $backupWarpPath) {
            Write-Host "正在恢复 Warp 数据文件..." -ForegroundColor Yellow

            if (Test-Path $warpDataPath) {
                Remove-Item $warpDataPath -Recurse -Force
            }

            Copy-Item $backupWarpPath -Destination $warpDataPath -Recurse -Force
            Write-Host "✓ Warp 数据文件恢复完成" -ForegroundColor Green
        }

        # 恢复注册表
        $registryBackupPath = Join-Path $BackupPath "WarpRegistry.reg"

        if (Test-Path $registryBackupPath) {
            Write-Host "正在恢复注册表..." -ForegroundColor Yellow

            # 导入注册表
            $result = Start-Process -FilePath "reg" -ArgumentList "import", "`"$registryBackupPath`"" -Wait -PassThru -WindowStyle Hidden

            if ($result.ExitCode -eq 0) {
                Write-Host "✓ 注册表恢复完成" -ForegroundColor Green
            } else {
                Write-Host "⚠ 注册表恢复可能失败，退出代码：$($result.ExitCode)" -ForegroundColor Yellow
            }
        }

        Write-Host "============================================================" -ForegroundColor DarkGray
        Write-Host "恢复操作完成！" -ForegroundColor Green
        Write-Host ""
        Write-Host "建议重启 Warp 应用程序以确保恢复生效。" -ForegroundColor Cyan

    } catch {
        Write-Host ""
        Write-Host "恢复过程中出现错误：" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# 脚本执行后的用户选择菜单
function Show-PostExecutionMenu {
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "  [Enter] 返回主菜单    [Esc] 关闭程序" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "请选择操作：" -ForegroundColor Cyan -NoNewline

    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            13 {  # Enter 键
                Write-Host " [返回主菜单]" -ForegroundColor Green
                return "menu"
            }
            27 {  # Esc 键
                Write-Host " [关闭程序]" -ForegroundColor Red
                return "exit"
            }
            default {
                # 忽略其他按键，继续等待
            }
        }
    } while ($true)
}

# 执行脚本
function Run-Script {
    param([string]$ScriptName, [string]$ScriptPath)
    
    Write-Host "正在执行：$ScriptName" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "错误：脚本文件不存在！" -ForegroundColor Red
        Write-Host "路径：$ScriptPath" -ForegroundColor Red
        return
    }
    
    try {
        Write-Host "开始执行脚本..." -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor DarkGray
        
        # 设置执行策略并运行脚本
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        & $ScriptPath
        
        Write-Host "============================================================" -ForegroundColor DarkGray
        Write-Host "脚本执行完成！" -ForegroundColor Green
        
    } catch {
        Write-Host "脚本执行出错：" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    
    Write-Host ""
    $userChoice = Show-PostExecutionMenu
    return $userChoice
}

# 主程序循环
do {
    Clear-Host
    Show-Menu
    
    Write-Host "请输入选项编号 (0-4)：" -ForegroundColor Yellow -NoNewline
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            $scriptPath = Join-Path (Split-Path $PSScriptRoot) "scripts\Deep-Clean-Warp-Auto-CN-Safe.ps1"
            $result = Run-Script -ScriptName "Warp 深度清理" -ScriptPath $scriptPath
            if ($result -eq "exit") { $choice = "0"; break }
        }

        "2" {
            $scriptPath = Join-Path (Split-Path $PSScriptRoot) "scripts\Intelligent-Cleaning-Warp-Auto-CN-Safe.ps1"
            $result = Run-Script -ScriptName "Warp 智能清理" -ScriptPath $scriptPath
            if ($result -eq "exit") { $choice = "0"; break }
        }

        "3" {
            $scriptPath = Join-Path (Split-Path $PSScriptRoot) "scripts\Secondary-UID-Migration-Auto-CN-Safe.ps1"
            $result = Run-Script -ScriptName "二次 UID 迁移" -ScriptPath $scriptPath
            if ($result -eq "exit") { $choice = "0"; break }
        }

        "4" {
            $result = Restore-WarpBackup
            if ($result -eq "exit") { $choice = "0"; break }
        }
        
        "0" {
            Write-Host ""
            Write-Host "感谢使用 Warp 清理工具集！" -ForegroundColor Green
            Write-Host "程序即将退出..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            break
        }
        
        default {
            Write-Host ""
            Write-Host "无效的选项！请输入 0-4 之间的数字。" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
} while ($choice -ne "0")

Write-Host ""
Write-Host "程序已退出。" -ForegroundColor Gray
