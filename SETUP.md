# Quick Setup Guide

## For New Machines

When setting up Claude Code sync on a new machine (Linux Notebook 2 or Windows Desktop):

### 1. Clone the Repository
```bash
git clone <your-repo-url> ~/claude-cross-machine-sync
cd ~/claude-cross-machine-sync
```

### 2. Copy Machine Info Template
```bash
cp .claude/machine-info.json ~/.claude/machine-info.json
```

### 3. Update Your Machine Info
Edit `~/.claude/machine-info.json` with your machine's details:
```bash
# Get your system info
uname -a                    # Kernel
lscpu | grep "Model name"   # CPU
free -h                     # Memory
df -h /                     # Disk
hostnamectl                 # System details
claude --version            # Claude version
```

Update the JSON with:
- Machine name (e.g., "Linux Notebook 2", "Windows Desktop")
- Machine ID (e.g., "linux-notebook-2", "windows-desktop")
- Hardware specs
- Installed software versions

### 4. Copy Settings & Skills
```bash
# Copy shared settings to local
cp .claude/settings.json ~/.claude/settings.local.json

# Copy custom skills
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

### 5. Link Project Settings (Optional)
If you want project-scoped settings in a specific project:
```bash
cd ~/your-project
ln -s ~/claude-cross-machine-sync/.claude ./.claude
```

### 6. Install Plugins
Your plugins should sync automatically via Claude account, but verify:
```bash
# Check enabled plugins in ~/.claude/settings.json
# Should see:
# - superpowers@superpowers-marketplace
# - episodic-memory@superpowers-marketplace
```

### 7. Configure MCP Servers
Update `~/.claude.json` if needed. For Beeper:
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

### 8. Restart Claude Code
```bash
claude
```

### 9. Verify Setup
```bash
# Test episodic memory
# In Claude Code, ask: "what tools are available?"

# Check loaded memory
/memory

# View configuration
/config

# List MCP servers
/mcp
```

## Daily Sync Routine

### Morning (Pull Updates)
```bash
cd ~/claude-cross-machine-sync
git pull
```

### Evening (Push Changes)
```bash
cd ~/claude-cross-machine-sync

# Update CLAUDE.md if you solved new problems
nano CLAUDE.md

# Commit and push
git add .
git commit -m "Updated: <description>"
git push
```

## Machine Comparison

| Feature | MacBook Air | Samsung 270E5J | Dell G15 |
|---------|-------------|----------------|----------|
| **Status** | ✅ Active | ✅ Active | ⏳ Pending |
| **Hardware** | MacBookAir7,2 (i5-5250U) | 270E5J (i7-4510U) | G15 5530 (TBD) |
| **OS** | Arch Linux + Hyprland | Arch Linux + Hyprland | Windows 11 |
| **Claude Code** | ✅ Configured | ✅ Configured | ✅ Configured |
| **MCP Servers** | ✅ 12 servers | ✅ 13 servers | TBD |
| **Omarchy Sync** | ✅ 5 hypr configs | ✅ 6 hypr configs | N/A (Windows) |
| **Chrome Flags** | ✅ Synced | ✅ Synced | N/A |
| **Memory** | ✅ Synced | ✅ 5 memories | TBD |

---

**Next Steps**:
1. Complete Dell G15 bootstrap (hardware detection, full config)
2. Install and enable omarchy sync daemon on Samsung and MacBook
3. Test cross-machine sync workflows
