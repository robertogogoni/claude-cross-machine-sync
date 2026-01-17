#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code Cross-Machine Sync - Windows Setup Script

.DESCRIPTION
    Automatically sets up Claude Code with synced settings, skills, and episodic memory.
    Run this script on a new Windows machine to get everything configured.

.NOTES
    Repository: https://github.com/robertogogoni/claude-cross-machine-sync
    Created: 2026-01-17
#>

param(
    [string]$RepoUrl = "https://github.com/robertogogoni/claude-cross-machine-sync.git",
    [string]$InstallPath = "$env:USERPROFILE\claude-cross-machine-sync",
    [switch]$SkipPrerequisites,
    [switch]$Force
)

# Colors for output
function Write-Step { param($msg) Write-Host "`n[$([char]0x2192)] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "    [!] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "    [X] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "    $msg" -ForegroundColor Gray }

# Banner
Write-Host @"

  ╔═══════════════════════════════════════════════════════════╗
  ║       Claude Code Cross-Machine Sync - Windows Setup      ║
  ║                                                           ║
  ║  This script will:                                        ║
  ║  1. Install prerequisites (Git, Git LFS)                  ║
  ║  2. Clone the sync repository                             ║
  ║  3. Copy settings and skills to Claude Code               ║
  ║  4. Verify the installation                               ║
  ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

# Check if running as admin (not required but noted)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Info "Running as regular user (recommended)"
}

#region Prerequisites
if (-not $SkipPrerequisites) {
    Write-Step "Checking prerequisites..."

    # Check for winget
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $hasWinget) {
        Write-Error "winget not found. Please install App Installer from Microsoft Store."
        Write-Info "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1"
        exit 1
    }
    Write-Success "winget available"

    # Check/Install Git
    $hasGit = Get-Command git -ErrorAction SilentlyContinue
    if (-not $hasGit) {
        Write-Warning "Git not found. Installing..."
        winget install Git.Git --accept-package-agreements --accept-source-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $hasGit = Get-Command git -ErrorAction SilentlyContinue
        if (-not $hasGit) {
            Write-Error "Git installation failed. Please install manually and restart terminal."
            exit 1
        }
    }
    Write-Success "Git installed: $(git --version)"

    # Check/Install Git LFS
    $hasLfs = $false
    try {
        $lfsVersion = git lfs version 2>&1
        if ($lfsVersion -match "git-lfs") { $hasLfs = $true }
    } catch {}

    if (-not $hasLfs) {
        Write-Warning "Git LFS not found. Installing..."
        winget install GitHub.GitLFS --accept-package-agreements --accept-source-agreements
        # Initialize LFS
        git lfs install
    }
    Write-Success "Git LFS installed: $(git lfs version)"

    # Check Claude Code
    $hasClaude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $hasClaude) {
        Write-Warning "Claude Code not found in PATH"
        Write-Info "Please ensure Claude Code is installed: https://claude.ai/code"
        Write-Info "Continuing with setup anyway..."
    } else {
        Write-Success "Claude Code installed: $(claude --version 2>&1 | Select-Object -First 1)"
    }
}
#endregion

#region Clone Repository
Write-Step "Setting up repository..."

if (Test-Path $InstallPath) {
    if ($Force) {
        Write-Warning "Removing existing installation..."
        Remove-Item -Recurse -Force $InstallPath
    } else {
        Write-Info "Repository already exists at $InstallPath"
        Write-Info "Pulling latest changes..."
        Push-Location $InstallPath
        git pull
        Pop-Location
    }
}

if (-not (Test-Path $InstallPath)) {
    Write-Info "Cloning repository..."
    git clone $RepoUrl $InstallPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone repository"
        exit 1
    }
}
Write-Success "Repository ready at $InstallPath"

# Ensure LFS content is pulled
Write-Info "Fetching Git LFS content..."
Push-Location $InstallPath
git lfs pull
Pop-Location
Write-Success "LFS content downloaded"
#endregion

#region Copy Configuration
Write-Step "Configuring Claude Code..."

$claudeDir = "$env:USERPROFILE\.claude"
$skillsDir = "$claudeDir\skills"

# Create directories
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    Write-Success "Created $claudeDir"
}

if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    Write-Success "Created $skillsDir"
}

# Copy settings
$settingsSource = "$InstallPath\.claude\settings.json"
$settingsDest = "$claudeDir\settings.json"

if (Test-Path $settingsSource) {
    # Backup existing settings
    if (Test-Path $settingsDest) {
        $backupPath = "$settingsDest.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $settingsDest $backupPath
        Write-Info "Backed up existing settings to $backupPath"
    }
    Copy-Item $settingsSource $settingsDest -Force
    Write-Success "Copied settings.json"
} else {
    Write-Warning "settings.json not found in repository"
}

# Copy skills
$skillsSource = "$InstallPath\skills"
if (Test-Path $skillsSource) {
    $skillCount = 0
    Get-ChildItem -Path $skillsSource -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($skillsSource.Length + 1)
        $destPath = Join-Path $skillsDir $relativePath

        if ($_.PSIsContainer) {
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
        } else {
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $_.FullName $destPath -Force
            $skillCount++
        }
    }
    Write-Success "Copied $skillCount skill files"
} else {
    Write-Warning "Skills directory not found in repository"
}
#endregion

#region Verification
Write-Step "Verifying installation..."

# Check settings file
if (Test-Path $settingsDest) {
    try {
        $settings = Get-Content $settingsDest | ConvertFrom-Json
        Write-Success "Settings file is valid JSON"
    } catch {
        Write-Warning "Settings file may be invalid JSON"
    }
} else {
    Write-Warning "Settings file not found"
}

# Check skills
$installedSkills = Get-ChildItem -Path $skillsDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
Write-Success "Found $($installedSkills.Count) skill files"

# Check episodic memory
$episodicPath = "$InstallPath\episodic-memory"
if (Test-Path $episodicPath) {
    $episodicSize = (Get-ChildItem -Path $episodicPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Success "Episodic memory: $([math]::Round($episodicSize, 1)) MB"
} else {
    Write-Warning "Episodic memory not found (Git LFS may need to fetch it)"
}

# Check Warp AI history
$warpPath = "$InstallPath\warp-ai"
if (Test-Path $warpPath) {
    $queryCount = (Get-Content "$warpPath\queries\all-queries.csv" -ErrorAction SilentlyContinue | Measure-Object).Count
    $previewCount = (Get-Content "$warpPath\preview-queries\all-queries.csv" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Success "Warp AI history: $($queryCount + $previewCount - 2) queries available"
}
#endregion

#region Summary
Write-Host @"

  ╔═══════════════════════════════════════════════════════════╗
  ║                    Setup Complete!                        ║
  ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "  Repository:  $InstallPath" -ForegroundColor White
Write-Host "  Settings:    $settingsDest" -ForegroundColor White
Write-Host "  Skills:      $skillsDir" -ForegroundColor White
Write-Host ""

Write-Host "  Next Steps (run inside Claude Code):" -ForegroundColor Yellow
Write-Host ""
Write-Host "    1. Install plugins:" -ForegroundColor White
Write-Host "       /plugin marketplace add obra/superpowers-marketplace" -ForegroundColor Gray
Write-Host "       /plugin install episodic-memory@superpowers-marketplace" -ForegroundColor Gray
Write-Host "       /plugin install superpowers@superpowers-marketplace" -ForegroundColor Gray
Write-Host ""
Write-Host "    2. Verify setup:" -ForegroundColor White
Write-Host "       /config" -ForegroundColor Gray
Write-Host "       /help" -ForegroundColor Gray
Write-Host ""
Write-Host "    3. Test episodic memory:" -ForegroundColor White
Write-Host '       "What was the solution to the Warp extraction?"' -ForegroundColor Gray
Write-Host ""

Write-Host "  Documentation: $InstallPath\docs\WINDOWS-SETUP.md" -ForegroundColor Cyan
Write-Host "  Project Memory: $InstallPath\CLAUDE.md" -ForegroundColor Cyan
Write-Host ""
#endregion

#region Optional: Create Desktop Shortcut
$createShortcut = Read-Host "Create desktop shortcut to sync folder? (y/N)"
if ($createShortcut -eq 'y' -or $createShortcut -eq 'Y') {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktop\Claude Sync.lnk"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $InstallPath
    $shortcut.Description = "Claude Code Cross-Machine Sync Repository"
    $shortcut.Save()

    Write-Success "Created desktop shortcut"
}
#endregion

Write-Host "`nSetup complete! Start Claude Code to begin." -ForegroundColor Green
