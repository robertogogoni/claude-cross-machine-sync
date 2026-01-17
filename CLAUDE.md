# Claude Code Cross-Machine Setup

**Last Updated**: 2026-01-17
**Machines**: MacBook Air (Main), Linux Notebook 2, Windows Desktop
**Repository**: https://github.com/robertogogoni/claude-cross-machine-sync

## Machine Identification

This repository syncs configuration across:
- **MacBook Air** (Main) - Apple MacBookAir7,2 running Arch Linux (hostname: macbook-air)
- **Linux Notebook 2** - To be configured
- **Windows Desktop** - To be configured

See `.claude/machine-info.json` for detailed system configuration.

## Purpose

This repository is a **comprehensive AI intelligence hub** that:
1. Synchronizes Claude Code settings, memory, and skills across machines
2. Aggregates AI conversation history from multiple tools (Claude, Warp, Gemini)
3. Preserves learnings and patterns discovered during development
4. Provides searchable access to past solutions via episodic memory

## Quick Links

- **Episodic Memory**: `/episodic-memory:search-conversations "keyword"`
- **Settings**: `.claude/settings.json` (shared), `~/.claude/settings.json` (per-machine)
- **Skills**: `skills/` directory - custom Claude Code capabilities
- **Warp AI History**: `warp-ai/` - 1,708 queries, 49 agent conversations
- **Gemini Sessions**: `antigravity-history/gemini-brain/` - 15 task sessions

---

## Recent Solutions & Fixes

### 2026-01-17: "Jarvis Mode" - Full Autonomy Permission Setup

**Session Goal**: Eliminate permission prompts for a fully autonomous Claude Code experience
**Machine**: Windows Desktop

**Problem**: Claude Code prompts for permission on every file edit, bash command, etc. Too much friction for power users.

**Solutions Explored**:

| Approach | Command/Config | Safety Level | Platform |
|----------|----------------|--------------|----------|
| CLI Flag | `claude --dangerously-skip-permissions` | ⚠️ Full access | 🔄 All |
| Docker Container | `claude-code-container` | ✅ Sandboxed | 🔄 All |
| Settings Permissions | Broad `"Bash"` in settings.json | ⚠️ Medium | 🔄 All |
| Wildcard Permissions | `Bash(npm *)`, `Bash(git *)` (v2.1.0+) | ⚠️ Scoped | 🔄 All |
| PowerShell Alias | `jarvis` function + `j` alias | N/A | 🪟 Windows |
| Bash/Zsh Alias | `alias jarvis=...` | N/A | 🐧 Linux/macOS |

**Platform Legend**: 🪟 Windows | 🐧 Linux/macOS | 🔄 Cross-platform

**Chosen Solution (Windows)**: CLI flag with PowerShell alias

**Implementation** 🪟:
```powershell
# Added to both PowerShell profiles:
# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
# ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1

function jarvis { claude --dangerously-skip-permissions @args }
Set-Alias -Name j -Value jarvis
```

**Equivalent for Linux/macOS** 🐧:
```bash
# Add to ~/.bashrc or ~/.zshrc
alias jarvis='claude --dangerously-skip-permissions'
alias j='jarvis'
```

**Usage** 🔄:
```bash
jarvis              # Launch with full autonomy
j                   # Short alias
j --resume          # Resume with autonomy (args pass through)
```

**Key Learnings**:
- 🪟 `@args` in PowerShell is "splatting" - passes all arguments through to the underlying command
- 🐧 Bash aliases are simpler: just string substitution
- 🔄 `--dangerously-skip-permissions` is officially nicknamed "yolo mode"
- 🔄 Docker containers (claude-code-container, run-claude-docker) provide safe sandboxed yolo mode
- 🔄 Claude Code 2.1.0+ supports wildcard bash permissions: `Bash(npm *)`

**Resources**:
- [Superpowers Plugin](https://github.com/obra/superpowers) - Skills framework
- [Superpowers Marketplace](https://github.com/obra/superpowers-marketplace) - Docker containers & tools

---

### 2026-01-17: Comprehensive AI History Extraction & Cross-Machine Sync

**Session Goal**: Set up Claude Code on Windows with everything synced across all machines

**What We Accomplished**:

#### 1. Warp Terminal AI History Extraction
- **Problem**: AI queries and agent conversations stored in SQLite, not accessible
- **Location**: `~/.local/state/warp-terminal/warp.sqlite` and `warp-terminal-preview/`
- **Solution**: Extracted to CSV/JSON for human-readable, searchable format

```bash
# Extraction commands used
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv

sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  "SELECT * FROM ai_agent_conversations;" > warp-ai/agents/all-conversations.json
```

**Results**:
| Source | AI Queries | Agent Conversations |
|--------|------------|---------------------|
| Warp Terminal | 570 | 13 |
| Warp Preview | 1,138 | 36 |
| **Total** | **1,708** | **49** |

**Key Learning**: Warp stores AI history in SQLite tables `ai_queries` and `ai_agent_conversations`. The `input` field in queries is JSON containing query text, context, and attachments.

---

#### 2. Antigravity/Gemini Brain Recovery
- **Problem**: Google Antigravity IDE AI task files scattered and potentially lost
- **Location**: `~/.gemini/antigravity/brain/`
- **Solution**: Copied 15 complete task sessions with all .md files

**Session Types Recovered**:
- Debug Critical Functionality
- Install Warp Terminal
- Keyboard Layout Configuration
- Trackpad/Mouse Optimization
- Install Stremio
- System optimization tasks
- And 9 more sessions

**File Types per Session**:
- `task.md` - Task definition and requirements
- `implementation_plan.md` - Step-by-step implementation
- `walkthrough.md` - Guided walkthrough
- `verification_plan.md` - Testing and verification steps

**Key Learning**: Gemini stores task sessions by UUID in `~/.gemini/<app>/brain/`. Each session is self-contained with markdown files for each phase.

---

#### 3. Git LFS for Large Files
- **Problem**: Episodic memory archive is 128MB, too large for regular git
- **Solution**: Configured Git LFS to track `.jsonl` files

```bash
# Setup
git lfs install
git lfs track "*.jsonl"
git add .gitattributes
```

**Key Learning**: Git LFS stores large files as pointers in the repo, with actual content in LFS storage. Cloning is fast; content downloads on demand.

---

#### 4. Comprehensive Documentation
- **Created**: Polished README.md with badges, tables, collapsible sections
- **Created**: Windows setup guide (`docs/WINDOWS-SETUP.md`)
- **Created**: Warp AI index (`warp-ai/INDEX.md`)
- **Created**: Antigravity history index (`antigravity-history/INDEX.md`)

---

### 2026-01-06: Fixed Invalid Settings

**Problem**: Claude Code showed "invalid settings" error
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/settings.local.json`

**Issue Found**:
Lines 88-107 had invalid Bash permission entries trying to break down shell scripts:
```json
"Bash(for file in ...)",
"Bash(do)",
"Bash(if grep -q ...)",
// etc - shell syntax broken into individual lines
```

**Solution**:
Removed invalid shell syntax entries and replaced with proper command patterns:
```json
"Bash(sqlite3:*)",
"Bash(sudo sh:*)",
"Bash(lsattr:*)",
"Bash([ -d:*)",
"Bash([ -f:*)"
```

**Key Learning**: Bash permissions use prefix matching on complete commands, not individual shell syntax keywords.

---

### 2026-01-06: Simplified Permissions to Full Access

**Problem**: Too many specific permission entries making maintenance difficult
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/settings.local.json`

**Solution**:
Replaced 93 specific permission entries with broad tool access:
```json
{
  "permissions": {
    "allow": [
      "Bash",
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "Skill",
      "LSP",
      "NotebookEdit",
      "mcp__beeper__search_chats",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```

**Apply to other machines**: Copy this simplified config to all machines.

---

### 2026-01-06: Created Tool Discovery Skill

**Problem**: Needed proactive tool suggestions and auto-search for missing tools
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/skills/tool-discovery/SKILL.md`

**Features**:
- Auto-activates when asking "what tools are available?"
- Lists all installed MCP servers and tools
- Searches GitHub/npm/PyPI for new tools when needed
- Provides installation guidance

**Trigger phrases**:
- "what tools are available?"
- "is there a tool for..."
- "can Claude do..."
- "how can I..."

---

### 2026-01-06: Chrome Extension Connection

**Problem**: Chrome extension installed but not connecting to Claude Code
**Machine**: MacBook Air (Main)
**Status**: ⚠️ Pending installation

**Solution**:
1. Visit https://claude.ai/chrome in Chrome/Chrome Canary
2. Install the Claude extension
3. Extension auto-connects to running MCP server
4. Tools become available immediately (permissions already configured)

---

## Data Sources & Locations

### AI History Sources

| Tool | Data Location | Format | Extraction Method |
|------|---------------|--------|-------------------|
| **Claude Code** | `~/.config/superpowers/conversation-archive/` | JSONL | Direct copy (Git LFS) |
| **Warp Terminal** | `~/.local/state/warp-terminal/warp.sqlite` | SQLite | SQL query to CSV/JSON |
| **Warp Preview** | `~/.local/state/warp-terminal-preview/warp.sqlite` | SQLite | SQL query to CSV/JSON |
| **Antigravity/Gemini** | `~/.gemini/antigravity/brain/` | Markdown | Direct copy |
| **Cursor** | `~/.config/Cursor/` | Various | Minimal AI data found |
| **Zed** | `~/.local/share/zed/db/` | SQLite | No AI tables found |

### Configuration Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Claude settings | `~/.claude/settings.json` | User-level settings |
| Claude skills | `~/.claude/skills/` | Custom skill definitions |
| Project settings | `.claude/settings.json` | Project-specific overrides |
| MCP servers | `~/.claude.json` | MCP server configurations |

---

## Machine-Specific Notes

### MacBook Air (Main)

| Property | Value |
|----------|-------|
| **Hardware** | Apple MacBookAir7,2 (Early 2015) |
| **CPU** | Intel Core i5-5250U @ 1.60GHz (2 cores, 4 threads) |
| **Memory** | 8GB RAM |
| **Disk** | 111GB SSD (53GB used) |
| **OS** | Arch Linux (rolling), Kernel 6.18.x |
| **Hostname** | macbook-air |
| **User** | rob |
| **Claude Version** | 2.0.76+ |

**Installed Components**:
- **MCP Servers**: Beeper, Claude in Chrome, Episodic Memory, Playwright
- **Plugins**: superpowers, episodic-memory
- **Custom Skills**: tool-discovery, beeper-chat, omarchy
- **Dev Tools**: Git 2.52+, Node.js v25+, npm 11+

### Linux Notebook 2
- **Status**: To be configured
- **Setup Guide**: Follow `docs/WINDOWS-SETUP.md` (Linux sections)

### Windows Desktop
- **Status**: ✅ Configured (2026-01-17)
- **Setup Guide**: `docs/WINDOWS-SETUP.md`
- **Jarvis Mode**: `jarvis` or `j` aliases configured in PowerShell
- **User**: rober

---

## Repository Statistics

| Category | Count | Size |
|----------|-------|------|
| AI Queries (Warp) | 1,708 | ~2MB |
| Agent Conversations | 49 | ~1MB |
| Gemini Sessions | 15 | ~500KB |
| Episodic Memory | Full archive | ~128MB |
| Documentation Files | 25+ | ~300KB |
| Custom Skills | 4 | ~50KB |
| **Total** | **599+ files** | **~308MB** |

---

## Cross-Machine Workflows

### Workflow 1: Syncing Changes
```bash
# After making changes on any machine
cd ~/claude-cross-machine-sync
git add .
git commit -m "Updated: <description>"
git push

# On other machines
git pull
```

### Workflow 2: Finding Past Solutions
```bash
# Natural language (Claude searches episodic memory)
"What was the solution to X?"
"How did I configure Y?"

# Direct command
/episodic-memory:search-conversations "keyword"

# Search Warp history
grep -i "keyword" warp-ai/queries/all-queries.csv
```

### Workflow 3: Adding New Machine
1. Install Git LFS: `git lfs install`
2. Clone: `git clone https://github.com/robertogogoni/claude-cross-machine-sync.git`
3. Copy settings: `cp .claude/settings.json ~/.claude/`
4. Copy skills: `cp -r skills/* ~/.claude/skills/`
5. Install plugins via Claude Code

### Workflow 4: Extracting AI History (Future Updates)
```bash
# Warp Terminal
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv

# Commit new data
git add warp-ai/
git commit -m "Updated Warp AI history"
git push
```

---

## File Structure

```
~/claude-cross-machine-sync/
├── CLAUDE.md                    # This file (project memory)
├── README.md                    # Repository documentation
├── .gitattributes               # Git LFS configuration
│
├── .claude/                     # Claude Code configuration
│   ├── settings.json            # Shared settings
│   └── machine-info.json        # Machine identification
│
├── skills/                      # Custom Claude Code skills
│   ├── tool-discovery/          # Auto-discover tools
│   ├── beeper-chat/             # Beeper messaging
│   └── omarchy-skill.md         # Linux desktop config
│
├── episodic-memory/             # Conversation archive (Git LFS)
│   ├── -home-rob/               # JSONL conversation files
│   ├── conversation-index/      # Search index
│   └── learnings/               # Extracted learnings
│
├── warp-ai/                     # Warp Terminal AI history
│   ├── queries/                 # AI queries (CSV)
│   ├── agents/                  # Agent conversations (JSON)
│   ├── preview-queries/         # Warp Preview queries
│   ├── preview-agents/          # Warp Preview agents
│   └── INDEX.md                 # Documentation
│
├── antigravity-history/         # Antigravity/Gemini recovery
│   ├── gemini-brain/            # 15 task sessions
│   └── INDEX.md                 # Session index
│
├── learnings/                   # AI-generated knowledge
│   ├── bash-patterns.md         # Shell patterns
│   ├── beeper.md                # Beeper insights
│   ├── claude-code-permissions.md # Permission modes & yolo mode
│   ├── electron-wayland.md      # Electron fixes
│   ├── cross-machine-sync.md    # Sync patterns
│   └── ai-data-extraction.md    # Extraction techniques
│
└── docs/                        # Documentation
    ├── WINDOWS-SETUP.md         # Windows guide
    ├── ssh-setup.md             # SSH configuration
    ├── guides/                  # Hardware/software guides
    ├── system/                  # System reports
    ├── beeper/                  # Beeper docs
    ├── plans/                   # Development plans
    └── obra-superpowers/        # Plugin docs
```

---

## Troubleshooting

### Git LFS Issues
```bash
# Verify LFS is installed
git lfs version

# Check tracked files
git lfs ls-files

# Pull LFS content
git lfs pull
```

### Settings Not Applying
- Check `.claude/settings.json` exists in project root
- Restart Claude Code session
- Run `/config` to see loaded settings

### Episodic Memory Not Working
- Verify plugin: `/plugin list`
- Check archive exists in `episodic-memory/`
- Try specific keywords

### Warp Data Not Updating
```bash
# Re-extract from SQLite
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv
```

---

## Checklist: New Machine Setup

- [ ] Install Git and Git LFS
- [ ] Clone repository
- [ ] Copy settings to `~/.claude/`
- [ ] Copy skills to `~/.claude/skills/`
- [ ] Install Claude Code plugins
- [ ] Test episodic memory search
- [ ] Update machine-info.json
- [ ] Commit and push

---

## Resources

- **Repository**: https://github.com/robertogogoni/claude-cross-machine-sync
- **Claude Code Docs**: https://docs.anthropic.com/claude-code
- **Superpowers Plugin**: https://github.com/obra/superpowers
- **Git LFS**: https://git-lfs.github.com/

---

*This file is automatically loaded by Claude Code. Update it whenever you discover new solutions!*

*Last session: 2026-01-17 - Jarvis Mode setup (--dangerously-skip-permissions with PowerShell alias)*
