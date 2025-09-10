## 1) Reset-Warp-Fixed.ps1 — 标准重置（本地“新设备/新用户”）

•  适用场景
•  需要让 Warp 在下次启动时认为当前机器与用户都是全新状态
•  常规重置用户身份、本地数据库和缓存
•  权限与交互
•  建议以管理员身份运行 PowerShell
•  执行时会提示确认：输入 RESET 才会继续
•  主要操作步骤
•  停止 Warp 相关进程，避免文件被占用
•  备份本地数据与注册表到桌面：WarpCompleteBackup_YYYYMMDD_HHmmss
•  删除本地数据目录：%LOCALAPPDATA%\warp\Warp（cache、data 等）
•  删除注册表键：HKCU:\Software\Warp.dev（用户级配置、实验标识等）
•  清理临时文件：%TEMP%、%LOCALAPPDATA%\Temp 中与 warp 匹配的项
•  初始化全新环境：重建 cache、data、logs、logs\mcp 等目录
•  生成新的设备标识符 UUID：在 %LOCALAPPDATA%\warp\Warp\cache{UUID}.run 下创建目录与 .lock 文件
•  显示只读硬件指纹信息（不可更改）：Machine GUID、System UUID
•  输出总结（清理项、备份路径、新设备标识）
•  提供恢复提示（如何用备份恢复文件与注册表）
•  触达的关键路径/对象
•  文件系统：%LOCALAPPDATA%\warp\Warp\… 及临时目录
•  注册表：HKCU:\Software\Warp.dev
•  设备 UUID 目录：%LOCALAPPDATA%\warp\Warp\cache{UUID}.run
•  产出与副作用
•  产出：桌面备份目录、全新的本地 Warp 目录结构和 UUID
•  副作用：清空本地会话、数据库与缓存；下次启动需重新登录
•  运行命令
•  pwsh -ExecutionPolicy Bypass -File scripts\Reset-Warp-Fixed.ps1

## 2) Deep-Clean-Warp.ps1 — 深度清理（最大范围的“彻底卸载”式清理）

•  适用场景
•  需要尽可能移除本机与 Warp 相关的所有痕迹（文件、缓存、注册表）
•  标准重置不足以解决问题，或要模拟“系统从未安装过 Warp”
•  权限与交互
•  建议管理员身份运行
•  扫描后会汇总发现内容，再提示确认：输入 DEEPCLEAN 才会执行清理
•  主要操作步骤
•  扫描与列出所有可能的 Warp 位置：
◦  文件系统：%LOCALAPPDATA%\warp\Warp、%APPDATA%\warp、安装目录（Program Files/Programs）、用户主目录 .warp/.config\warp、%TEMP%、%LOCALAPPDATA%\Temp
◦  Electron/Chromium 缓存：User Data、Local Storage、IndexedDB、Service Worker、Session Storage、blob_storage
•  扫描注册表：
◦  HKCU:\Software\Warp.dev、HKLM:\SOFTWARE\Warp.dev、相关 Classes 注册（协议/卸载项）
•  显示系统只读标识（Machine GUID、System UUID、MAC）供知悉
•  备份所有将清理的文件与注册表到桌面：WarpDeepCleanBackup_YYYYMMDD_HHmmss
•  停止 Warp 进程
•  删除扫描到的文件位置
•  导出并删除扫描到的注册表项（HKCU/HKLM 范围）
•  额外清理：
◦  刷新 DNS 缓存（ipconfig /flushdns）
◦  清理 IE/Edge 传统临时互联网文件
◦  如存在，删除 Windows 预取（Prefetch）中与 WARP 匹配的条目
•  写入总结文件 CleanupSummary.txt（包含备份路径、已清理项清单与系统标识）
•  触达的关键路径/对象
•  文件系统：用户数据、漫游数据、安装目录、Electron/Chromium 缓存、临时目录
•  注册表：HKCU/HKLM 下 Warp 相关键与关联项（含协议、卸载信息）
•  产出与副作用
•  产出：桌面备份目录与 CleanupSummary.txt
•  副作用：更彻底的“本机无 Warp 痕迹”状态；之后如需再用 Warp，建议全新安装与登录
•  运行命令
•  pwsh -ExecutionPolicy Bypass -File scripts\Deep-Clean-Warp.ps1

### 3) Secondary-UID-Migration.ps1 — 二次 UID 迁移（账号切换后的配置所有权转移）

•  适用场景
•  已经在 Warp 内登录新账号，但本地配置（如 MCP 服务器、偏好、Rules）仍归属于旧 UID，导致配置不被新账号“认领”
•  希望保留配置内容，只把“所有者”换成当前账号
•  依赖与交互
•  需要系统已安装 sqlite3 并在 PATH 中可用
•  要求 Warp 已成功登录新账号，并且处于可读取数据库的状态
•  脚本开始会提示确认是否已登录新账号（y/N）
•  主要操作步骤
•  记录日志到桌面：UID_Migration_YYYYMMDD_HHmmss.log 和错误日志
•  定位数据库：%LOCALAPPDATA%\warp\Warp\data\warp.sqlite
•  查询当前登录用户 UID：从 users 表读取 is_current = 1 的 firebase_uid
•  可选读取当前用户邮箱：user_profiles 表
•  识别“待迁移对象”：object_metadata 中 creator_uid 为空/不同于当前 UID 的条目
◦  主要对象类型：GENERIC_STRING_JSON_MCPSERVER（MCP 服务器）、GENERIC_STRING_JSON_PREFERENCE（偏好）、GENERIC_STRING_JSON_RULE（规则）
•  备份数据库到桌面：UID_Migration_Backup_YYYYMMDD_HHmmss\warp.sqlite.backup
•  导出当前配置详情到 config_details.txt（含对象清单与各类型配置快照）
•  停止 Warp 进程，避免数据库被锁
•  执行迁移：将上述对象的 creator_uid、last_editor_uid、current_editor 更新为新 UID，并更新 updated_at
•  统计迁移影响（SELECT changes()）
•  去重（可选）：对 MCP 配置按 json_data 分组保留最新一条，删除重复
•  验证：统计仍未正确关联的对象数量，以及新 UID 名下各类对象数量
•  清理 cache 下 *.run 会话中的 session.json（若存在）
•  生成迁移报告 MigrationReport.txt（包含迁移前后统计与备份位置）
•  可选提示启动 Warp
•  触达的关键路径/对象
•  数据库：%LOCALAPPDATA%\warp\Warp\data\warp.sqlite（表：users、user_profiles、object_metadata）
•  文件系统：%LOCALAPPDATA%\warp\Warp\cache 中的会话文件
•  产出与副作用
•  产出：桌面备份目录、日志与迁移报告；将本地配置“归属权”切换到当前登录账号
•  副作用：如存在异常，脚本会写入错误日志；若未来 Warp 数据库结构变化，需调整 SQL
•  运行命令
•  pwsh -ExecutionPolicy Bypass -File scripts\Secondary-UID-Migration.ps1

补充建议
•  使用顺序建议
•  一般问题：先尝试 Reset-Warp-Fixed.ps1（影响面较小、易恢复）
•  若需要“干净地重来”：使用 Deep-Clean-Warp.ps1（最彻底）
•  账号切换后配置不跟随：使用 Secondary-UID-Migration.ps1（迁移所有权）
•  自动化/无交互运行
