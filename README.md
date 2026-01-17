# 🔄 Claude Cross-Machine Sync

> **Your AI memory, everywhere.** Synchronize Claude Code settings, conversation history, and AI-generated intelligence across all your machines.

[![Machines](https://img.shields.io/badge/machines-3-blue)]()
[![AI Queries](https://img.shields.io/badge/AI%20queries-1,708-green)]()
[![Conversations](https://img.shields.io/badge/conversations-49-orange)]()
[![Size](https://img.shields.io/badge/size-308MB-lightgrey)]()

---

## 📋 Overview

This repository aggregates and syncs **all AI-generated intelligence** from multiple tools across multiple machines:

| Source | Content | Records |
|--------|---------|---------|
| **Claude Code** | Episodic memory, settings, skills | 128MB archive |
| **Warp Terminal** | AI queries + agent conversations | 570 + 13 |
| **Warp Preview** | AI queries + agent conversations | 1,138 + 36 |
| **Antigravity/Gemini** | Task plans, implementations, walkthroughs | 15 sessions |
| **Custom Skills** | Tool discovery, Beeper chat, Omarchy | 4 skills |
| **Learnings** | Bash patterns, Beeper, Electron/Wayland | 3 files |

---

## 🖥️ Machines

| Machine | OS | Status | Hostname |
|---------|-----|--------|----------|
| **MacBook Air** (Main) | Arch Linux | ✅ Configured | `macbook-air` |
| **Linux Notebook 2** | Linux | 📋 Pending | - |
| **Windows Desktop** | Windows 11 | 📋 Pending | - |

---

## 🚀 Quick Start

### New Machine Setup

<details>
<summary><b>🐧 Linux / macOS</b></summary>

```bash
# 1. Install Git LFS (for large files)
# Arch: sudo pacman -S git-lfs
# Ubuntu: sudo apt install git-lfs
# macOS: brew install git-lfs
git lfs install

# 2. Clone the repository
cd ~
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git

# 3. Copy settings to Claude Code
cp ~/claude-cross-machine-sync/.claude/settings.json ~/.claude/
cp -r ~/claude-cross-machine-sync/skills/* ~/.claude/skills/

# 4. Install plugins
claude /plugin marketplace add obra/superpowers-marketplace
claude /plugin install episodic-memory@superpowers-marketplace
claude /plugin install superpowers@superpowers-marketplace
```

</details>

<details>
<summary><b>🪟 Windows</b></summary>

```powershell
# 1. Install Git LFS
winget install GitHub.GitLFS
git lfs install

# 2. Clone the repository
cd ~
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git

# 3. Copy settings to Claude Code
Copy-Item ".\claude-cross-machine-sync\.claude\settings.json" "$env:USERPROFILE\.claude\" -Force
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills" -Force
Copy-Item -Recurse ".\claude-cross-machine-sync\skills\*" "$env:USERPROFILE\.claude\skills\" -Force

# 4. Install plugins (run inside Claude Code)
# /plugin marketplace add obra/superpowers-marketplace
# /plugin install episodic-memory@superpowers-marketplace
```

See **[docs/WINDOWS-SETUP.md](docs/WINDOWS-SETUP.md)** for detailed instructions.

</details>

---

## 📁 Repository Structure

```
claude-cross-machine-sync/
│
├── 📄 CLAUDE.md                    # Project memory (auto-loaded by Claude)
├── 📄 README.md                    # This file
│
├── 📂 .claude/                     # Claude Code configuration
│   ├── settings.json               # Shared permissions & tool config
│   └── machine-info.json           # Machine identification
│
├── 📂 skills/                      # Custom Claude Code skills
│   ├── tool-discovery/             # Auto-discover available tools
│   ├── beeper-chat/                # Beeper messaging integration
│   └── omarchy-skill.md            # Linux desktop configuration
│
├── 📂 episodic-memory/             # 🔒 Git LFS (128MB)
│   ├── -home-rob/                  # Conversation JSONL archives
│   ├── conversation-index/         # Search index database
│   └── learnings/                  # AI-extracted learnings
│
├── 📂 warp-ai/                     # Warp Terminal AI history
│   ├── queries/                    # 570 AI queries (CSV)
│   ├── agents/                     # 13 agent conversations (JSON)
│   ├── preview-queries/            # 1,138 queries from Warp Preview
│   ├── preview-agents/             # 36 agent conversations
│   └── INDEX.md                    # Data format documentation
│
├── 📂 antigravity-history/         # Google Antigravity IDE recovery
│   ├── gemini-brain/               # 15 AI task sessions
│   │   └── <session-id>/
│   │       ├── task.md             # Task definition
│   │       ├── implementation_plan.md
│   │       └── walkthrough.md      # Step-by-step guidance
│   └── INDEX.md                    # Session index
│
├── 📂 learnings/                   # AI-generated knowledge
│   ├── bash-patterns.md            # Shell scripting patterns
│   ├── beeper.md                   # Beeper messaging insights
│   └── electron-wayland.md         # Electron on Wayland fixes
│
└── 📂 docs/                        # Documentation
    ├── WINDOWS-SETUP.md            # Windows installation guide
    ├── ssh-setup.md                # SSH remote access
    ├── guides/                     # Hardware/software guides
    ├── system/                     # System reports & optimization
    ├── beeper/                     # Beeper integration docs
    ├── plans/                      # Development plans
    └── obra-superpowers/           # Superpowers plugin docs
```

---

## 🔍 Finding Past Solutions

### Episodic Memory Search

Just ask Claude naturally:

```
"What was the solution to the Chrome settings error?"
"How did I configure permissions on Linux?"
"What commands did I use to fix the audio?"
```

Or use the direct command:

```
/episodic-memory:search-conversations "keyword"
```

### Searching Warp AI History

The extracted CSV files are grep-able:

```bash
# Find queries about Docker
grep -i docker warp-ai/queries/all-queries.csv

# Search agent conversations
grep -i "kubernetes" warp-ai/agents/all-conversations.json
```

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [CLAUDE.md](./CLAUDE.md) | Full project memory, solutions, machine configs |
| [WINDOWS-SETUP.md](docs/WINDOWS-SETUP.md) | Complete Windows installation guide |
| [ssh-setup.md](docs/ssh-setup.md) | SSH remote access configuration |
| [warp-ai/INDEX.md](warp-ai/INDEX.md) | Warp AI data format & usage |
| [antigravity-history/INDEX.md](antigravity-history/INDEX.md) | Gemini brain session index |

### Hardware & System Guides

| Guide | Topic |
|-------|-------|
| [AUDIO_SETUP.md](docs/guides/AUDIO_SETUP.md) | Audio configuration |
| [KEYBOARD_BACKLIGHT_GUIDE.md](docs/guides/KEYBOARD_BACKLIGHT_GUIDE.md) | Keyboard backlight control |
| [SENSOR_GUIDE.md](docs/guides/SENSOR_GUIDE.md) | Hardware sensor setup |
| [OPTIMIZATION_REPORT.md](docs/system/OPTIMIZATION_REPORT.md) | System optimization |

---

## 🛠️ Skills

Custom skills enhance Claude Code's capabilities:

| Skill | Trigger | Purpose |
|-------|---------|---------|
| **tool-discovery** | "what tools are available?" | Lists MCP servers, searches for new tools |
| **beeper-chat** | Beeper-related requests | Chat search and messaging |
| **omarchy** | Desktop/WM config changes | Hyprland, Waybar, terminal config |

---

## 🔄 Daily Workflow

```bash
# Morning: Pull latest changes
cd ~/claude-cross-machine-sync && git pull

# Work normally - Claude loads settings automatically

# After solving problems: Push updates
cd ~/claude-cross-machine-sync
git add .
git commit -m "Added: <description>"
git push
```

---

## ⚙️ Technical Details

### Git LFS

Large files (episodic memory) are tracked with Git LFS:

```bash
# Files tracked
*.jsonl filter=lfs diff=lfs merge=lfs -text

# Check LFS status
git lfs ls-files
```

### Data Sources

| Source | Location | Format |
|--------|----------|--------|
| Warp Terminal | `~/.local/state/warp-terminal/warp.sqlite` | SQLite |
| Warp Preview | `~/.local/state/warp-terminal-preview/warp.sqlite` | SQLite |
| Antigravity | `~/.gemini/antigravity/brain/` | Markdown |
| Episodic Memory | `~/.config/superpowers/conversation-archive/` | JSONL |

---

## 📈 Stats

- **Total Size**: ~308MB
- **Files**: 599+
- **AI Queries**: 1,708
- **Agent Conversations**: 49
- **Gemini Sessions**: 15
- **Custom Skills**: 4
- **Documentation Files**: 25+

---

## 🔗 Related

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Superpowers Plugin](https://github.com/obra/superpowers)
- [Episodic Memory Plugin](https://github.com/anthropics/claude-code-plugins)

---

## 📝 License

Personal use. This repository contains personal AI conversation history and machine configurations.

---

<div align="center">

**Sync your AI intelligence across all machines** 🧠

*Last updated: 2026-01-17*

</div>
