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

| Feature | MacBook Air (Main) | Linux Notebook 2 | Windows Desktop |
|---------|-------------------|------------------|-----------------|
| **Status** | ✅ Configured | ⏳ Pending | ⏳ Pending |
| **Hardware** | MacBookAir7,2 | TBD | TBD |
| **OS** | Arch Linux | TBD | Windows |
| **Claude Version** | 2.0.76 | TBD | TBD |
| **MCP: Beeper** | ✅ Configured | TBD | TBD |
| **MCP: Chrome** | ⏳ Extension pending | TBD | TBD |
| **Tool Discovery** | ✅ Installed | TBD | TBD |
| **SSH Access** | ⏳ To configure | TBD | TBD |

---

**Next Steps**:
1. Push this repository to GitHub/GitLab
2. Set up Linux Notebook 2
3. Set up Windows Desktop
4. Configure SSH between all machines
5. Test cross-machine workflows
