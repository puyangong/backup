# Backup Skill

## Trigger

当用户说出以下提示词时自动触发：

- 备份
- 保存
- 提交
- 克隆
- 记录

## Execution Flow

### Step 1: Detect Operating System

获取用户的操作系统类型和位数：

- **Windows**: 执行 `[System.Environment]::OSVersion.Platform` 或 `$env:OS`
- **Linux/macOS**: 执行 `uname -s` 和 `uname -m`

### Step 2: Execute Backup Script

根据操作系统类型执行对应的备份脚本：

#### Windows (任意位数)

```powershell
# 执行 PowerShell 备份脚本 (使用相对于当前工作目录的路径)
& (Join-Path $PSScriptRoot "tools\backup.ps1")

# 或直接执行
powershell -File "$PSScriptRoot\tools\backup.ps1"
```

#### Linux / macOS

```bash
# 执行 Shell 备份脚本 (使用相对于脚本所在目录的路径)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/tools/backup.sh"

# 或直接执行
bash "$(dirname "$0")/tools/backup.sh"
```

### Step 3: Output Result

脚本执行后显示：

- 备份文件名
- 备份目录位置 (`.backup/`)
- 当前保留的备份列表

## Script Locations

| Script     | 相对路径           |
| ---------- | ------------------ |
| PowerShell | `tools/backup.ps1` |
| Shell      | `tools/backup.sh`  |

> 路径相对于本 SKILL.md 所在目录 (`skills/backup/`)

## Notes

- 备份自动排除 `.backup` 目录本身
- 保留最近 10 个备份 (1-10)
- 每次备份自动轮转：10→11, 9→10, ..., 1→2
- 备份文件名格式: `{序号}-{时间戳}.zip`
