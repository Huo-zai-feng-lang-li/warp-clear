# 二次 UID 迁移 - 安全中文版本（无交互）
# 在登录新账号后执行，完成配置对象的所有权转移
# 确保所有配置正确关联到新登录的账号

# 安全编码设置，避免闪退
try {
    $Host.UI.RawUI.WindowTitle = "Warp UID Migration Tool"
    chcp 65001 | Out-Null
} catch {
    # 如果编码设置失败，继续执行
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         二次 UID 迁移 - 配置所有权转移 (自动版)    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "此脚本用于：" -ForegroundColor Yellow
Write-Host "  ✓ 在您登录新账号后执行" -ForegroundColor Green
Write-Host "  ✓ 将所有配置对象转移到新账号下" -ForegroundColor Green
Write-Host "  ✓ 确保MCP服务器正常工作" -ForegroundColor Green
Write-Host "  ✓ 保留所有Rules和偏好设置" -ForegroundColor Green
Write-Host ""

Write-Host "运行在自动模式 - 无需确认" -ForegroundColor Yellow
Write-Host ""

# 创建迁移日志
$MigrationLog = "$env:USERPROFILE\Desktop\UID_Migration_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorLog = "$env:USERPROFILE\Desktop\UID_Migration_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $MigrationLog -Append -Encoding UTF8
    Write-Host $Message -ForegroundColor $Color
}

Write-Log ""
Write-Log "开始二次UID迁移..." "Green"
Write-Log ""

# Step 1: 获取当前新用户的UID
Write-Log "1. 获取新账号信息..." "Yellow"

$sqlitePath = "$env:USERPROFILE\AppData\Local\warp\Warp\data\warp.sqlite"

if (-not (Test-Path $sqlitePath)) {
    Write-Log "   ! 数据库文件不存在" "Red"
    exit 1
}

# 获取当前登录的新用户UID
$newUserUID = sqlite3 $sqlitePath "SELECT firebase_uid FROM users WHERE is_current = 1 LIMIT 1;" 2>$null

if ([string]::IsNullOrEmpty($newUserUID)) {
    Write-Log "   ! 未找到当前登录用户，请确认已登录新账号" "Red"
    exit 1
}

Write-Log "   新账号UID: $newUserUID" "Cyan"

# 获取新用户邮箱
$userEmail = sqlite3 $sqlitePath "SELECT email FROM user_profiles WHERE firebase_uid = '$newUserUID' LIMIT 1;" 2>$null
if (-not [string]::IsNullOrEmpty($userEmail)) {
    Write-Log "   账号邮箱: $userEmail" "Cyan"
}

# Step 2: 分析需要迁移的对象
Write-Log "2. 分析需要迁移的配置对象..." "Yellow"

# 查找所有非当前用户创建的对象（这些是需要迁移的）
$orphanedObjects = sqlite3 $sqlitePath @"
SELECT 
    id,
    object_type,
    creator_uid,
    CASE 
        WHEN object_type = 'GENERIC_STRING_JSON_MCPSERVER' THEN 'MCP服务器'
        WHEN object_type = 'GENERIC_STRING_JSON_PREFERENCE' THEN '偏好设置'
        WHEN object_type = 'GENERIC_STRING_JSON_RULE' THEN 'Rules规则'
        ELSE object_type
    END as type_name
FROM object_metadata 
WHERE creator_uid != '$newUserUID'
    OR creator_uid IS NULL
    OR creator_uid = '';
"@ 2>$null

if ([string]::IsNullOrEmpty($orphanedObjects)) {
    Write-Log "   ✓ 所有配置已正确关联到当前账号" "Green"
    Write-Log ""
    Write-Log "迁移完成！无需额外操作。" "Green"
    exit 0
}

# 统计需要迁移的对象
$objectLines = $orphanedObjects -split "`n" | Where-Object { $_ -ne "" }
$totalObjects = $objectLines.Count

$mcpCount = ($objectLines | Where-Object { $_ -match "MCP服务器" }).Count
$prefCount = ($objectLines | Where-Object { $_ -match "偏好设置" }).Count
$ruleCount = ($objectLines | Where-Object { $_ -match "Rules规则" }).Count

Write-Log "   找到 $totalObjects 个需要迁移的对象:" "Yellow"
Write-Log "   - MCP服务器: $mcpCount 个" "Gray"
Write-Log "   - 偏好设置: $prefCount 个" "Gray"
Write-Log "   - Rules规则: $ruleCount 个" "Gray"

# Step 3: 备份当前数据
Write-Log "3. 备份数据库..." "Yellow"

$BackupPath = "$env:USERPROFILE\Desktop\warp-migrate-$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

Copy-Item $sqlitePath "$BackupPath\warp.sqlite.backup" -Force
Write-Log "   ✓ 数据库已备份到: $BackupPath" "Green"

# 导出当前配置详情
$configBackup = "$BackupPath\config_details.txt"
@"
二次UID迁移前配置备份
======================
日期: $(Get-Date)
新用户UID: $newUserUID
新用户邮箱: $userEmail

需要迁移的对象:
$orphanedObjects

MCP服务器配置:
$(sqlite3 $sqlitePath "SELECT id, json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER';")

偏好设置:
$(sqlite3 $sqlitePath "SELECT id, json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_PREFERENCE';")

Rules规则:
$(sqlite3 $sqlitePath "SELECT id, json_data FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_RULE';")
"@ | Out-File -FilePath $configBackup -Encoding UTF8

Write-Log "   ✓ 配置详情已备份" "Green"

# Step 4: 停止Warp进程
Write-Log "4. 停止Warp进程..." "Yellow"
Get-Process | Where-Object { $_.Name -like "*warp*" } | ForEach-Object {
    Write-Log "   停止进程: $($_.Name)" "Cyan"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Step 5: 执行UID迁移
Write-Log "5. 执行配置对象所有权转移..." "Yellow"

# 批量更新所有孤立对象的所有者
$updateQuery = @"
UPDATE object_metadata 
SET 
    creator_uid = '$newUserUID',
    last_editor_uid = '$newUserUID',
    current_editor = '$newUserUID',
    updated_at = datetime('now')
WHERE creator_uid != '$newUserUID'
    OR creator_uid IS NULL
    OR creator_uid = '';
"@

$updateResult = sqlite3 $sqlitePath $updateQuery 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Log "   ! 迁移失败: $updateResult" "Red"
    $updateResult | Out-File -FilePath $ErrorLog -Append -Encoding UTF8
    exit 1
}

# 验证迁移结果
$migratedCount = sqlite3 $sqlitePath "SELECT changes();" 2>$null
Write-Log "   ✓ 成功迁移 $migratedCount 个对象" "Green"

# Step 6: 清理可能的冲突数据
Write-Log "6. 清理冲突数据..." "Yellow"

# 清理重复的MCP服务器配置
$duplicateMCP = sqlite3 $sqlitePath @"
SELECT COUNT(*) 
FROM object_metadata 
WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER' 
GROUP BY json_data 
HAVING COUNT(*) > 1;
"@ 2>$null

if (-not [string]::IsNullOrEmpty($duplicateMCP) -and $duplicateMCP -ne "0") {
    Write-Log "   检测到重复的MCP配置，正在清理..." "Yellow"
    
    # 保留最新的，删除旧的
    sqlite3 $sqlitePath @"
DELETE FROM object_metadata 
WHERE id IN (
    SELECT id FROM (
        SELECT id, 
               ROW_NUMBER() OVER (PARTITION BY json_data ORDER BY updated_at DESC) as rn
        FROM object_metadata
        WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER'
    ) WHERE rn > 1
);
"@
    
    Write-Log "   ✓ 重复配置已清理" "Green"
}

# Step 7: 验证迁移结果
Write-Log "7. 验证迁移结果..." "Yellow"

# 检查所有对象是否都关联到新用户
$remainingOrphans = sqlite3 $sqlitePath @"
SELECT COUNT(*) 
FROM object_metadata 
WHERE (creator_uid != '$newUserUID' OR creator_uid IS NULL OR creator_uid = '')
    AND object_type IN ('GENERIC_STRING_JSON_MCPSERVER', 'GENERIC_STRING_JSON_PREFERENCE', 'GENERIC_STRING_JSON_RULE');
"@ 2>$null

if ($remainingOrphans -eq "0" -or [string]::IsNullOrEmpty($remainingOrphans)) {
    Write-Log "   ✓ 所有配置对象已成功关联到新账号" "Green"
} else {
    Write-Log "   ⚠ 仍有 $remainingOrphans 个对象未正确关联" "Yellow"
}

# 统计最终配置
$finalMcpCount = sqlite3 $sqlitePath "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_MCPSERVER' AND creator_uid = '$newUserUID';" 2>$null
$finalPrefCount = sqlite3 $sqlitePath "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_PREFERENCE' AND creator_uid = '$newUserUID';" 2>$null
$finalRuleCount = sqlite3 $sqlitePath "SELECT COUNT(*) FROM object_metadata WHERE object_type = 'GENERIC_STRING_JSON_RULE' AND creator_uid = '$newUserUID';" 2>$null

Write-Log ""
Write-Log "最终配置统计:" "Cyan"
Write-Log "   MCP服务器: $finalMcpCount 个" "Gray"
Write-Log "   偏好设置: $finalPrefCount 个" "Gray"
Write-Log "   Rules规则: $finalRuleCount 个" "Gray"

# Step 8: 清理缓存
Write-Log "8. 清理缓存数据..." "Yellow"

$cacheDir = "$env:USERPROFILE\AppData\Local\warp\Warp\cache"
if (Test-Path $cacheDir) {
    Get-ChildItem -Path $cacheDir -Filter "*.run" -Directory | ForEach-Object {
        $sessionFile = Join-Path $_.FullName "session.json"
        if (Test-Path $sessionFile) {
            Remove-Item $sessionFile -Force -ErrorAction SilentlyContinue
            Write-Log "   ✓ 清理会话: $(Split-Path $_.Name -Leaf)" "Gray"
        }
    }
}

# 生成迁移报告
$reportFile = "$BackupPath\MigrationReport.txt"
@"
二次UID迁移报告
================
执行时间: $(Get-Date)
新用户UID: $newUserUID
新用户邮箱: $userEmail

迁移前状态:
- 需要迁移的对象: $totalObjects 个
- MCP服务器: $mcpCount 个
- 偏好设置: $prefCount 个
- Rules规则: $ruleCount 个

迁移后状态:
- 成功迁移: $migratedCount 个对象
- MCP服务器: $finalMcpCount 个
- 偏好设置: $finalPrefCount 个
- Rules规则: $finalRuleCount 个

验证结果:
- 剩余孤立对象: $remainingOrphans 个

备份位置: $BackupPath
日志文件: $MigrationLog

如有问题，可使用备份文件恢复:
$BackupPath\warp.sqlite.backup
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Log ""
Write-Log "====================================================" "Green"
Write-Log "              二次UID迁移完成！                    " "Green"
Write-Log "====================================================" "Green"
Write-Log ""

Write-Log "迁移报告: $reportFile" "Cyan"
Write-Log "备份位置: $BackupPath" "Cyan"
Write-Log ""

Write-Log "现在可以启动Warp，所有配置应该正常工作！" "Green"
Write-Log ""

Write-Log "提示：如果MCP服务器显示未连接，请尝试：" "Yellow"
Write-Log "  1. 重启Warp" "Gray"
Write-Log "  2. 在MCP设置中点击重新连接" "Gray"
Write-Log "  3. 检查MCP服务器进程是否正常运行" "Gray"
Write-Log ""

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                    UID 迁移完成                    " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "备份已保存到：$BackupPath" -ForegroundColor Cyan
Write-Host "如需恢复数据，请使用主菜单的恢复功能。" -ForegroundColor Yellow
