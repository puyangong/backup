# 备份技能（Backup Skill）

基于 7-Zip 的跨平台自动轮转备份工具。

## 概述

本项目是一个 **Snow AI CLI 技能**，可为任意目录提供自动化备份功能。它会对当前工作目录创建带时间戳的 ZIP 压缩包，自动轮转备份以保留最近的 10 个副本，并在归档时排除备份目录本身。

该技能通过自然语言关键词触发，例如 "备份"、"保存"、"提交"、"克隆" 和 "记录"。它会检测宿主操作系统及架构，然后使用内置或系统已安装的 7-Zip 二进制文件执行相应的备份脚本。

## 技术栈

- **语言/运行时**：PowerShell 5+（Windows）、Bash（Linux / macOS）
- **压缩引擎**：7-Zip 26.00（所有平台均附带二进制文件）
- **支持平台**：Windows（x64）、Linux（x64 / ARM64）、macOS（通用）
- **配置**：JSON（Snow AI CLI 设置与权限）

## 项目结构

```
.
├── .snow/                          # Snow AI CLI 元数据与配置
│   ├── hooks/                      # 钩子脚本目录（空）
│   ├── notebook/                   # 笔记本存储目录（空）
│   ├── permissions.json            # 自动批准的工具：filesystem-read、terminal-execute
│   └── settings.json               # Snow AI CLI 设置（yoloMode、planMode 等）
├── tools/                          # 备份脚本与 7-Zip 二进制文件
│   ├── 7z-win-64/                  # Windows x64 7-Zip 二进制文件（7z.exe、7z.dll）
│   ├── 7z2600-linux-arm64/         # Linux ARM64 7-Zip 二进制文件（7zz、7zzs、手册）
│   ├── 7z2600-linux-x64/           # Linux x64 7-Zip 二进制文件（7zz、7zzs、手册）
│   ├── 7z2600-mac/                 # macOS 7-Zip 二进制文件（7zz、手册）
│   ├── backup.ps1                  # PowerShell 备份脚本（Windows）
│   └── backup.sh                   # Bash 备份脚本（Linux / macOS）
├── AGENTS.md                       # 本文档 —— 项目说明（英文原版）
├── AGENTS.zh.md                    # 本文档 —— 项目说明（中文版）
└── SKILL.md                        # 技能定义与触发关键词（中文）
```

## 核心功能

- **跨平台**：Windows（PowerShell）与 Unix（Bash）原生脚本
- **自包含**：附带 Windows、Linux（x64/ARM64）和 macOS 的 7-Zip 26.00 二进制文件
- **自动下载回退**：若未找到本地二进制文件，自动从官网下载 7-Zip
- **备份轮转**：保留最近的 10 个备份；旧备份自动删除
- **带时间戳的归档**：备份文件名格式为 `{序号}-{时间戳}.zip`（例如 `1-2026-05-14-08-00-00.zip`）
- **智能排除**：自动排除 `.backup/` 目录，避免递归归档
- **保留空目录**：归档时包含空文件夹

## 快速开始

### 前置要求

- Windows 10/11 并安装 PowerShell 5+，**或**
- 安装 Bash 的 Linux 发行版，**或**
- 安装 Bash 的 macOS
- 网络连接（仅在首次运行且未预装 7-Zip 时需要）

### 安装

无需安装。只需将该目录放到系统任意位置即可。

```bash
# 克隆或复制技能目录
cd /path/to/backup
```

### 使用方式

#### 手动执行

**Windows：**
```powershell
# 从当前工作目录执行
& .\tools\backup.ps1
```

**Linux / macOS：**
```bash
# 从当前工作目录执行
bash ./tools/backup.sh
```

#### Snow AI CLI 技能调用

使用 Snow AI CLI 时，说出任意触发词即可：
- 备份
- 保存
- 提交
- 克隆
- 记录

CLI 将自动检测操作系统并运行相应脚本。

## 开发

### 可用脚本

| 脚本 | 路径 | 平台 | 说明 |
|------|------|------|------|
| `backup.ps1` | `tools/backup.ps1` | Windows | 基于 7-Zip 的 PowerShell 备份 |
| `backup.sh` | `tools/backup.sh` | Linux / macOS | 基于 7-Zip 的 Bash 备份 |

### 开发流程

1. **修改脚本**：根据需要编辑 `tools/backup.ps1` 或 `tools/backup.sh`。
2. **本地测试**：在测试目录中运行脚本，并检查 `.backup/` 的内容。
3. **更新 SKILL.md**：如果触发词或行为发生变化，请同步更新 `SKILL.md`。

## 配置

### Snow AI CLI 设置（`.snow/settings.json`）

| 键 | 值 | 说明 |
|-----|-------|-------------|
| `yoloMode` | `true` | 自动批准安全操作 |
| `planMode` | `false` | 规划模式已关闭 |
| `vulnerabilityHuntingMode` | `false` | 安全扫描已关闭 |
| `toolSearchEnabled` | `false` | 外部工具搜索已关闭 |
| `hybridCompressEnabled` | `false` | 混合压缩已关闭 |
| `teamMode` | `false` | 团队协作已关闭 |

### Snow AI CLI 权限（`.snow/permissions.json`）

| 工具 | 状态 |
|------|--------|
| `filesystem-read` | 始终批准 |
| `terminal-execute` | 始终批准 |

## 架构

```
用户输入（触发词）
        │
        ▼
┌─────────────────┐
│  Snow AI CLI    │
│  技能路由器     │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
 Windows   Linux/macOS
    │         │
    ▼         ▼
backup.ps1  backup.sh
    │         │
    └────┬────┘
         ▼
┌─────────────────┐
│  操作系统检测   │
│  与架构检查     │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
 本地 7z    下载
    │         │
    └────┬────┘
         ▼
┌─────────────────┐
│  备份轮转       │
│  (1→2, 2→3...)  │
└────────┬────────┘
         ▼
┌─────────────────┐
│  创建 ZIP       │
│  (排除 .backup) │
└────────┬────────┘
         ▼
    .backup/1-{时间戳}.zip
```

### 备份轮转逻辑

1. 现有备份依次后移：`1-*` → `2-*`、`2-*` → `3-*`、...、`10-*` → `11-*`
2. 删除 `11-*`（最旧的备份）
3. 创建新的备份 `1-{时间戳}.zip`
4. 始终保持最多 10 个备份

## 贡献指南

这是一个 Snow AI CLI 技能模块。如需贡献：

1. Fork 或复制本仓库
2. 修改脚本或文档
3. 在所有目标平台（Windows、Linux、macOS）上测试
4. 如果行为发生变化，请更新 `SKILL.md` 和 `AGENTS.md`

## 许可证

**备份脚本**（`backup.ps1`、`backup.sh`）和 **技能元数据** 按原样提供，仅供在 Snow AI CLI 生态系统中使用。

附带的 **7-Zip 二进制文件** 基于 **GNU LGPL** 许可证（特定组件还包含额外的 BSD 2-clause、BSD 3-clause 和 unRAR 许可证限制）。完整许可证详情见 `tools/7z2600-*/License.txt`。

> 7-Zip 版权所有 (C) 1999–2026 Igor Pavlov。
