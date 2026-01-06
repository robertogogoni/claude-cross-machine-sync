# Claude Code Cross-Machine Sync

Synchronize Claude Code settings, memory, and solutions across multiple machines.

## Quick Start

### On Machine 1 (Setup)
```bash
cd ~/claude-cross-machine-sync
git init
git add .
git commit -m "Initial Claude Code sync setup"
git remote add origin <your-repo-url>
git push -u origin main
```

### On Machines 2 & 3 (Clone)
```bash
git clone <your-repo-url> ~/claude-cross-machine-sync
cd ~/your-project
ln -s ~/claude-cross-machine-sync/.claude ./.claude
cp ~/claude-cross-machine-sync/.claude/settings.json ~/.claude/settings.local.json
cp -r ~/claude-cross-machine-sync/skills/* ~/.claude/skills/
```

## What's Included

- **CLAUDE.md** - Project memory with solutions and fixes
- **.claude/settings.json** - Shared permission and tool configurations
- **skills/** - Custom Claude Code skills (tool-discovery)
- **docs/ssh-setup.md** - SSH remote access guide

## Features

### 🔄 Git-Based Sync
Settings and memory files sync automatically via git across all machines.

### 🔍 Episodic Memory
Search past conversations from any machine:
```
"What was the solution to X on my Linux machine?"
```

### 🖥️ Remote Execution
SSH into machines and run Claude Code remotely (see `docs/ssh-setup.md`)

### 🛠️ Tool Discovery
Custom skill that suggests and searches for tools automatically.

## Usage

### Daily Workflow
```bash
# Morning: Pull latest
cd ~/claude-cross-machine-sync && git pull

# Work on projects...
# Claude Code loads settings and memory automatically

# Evening: Push changes
cd ~/claude-cross-machine-sync
git add .
git commit -m "Updated: <description>"
git push
```

### Finding Past Solutions
Just ask Claude:
- "How did I fix the Chrome settings?"
- "What permissions did I configure?"
- "What MCP servers are installed?"

### Remote Execution
```bash
# SSH into another machine
ssh linux-notebook-1
cd ~/project
claude
```

## File Structure

```
~/claude-cross-machine-sync/
├── README.md               # This file
├── CLAUDE.md              # Project memory (auto-loaded)
├── .claude/
│   └── settings.json      # Shared settings
├── skills/
│   └── tool-discovery/    # Custom skills
└── docs/
    └── ssh-setup.md       # SSH configuration guide
```

## Machines

- **Linux Notebook 1** (Main) - Arch Linux
- **Linux Notebook 2** - TBD
- **Windows Desktop** - TBD

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Full project memory and solutions
- [SSH Setup](./docs/ssh-setup.md) - Remote access configuration

## Update History

- **2026-01-06**: Initial setup
  - Fixed invalid settings
  - Created tool-discovery skill
  - Simplified permissions configuration
  - Documented Chrome extension issue

---

*Sync your Claude Code experience across all machines!*
