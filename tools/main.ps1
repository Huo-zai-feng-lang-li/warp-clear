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

# 显示公众号二维码
function Show-WeChatQR {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "                    🎉 技术公众号推广 🎉                    " -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔍 专注互联网 IT，行文'波澜诡谲、天马行空'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎭 这里不是普通的技术博客，这里是代码江湖的传奇！" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "⚡ 爽文风格：复杂冗长转简白易懂，让技术不再枯燥" -ForegroundColor Green
    Write-Host "🚀 全栈涉猎：Node.js、前端、后端、机器学习、AI、安卓逆向、exe 逆向……" -ForegroundColor Green
    Write-Host "💡 天马行空：用最有趣的方式解读最复杂的技术" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 特色内容：" -ForegroundColor Yellow
    Write-Host "  🛠️ 工具推荐 - 精选开发工具和效率神器" -ForegroundColor White
    Write-Host "  🔍 问题排查 - 常见技术问题的深度解析" -ForegroundColor White
    Write-Host "  📚 教程分享 - 从入门到精通的完整教程" -ForegroundColor White
    Write-Host "  💬 技术交流 - 与开发者互动，解答疑问" -ForegroundColor White
    Write-Host ""
    
    # 检查二维码文件是否存在
    $qrPath = Join-Path (Split-Path $PSScriptRoot) "qrcode.jpg"
    if (Test-Path $qrPath) {
        Write-Host "📱 微信公众号二维码：" -ForegroundColor Cyan
        Write-Host "   文件路径：$qrPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  📖 免费获取《Warp 使用完全指南》" -ForegroundColor White
        Write-Host "  🛠️ 独家工具推荐清单" -ForegroundColor White
        Write-Host "  💬 加入技术交流群" -ForegroundColor White
        Write-Host "  🎭 体验'波澜诡谲'的技术解读" -ForegroundColor White
        Write-Host ""
        
        # 尝试打开二维码图片
        try {
            Write-Host "正在打开二维码图片..." -ForegroundColor Green
            Start-Process $qrPath
            Write-Host "✓ 二维码图片已打开" -ForegroundColor Green
        } catch {
            Write-Host "⚠ 无法自动打开图片，请手动打开：$qrPath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ 二维码图片未找到：$qrPath" -ForegroundColor Red
        Write-Host "请确保 qrcode.jpg 文件位于项目根目录" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🚩 欢迎各位老爷莅临关注，体验'波澜诡谲、天马行空'的技术世界！🚩" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $userChoice = Show-PostExecutionMenu
    return $userChoice
}

# 简单显示ASCII艺术标题
function Show-AnimatedTitle {
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width

    # 定义ASCII艺术字符的各行内容
    $asciiLines = @(
        "  ██████╗  ███████╗  ███████╗  ██╗   ██╗     ████████╗  ████████╗  ",
        " ██╔════╝  ██╔════╝  ╚══███╔╝  ╚██╗ ██╔╝     ╚══██╔══╝  ╚══██╔══╝  ",
        " ██║       ███████╗    ███╔╝    ╚████╔╝         ██║        ██║     ",
        " ██║       ╚════██║   ███╔╝      ╚██╔╝          ██║        ██║     ",
        " ╚██████╗  ███████║  ███████╗     ██║           ██║        ██║     ",
        "  ╚═════╝  ╚══════╝  ╚══════╝     ╚═╝           ╚═╝        ╚═╝     "
    )

    Write-Host ""
    Write-Host ""

    # 直接显示标题，无动画效果
    $finalColors = @("White", "Green", "Green", "Green", "Green", "White")
    for ($i = 0; $i -lt $asciiLines.Length; $i++) {
        $line = $asciiLines[$i]
        $padding = [Math]::Max(0, ($consoleWidth - $line.Length) / 2)
        $centeredLine = (" " * $padding) + $line
        Write-Host $centeredLine -ForegroundColor $finalColors[$i]
    }
}

# 显示主菜单
function Show-Menu {
    # 显示标题
    Show-AnimatedTitle

    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $slogan = " >>>>  🎯 代码江湖，等你来战！⚡ 波澜诡谲，天马行空！ 逆向世界，无限可能！🎭  <<<< "

    Write-Host ""

    # 居中显示标语
    $sloganDisplayLength = 78
    $sloganPadding = [Math]::Max(0, ($consoleWidth - $sloganDisplayLength) / 2)
    $centeredSlogan = (" " * $sloganPadding) + $slogan
    Write-Host $centeredSlogan -ForegroundColor Green
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "========================================================================================================================" -ForegroundColor Cyan
    Write-Host "                                                   Warp 清理工具集                        " -ForegroundColor Cyan
    Write-Host "========================================================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "请选择要执行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Warp 深度清理 - ♻️ 全面扫描并移除所有标识符" -ForegroundColor Green
    Write-Host "  [2] Warp 智能清理 - 🌟 重置身份保留Rules、Mcp、Preference配置" -ForegroundColor Green
    Write-Host "  [3] 二次 UID 迁移 - ❤️ 登录新账号后执行" -ForegroundColor Green
    Write-Host "  [4] 恢复备份数据 - 从备份文件夹恢复清理前的数据" -ForegroundColor Magenta
    Write-Host "  [5] 关注公众号 - 🎉 获取更多技术技巧和工具推荐" -ForegroundColor Yellow
    Write-Host "  [0] 退出程序" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================================================================================================" -ForegroundColor Cyan
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
    
    Write-Host "请输入选项编号 (0-5)：" -ForegroundColor Yellow -NoNewline
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

        "5" {
            $result = Show-WeChatQR
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
            Write-Host "无效的选项！请输入 0-5 之间的数字。" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
} while ($choice -ne "0")

Write-Host ""
Write-Host "程序已退出。" -ForegroundColor Gray
