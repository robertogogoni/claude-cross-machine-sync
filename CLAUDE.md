# Claude Code Cross-Machine Setup

**Last Updated**: 2026-01-06
**Machines**: MacBook Air (Main), Linux Notebook 2, Windows Desktop

## Machine Identification

This repository syncs configuration across:
- **MacBook Air** (Main) - Apple MacBookAir7,2 running Arch Linux (hostname: macbook-air)
- **Linux Notebook 2** - To be configured
- **Windows Desktop** - To be configured

See `.claude/machine-info.json` for detailed system configuration.

## Purpose
This repository synchronizes Claude Code settings, project memory, and solutions across all 3 machines.

## Quick Links
- Episodic Memory: Use `/episodic-memory:search-conversations "keyword"` to find past solutions
- Settings: `.claude/settings.json` (shared), `~/.claude/settings.json` (per-machine)
- Rules: `.claude/rules/*.md` for modular instructions

---

## Recent Solutions & Fixes

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

**Apply to other machines**: Copy `~/.claude/skills/tool-discovery/` directory.

---

### 2026-01-06: Chrome Extension Not Connecting

**Problem**: Chrome extension installed but not connecting to Claude Code
**Machine**: MacBook Air (Main)
**Status**: ⚠️ Pending installation

**Diagnosis**:
- Chrome Canary is running
- MCP server process running (`--claude-in-chrome-mcp`)
- Extension NOT installed in browser

**Solution**:
1. Visit https://claude.ai/chrome in Chrome/Chrome Canary
2. Install the Claude extension
3. Extension auto-connects to running MCP server
4. Tools become available immediately (permissions already configured)

**Apply to other machines**: Install extension on each machine's Chrome browser.

---

## Machine-Specific Notes

### MacBook Air (Main)
- **Hardware**: Apple MacBookAir7,2 (Early 2015)
- **CPU**: Intel Core i5-5250U @ 1.60GHz (2 cores, 4 threads)
- **Memory**: 8GB RAM (7.7Gi total, 2.3Gi available)
- **Disk**: 111GB SSD (53GB used, 55GB free)
- **OS**: Arch Linux (rolling), Kernel 6.18.3-arch1-1
- **Hostname**: macbook-air
- **User**: rob
- **Location**: /home/rob
- **Claude Version**: 2.0.76
- **Installed MCP Servers**:
  - Beeper (http://0.0.0.0:23373/v0/mcp)
  - Claude in Chrome (pending extension install)
  - Episodic Memory (plugin-based)
- **Installed Plugins**:
  - superpowers@superpowers-marketplace
  - episodic-memory@superpowers-marketplace
- **Custom Skills**:
  - tool-discovery (~/.claude/skills/tool-discovery/)
- **Development Tools**:
  - Git 2.52.0
  - Node.js v25.1.0
  - npm 11.6.2
  - Shell: Bash
- **Configuration**: Full permissive access enabled

### Linux Notebook 2
- **Status**: To be configured
- **Action Items**:
  - Pull this repository
  - Copy settings from this repo
  - Install tool-discovery skill
  - Configure MCP servers (Beeper, Chrome)
  - Test episodic memory sync

### Windows Desktop
- **Status**: To be configured
- **Action Items**:
  - Install Claude Code (native Windows build)
  - Pull this repository
  - Copy settings from this repo
  - Install tool-discovery skill
  - Install Chrome extension
  - SSH setup for remote Linux access

---

## Cross-Machine Workflows

### Workflow 1: Syncing Settings
```bash
# On Machine 1 (after making changes)
cd ~/claude-cross-machine-sync
git add .
git commit -m "Updated settings: <description>"
git push

# On Machine 2 & 3
cd ~/claude-cross-machine-sync
git pull
# Settings auto-apply on next Claude Code session
```

### Workflow 2: Finding Past Solutions
```bash
# On ANY machine, just ask Claude:
"What was the solution to the Chrome settings error?"
"How did I configure permissions on the Linux machine?"
"What MCP servers did I install?"

# Claude uses episodic memory to search conversation history
```

### Workflow 3: Remote Execution (SSH)
```bash
# From Windows to MacBook Air
ssh rob@<macbook-air-ip>
cd ~/project
claude

# OR use VS Code Remote SSH:
# - Open VS Code
# - Connect to SSH host
# - Open terminal
# - Run: claude
```

### Workflow 4: Documenting New Solutions
```bash
# After solving a problem, update this file:
cd ~/claude-cross-machine-sync
nano CLAUDE.md  # Add solution under "Recent Solutions & Fixes"
git add CLAUDE.md
git commit -m "Documented solution: <problem>"
git push
```

---

## Setup Instructions for New Machines

### Initial Setup (First Time)
```bash
# 1. Clone this repository
git clone <your-repo-url> ~/claude-cross-machine-sync

# 2. Link shared settings (project scope)
cd ~/your-project  # Your actual working project
ln -s ~/claude-cross-machine-sync/.claude ./.claude

# 3. Copy user-level settings (if desired)
# WARNING: This replaces your existing settings
cp ~/claude-cross-machine-sync/.claude/settings.json ~/.claude/settings.local.json

# 4. Copy custom skills
cp -r ~/claude-cross-machine-sync/skills/* ~/.claude/skills/

# 5. Create machine-specific config (copy and edit .claude/machine-info.json)
cp ~/claude-cross-machine-sync/.claude/machine-info.json ~/.claude/machine-info.json
nano ~/.claude/machine-info.json  # Update with your machine's details

# 6. Restart Claude Code
claude
```

### Keeping Updated
```bash
# Run this regularly to sync changes
cd ~/claude-cross-machine-sync
git pull
# Restart Claude Code to apply changes
```

---

## MCP Server Configurations

### Beeper (Chat Search)
```json
{
  "mcpServers": {
    "beeper": {
      "type": "http",
      "url": "http://0.0.0.0:23373/v0/mcp"
    }
  }
}
```

### Episodic Memory
Installed via plugin marketplace:
- Plugin: `episodic-memory@superpowers-marketplace`
- Auto-enables conversation search across machines
- Use: Ask Claude about past conversations

---

## Useful Commands

### Episodic Memory
```bash
# Search past conversations
/episodic-memory:search-conversations "keywords"

# Or just ask naturally:
"What was the fix for X?"
"How did I solve Y on the Linux machine?"
```

### Settings Management
```bash
# View current configuration
/config

# View loaded context (including CLAUDE.md)
/context

# View permissions
/permissions

# View MCP servers
/mcp
```

### Memory Management
```bash
# Edit memory files
/memory

# View tool inventory
"what tools are available?"  # Activates tool-discovery skill
```

---

## File Structure

```
~/claude-cross-machine-sync/
├── CLAUDE.md                    # This file (project memory)
├── .claude/
│   ├── settings.json           # Shared settings (git-synced)
│   └── rules/
│       ├── permissions.md      # Permission rules
│       └── workflows.md        # Common workflows
├── skills/
│   └── tool-discovery/
│       └── SKILL.md            # Tool discovery skill
└── docs/
    ├── ssh-setup.md            # SSH configuration guide
    └── troubleshooting.md      # Common issues
```

---

## Troubleshooting

### Settings Not Applying
- Check that `.claude/settings.json` exists in project root
- Verify git pull completed successfully
- Restart Claude Code session
- Check `/config` to see loaded settings

### Episodic Memory Not Finding Solutions
- Ensure you're logged in with same Claude account on all machines
- Try more specific keywords
- Check plugin is enabled: look for `episodic-memory@superpowers-marketplace`

### MCP Server Connection Issues
- Check server is running: `ps aux | grep mcp`
- Verify configuration in `~/.claude.json`
- Check logs: `~/.config/Claude/logs/mcp.log`
- Run `/mcp` to see connection status

### Chrome Extension Not Connecting
- Install extension: https://claude.ai/chrome
- Restart Chrome after installation
- Check extension is enabled in chrome://extensions/
- Verify MCP process: `ps aux | grep claude-in-chrome-mcp`

---

## Next Steps

- [ ] Push this repository to GitHub/GitLab
- [ ] Clone on Linux Notebook 2
- [ ] Clone on Windows Desktop
- [ ] Install Chrome extension on all machines
- [ ] Test episodic memory search across machines
- [ ] Set up SSH keys for remote access
- [ ] Document additional solutions as they arise

---

## Resources

- **Claude Code Docs**: https://code.claude.com/docs
- **Settings Reference**: https://code.claude.com/docs/en/settings.md
- **Memory System**: https://code.claude.com/docs/en/memory.md
- **MCP Integration**: https://code.claude.com/docs/en/mcp.md
- **Episodic Memory**: Search conversations with semantic search

---

*This file is automatically loaded by Claude Code on all machines. Update it whenever you solve new problems!*
