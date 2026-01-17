# Setup Scripts

Automated setup scripts for Claude Code Cross-Machine Sync.

## Quick Start

### Windows (PowerShell)

**Option 1: One-liner (download and run)**
```powershell
irm https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/scripts/windows-setup.ps1 | iex
```

**Option 2: Download first, then run**
```powershell
# Download
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/scripts/windows-setup.ps1" -OutFile "windows-setup.ps1"

# Review (optional)
notepad windows-setup.ps1

# Run
.\windows-setup.ps1
```

**Option 3: Clone and run**
```powershell
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync
.\scripts\windows-setup.ps1
```

### Linux / macOS (Bash)

**Option 1: One-liner (download and run)**
```bash
curl -fsSL https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/scripts/linux-setup.sh | bash
```

**Option 2: Download first, then run**
```bash
# Download
curl -O https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/scripts/linux-setup.sh

# Review (optional)
less linux-setup.sh

# Run
chmod +x linux-setup.sh
./linux-setup.sh
```

**Option 3: Clone and run**
```bash
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync
./scripts/linux-setup.sh
```

## What the Scripts Do

1. **Check/Install Prerequisites**
   - Git
   - Git LFS (required for episodic memory)

2. **Clone Repository**
   - Clones to `~/claude-cross-machine-sync`
   - Pulls latest if already exists
   - Fetches Git LFS content

3. **Configure Claude Code**
   - Copies `settings.json` to `~/.claude/`
   - Copies skills to `~/.claude/skills/`
   - Backs up existing settings first

4. **Verify Installation**
   - Checks settings file validity
   - Reports episodic memory size
   - Shows available Warp AI queries

## Post-Setup (Manual Steps)

After running the script, open Claude Code and run:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Then verify with:
```
/config
/help
```

## Script Options

### Windows (windows-setup.ps1)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-RepoUrl` | Git repository URL | GitHub repo |
| `-InstallPath` | Where to clone | `~/claude-cross-machine-sync` |
| `-SkipPrerequisites` | Skip Git/LFS checks | `$false` |
| `-Force` | Remove existing and re-clone | `$false` |

Example:
```powershell
.\windows-setup.ps1 -Force -InstallPath "D:\claude-sync"
```

### Linux (linux-setup.sh)

Edit variables at top of script to customize:
```bash
REPO_URL="https://github.com/your-fork/claude-cross-machine-sync.git"
INSTALL_PATH="$HOME/my-claude-sync"
```

## Troubleshooting

### "Execution Policy" Error (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git LFS Not Working
```bash
git lfs install
cd ~/claude-cross-machine-sync
git lfs pull
```

### Settings Not Loading
1. Restart Claude Code
2. Check `/config` output
3. Verify `~/.claude/settings.json` exists

## Security Note

These scripts:
- Only read from/write to your home directory
- Don't require admin/root access
- Don't send data anywhere except GitHub (for cloning)
- Back up existing files before overwriting

Review the scripts before running if you're concerned about security.
