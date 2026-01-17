# Windows Setup Guide 🪟

Complete guide for setting up Claude Code cross-machine sync on Windows.

> **Platform**: This guide is **Windows-specific**. For Linux/macOS setup, see `LINUX-SETUP.md` (coming soon) or adapt the commands using Bash equivalents.

## Prerequisites

1. **Claude Code installed** (you mentioned this is done)
2. **Git for Windows** - https://git-scm.com/download/win
3. **Git LFS** - Comes with Git for Windows, or install via `git lfs install`
4. **GitHub CLI** (optional but recommended) - https://cli.github.com/

## Step 1: Install Git LFS

Open PowerShell or Git Bash:

```powershell
# Check if Git LFS is installed
git lfs version

# If not installed, install it
git lfs install
```

## Step 2: Clone the Sync Repository

```powershell
# Clone to your home directory
cd ~
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git

# This will download all files including LFS objects (episodic memory)
# May take a few minutes due to 133MB of LFS data
```

## Step 3: Set Up Claude Code Configuration

### Option A: Symlink Method (Recommended)

```powershell
# Create symbolic links (requires admin PowerShell or Developer Mode enabled)

# Link settings
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$env:USERPROFILE\claude-cross-machine-sync\.claude\settings.json" -Force

# Copy skills (symlinks for directories work differently on Windows)
Copy-Item -Recurse "$env:USERPROFILE\claude-cross-machine-sync\skills\*" "$env:USERPROFILE\.claude\skills\" -Force
```

### Option B: Copy Method

```powershell
# Copy settings
Copy-Item "$env:USERPROFILE\claude-cross-machine-sync\.claude\settings.json" "$env:USERPROFILE\.claude\settings.json" -Force

# Copy skills
Copy-Item -Recurse "$env:USERPROFILE\claude-cross-machine-sync\skills\*" "$env:USERPROFILE\.claude\skills\" -Force
```

## Step 4: Set Up Episodic Memory

The episodic memory plugin stores conversations in a specific location. On Windows:

```powershell
# Create the superpowers config directory
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\superpowers" -Force

# Option A: Symlink the conversation archive
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\superpowers\conversation-archive" -Target "$env:USERPROFILE\claude-cross-machine-sync\episodic-memory\-home-rob" -Force

# Option B: Or just copy it
Copy-Item -Recurse "$env:USERPROFILE\claude-cross-machine-sync\episodic-memory\*" "$env:USERPROFILE\.config\superpowers\" -Force
```

## Step 5: Install Required Plugins

In Claude Code, install the required plugins:

```
/plugin install superpowers@superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
```

## Step 6: Create Machine Info

Create your Windows machine identification:

```powershell
# Create machine info file
$machineInfo = @{
    machineName = "Windows Desktop"
    machineId = "windows-desktop"
    hardware = @{
        cpu = (Get-WmiObject Win32_Processor).Name
        memory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1).ToString() + "GB"
    }
    system = @{
        os = "Windows"
        osVersion = (Get-WmiObject Win32_OperatingSystem).Caption
        hostname = $env:COMPUTERNAME
    }
    software = @{
        claudeCode = @{
            version = "check with 'claude --version'"
        }
        shell = "PowerShell"
    }
    lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
}

$machineInfo | ConvertTo-Json -Depth 10 | Out-File "$env:USERPROFILE\.claude\machine-info.json" -Encoding utf8
```

## Step 7: Set Up "Jarvis Mode" (Optional - Full Autonomy) 🪟

If you want Claude Code to run without permission prompts ("yolo mode"), set up the jarvis alias.

> **Note**: This section is Windows/PowerShell-specific. For Bash/Zsh equivalents, see `learnings/claude-code-permissions.md`.

### Add to PowerShell Profile

```powershell
# Open your PowerShell profile for editing
notepad $PROFILE

# Or for both PowerShell versions:
notepad "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
notepad "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
```

Add these lines:

```powershell
# Claude Code "Jarvis Mode" - auto-approve all permissions
function jarvis { claude --dangerously-skip-permissions @args }

# Alias for convenience
Set-Alias -Name j -Value jarvis

Write-Host "Jarvis mode ready. Use 'jarvis' or 'j' to launch Claude Code with full autonomy." -ForegroundColor Cyan
```

### Reload Profile

```powershell
# Either restart PowerShell or run:
. $PROFILE
```

### Usage

```powershell
jarvis          # Full autonomy mode
j               # Short alias
j --resume      # Resume with autonomy (args pass through)
```

> **Warning**: In jarvis mode, Claude can edit/delete any file and run any command without asking. Only use in trusted environments.

---

## Step 8: Test the Setup

1. **Start Claude Code**:
   ```powershell
   claude
   ```

2. **Test episodic memory**:
   ```
   Search for past conversations about "chrome settings"
   ```

3. **Verify skills are loaded**:
   ```
   what tools are available?
   ```

## Daily Sync Workflow

### Pull Latest Changes (Before Working)

```powershell
cd ~/claude-cross-machine-sync
git pull
```

### Push Your Changes (After Working)

```powershell
cd ~/claude-cross-machine-sync
git add .
git commit -m "Updated from Windows: <description>"
git push
```

## Automatic Sync (Optional)

Create a scheduled task to auto-sync:

```powershell
# Create a sync script
@"
cd $env:USERPROFILE\claude-cross-machine-sync
git pull --rebase
git add .
git diff --quiet --cached || git commit -m "Auto-sync from Windows"
git push
"@ | Out-File "$env:USERPROFILE\claude-sync.ps1"

# Run it manually or add to Task Scheduler
```

## Troubleshooting

### Git LFS Issues

```powershell
# Re-fetch LFS objects
cd ~/claude-cross-machine-sync
git lfs fetch --all
git lfs checkout
```

### Permission Issues with Symlinks

Windows requires either:
1. **Developer Mode enabled** (Settings > Update & Security > For developers)
2. **Run PowerShell as Administrator**

### Claude Code Not Finding Settings

Verify the paths:
```powershell
# Check Claude config directory
dir $env:USERPROFILE\.claude

# Should show:
# - settings.json (or symlink to sync repo)
# - skills/ directory
# - machine-info.json
```

### Episodic Memory Not Working

1. Verify plugin is installed: `/mcp`
2. Check conversation archive location
3. Restart Claude Code

## Path Reference

| Component | Windows Path |
|-----------|--------------|
| Claude Config | `%USERPROFILE%\.claude\` |
| Settings | `%USERPROFILE%\.claude\settings.json` |
| Skills | `%USERPROFILE%\.claude\skills\` |
| Superpowers Config | `%USERPROFILE%\.config\superpowers\` |
| Sync Repo | `%USERPROFILE%\claude-cross-machine-sync\` |

## Next Steps

1. [ ] Clone the repository
2. [ ] Set up symlinks or copy files
3. [ ] Install plugins
4. [ ] Create machine-info.json
5. [ ] Set up "Jarvis Mode" alias (optional)
6. [ ] Test episodic memory
7. [ ] Set up SSH for remote access to MacBook Air (see docs/ssh-setup.md)

---

*Updated: 2026-01-17*

---

## Platform Reference

| Section | Platform |
|---------|----------|
| All steps | 🪟 Windows |
| Jarvis Mode alias | 🪟 PowerShell-specific |
| Git/Git LFS commands | 🔄 Cross-platform (same syntax) |
| Path conventions | 🪟 Windows (`%USERPROFILE%`, backslashes) |

**Legend**: 🪟 Windows | 🐧 Linux/macOS | 🔄 Cross-platform
