# Warp 清理工具集

这是一个用于清理和重置 Cloudflare Warp 客户端的工具集合。包含多个 PowerShell 脚
本，用于解决 Warp 客户端的各种问题。

## ✅ 快速开始

**双击运行**：`start.bat`

然后在菜单中输入对应编号：

- **1** - Warp 深度清理
- **2** - Warp 完全重置
- **3** - 二次 UID 迁移
- **4** - 恢复备份数据
- **0** - 退出程序

## 📁 项目结构

```
clear-warp/
├── start.bat          # 一键启动入口
├── tools/               # 工具文件夹
│   └── 启动.ps1         # 主菜单脚本
├── scripts/             # 清理脚本文件夹
│   ├── Deep-Clean-Warp-Auto-CN-Safe.ps1      # 深度清理
│   ├── Reset-Warp-Fixed-Auto-CN-Safe.ps1     # 完全重置
│   └── Secondary-UID-Migration-Auto-CN-Safe.ps1  # UID迁移
└── docs/                # 文档文件夹
    └── README.md        # 使用说明
```

## 🔔 功能说明

### 1. Warp 深度清理

- 全面扫描系统中的 Warp 相关文件、注册表项和配置
- 彻底清除所有痕迹，模拟"系统从未安装过 Warp"
- 备份格式：`warp-deep-YYYY-MM-DD`

### 2. Warp 智能清理

- 重置设备身份但保留重要配置（MCP、Rules、偏好设置）
- 清除用户登录状态和设备标识，生成新的设备 ID
- 智能备份和恢复，避免重新配置的繁琐
- 备份格式：`warp-intelligent-YYYY-MM-DD`

### 3. 二次 UID 迁移

- 在用户登录新账号后执行
- 确保所有配置正确关联到新登录的账号
- 完成配置对象的所有权转移

### 4. 恢复备份数据

- 自动检测桌面上的备份文件夹
- 支持选择不同的备份进行恢复
- 安全恢复文件和注册表配置

## 📋 备份文件夹格式

新的备份文件夹命名格式：

- 深度清理：`warp-deep-2025-09-10`
- 智能清理：`warp-intelligent-2025-09-10`
- UID 迁移：`warp-migrate-2025-09-10`

## ⚠️ 注意事项

1. **管理员权限**：建议以管理员身份运行以获得最佳效果
2. **关闭 Warp**：运行脚本前请先关闭 Warp 客户端
3. **备份重要数据**：运行前请确认重要配置已备份
4. **恢复功能**：现在可以通过主菜单的恢复功能轻松恢复数据

## ♻️ 恢复数据

如果需要恢复清理前的数据：

1. 运行 `start.bat`
2. 选择 `4` - 恢复备份数据
3. 从列表中选择要恢复的备份
4. 输入 `y` 确认恢复
5. 等待恢复完成
6. 选择后续操作：
   - 按 **Enter** 返回主菜单
   - 按 **Esc** 关闭程序
7. 重启 Warp 应用程序

## 🛠️ 系统要求

- Windows 10/11
- PowerShell 5.1 或更高版本
- 管理员权限（推荐）

### ✅ 环境检查

运行 `check-environment.ps1` 可以检查系统兼容性：

```powershell
powershell.exe -ExecutionPolicy Bypass -File "check-environment.ps1"
```

该脚本会检查：

- PowerShell 版本
- 操作系统兼容性
- 管理员权限
- 执行策略
- Warp 客户端安装状态
- 工具文件完整性

## 📞 故障排除

如果遇到执行策略问题：

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

## 📄 许可证

本项目采用 MIT 许可证。

---

## 🎉 技术公众号/解锁更好更多技巧

<div align="center">

### 🌟 欢迎关注！🚩

[![微信公众号](https://img.shields.io/badge/微信公众号-互联网IT技术分享-blue?style=for-the-badge&logo=wechat)](https://mp.weixin.qq.com)
[![关注人数](https://img.shields.io/badge/关注人数-1000+-green?style=for-the-badge)](https://mp.weixin.qq.com)
[![更新频率](https://img.shields.io/badge/更新频率-每周-orange?style=for-the-badge)](https://mp.weixin.qq.com)

</div>

### 🔍 专注互联网 IT，行文"波澜诡谲、天马行空"

**🎭 这里不是普通的技术博客，这里是代码江湖的传奇！**

- **⚡ 爽文风格**：复杂冗长转简白易懂，让技术不再枯燥
- **🚀 全栈涉猎**：Node.js、前端、后端、机器学习、AI、安卓逆向、exe 逆向……
- **💡 天马行空**：用最有趣的方式解读最复杂的技术

### 🎨 特色内容矩阵

| 内容类型        | 描述                   | 更新频率 | 风格特色 |
| --------------- | ---------------------- | -------- | -------- |
| 🛠️ **工具推荐** | 精选开发工具和效率神器 | 每周     | 爽文解析 |
| 🔍 **问题排查** | 常见技术问题的深度解析 | 按需     | 天马行空 |
| 📚 **教程分享** | 从入门到精通的完整教程 | 每月     | 波澜诡谲 |
| 💬 **技术交流** | 与开发者互动，解答疑问 | 实时     | 简白易懂 |

### 📢 立即关注

**🎯 扫描二维码，加入代码江湖的传奇之旅！**

![微信公众号二维码](qrcode.jpg)

### 🌈 加入我们的技术江湖

### 🎯 江湖传说 - 热门文章推荐

<div align="center">

**🔥 武林秘籍，江湖传说 🔥**

```
┌─────────────────────────────────────────────────────────┐
│  📚 《Warp 客户端完全清理指南》- 代码江湖的终极秘籍      │
│  🛠️ 《PowerShell 脚本开发最佳实践》- 内功心法大全      │
│  🔍 《Windows 系统优化技巧大全》- 系统调优的武林绝学   │
│  💡 《开发工具效率提升秘籍》- 效率修炼的独门心法       │
│  🎭 《波澜诡谲的技术解读》- 天马行空的代码哲学         │
└─────────────────────────────────────────────────────────┘
```

**⚡ 每一篇文章都是江湖传奇，每一个技巧都是武林绝学！**

</div>

---

<div align="center">

**🎊 感谢各位老爷的支持，让我们一起在代码江湖中创造传奇！🎊**

[![Star History Chart](https://api.star-history.com/svg?repos=Huo-zai-feng-lang-li/clear-warp&type=Date)](https://star-history.com/#Huo-zai-feng-lang-li/clear-warp&Date)

**⭐ 如果这个工具对你有帮助，请给我们一个 Star，让江湖传说继续流传！⭐**

**🚩 欢迎各位老爷莅临关注，体验"波澜诡谲、天马行空"的技术世界！🚩**

</div>

---
