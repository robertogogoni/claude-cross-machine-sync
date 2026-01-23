#Requires -Version 5.1
<#
.SYNOPSIS
    Machine Sync Daemon for Windows
    Watches for file changes and auto-syncs to git

.DESCRIPTION
    Uses FileSystemWatcher to detect changes in the sync repo.
    Auto-commits with categorized tags and pushes to remote.
    Periodically pulls changes from other machines.

.NOTES
    Install: Run bootstrap.ps1 to set up Task Scheduler
    Manual: .\sync-daemon.ps1 -Mode Watch
    Status: .\sync-daemon.ps1 -Mode Status
#>

param(
    [ValidateSet("Watch", "SyncNow", "Pull", "Status", "Install", "Uninstall")]
    [string]$Mode = "Watch",

    [string]$RepoPath = "$env:USERPROFILE\claude-cross-machine-sync",
    [int]$PullIntervalMinutes = 5,
    [switch]$Verbose
)

# Configuration
$script:LogFile = "$env:LOCALAPPDATA\machine-sync\sync.log"
$script:LockFile = "$env:LOCALAPPDATA\machine-sync\daemon.lock"
$script:TaskName = "Machine-Sync-Daemon"
$script:Hostname = $env:COMPUTERNAME
$script:DebounceSeconds = 3
$script:LastSyncTime = [DateTime]::MinValue

# Ensure directories exist
$logDir = Split-Path $script:LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $logEntry
    if ($Verbose -or $Level -eq "ERROR") {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN"  { "Yellow" }
            "INFO"  { "Cyan" }
            default { "White" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
}

# Categorization logic
function Get-CommitScope {
    param([string[]]$ChangedFiles)

    $scopes = @()

    foreach ($file in $ChangedFiles) {
        $relativePath = $file.Replace($RepoPath, "").TrimStart("\", "/")

        if ($relativePath -match "^machines/([^/]+)/") {
            $machine = $Matches[1]
            $scopes += "[machine:$machine]"
        }
        elseif ($relativePath -match "^platform/windows/") {
            $scopes += "[windows]"
        }
        elseif ($relativePath -match "^platform/linux/") {
            $scopes += "[linux]"
        }
        elseif ($relativePath -match "^universal/") {
            $scopes += "[universal]"
        }
        else {
            # Default: determine from content/path
            if ($relativePath -match "\.ps1$|powershell|windows") {
                $scopes += "[windows]"
            }
            elseif ($relativePath -match "\.sh$|bash|linux|hypr") {
                $scopes += "[linux]"
            }
            else {
                $scopes += "[universal]"
            }
        }
    }

    # Return unique scopes
    $uniqueScopes = $scopes | Select-Object -Unique
    return ($uniqueScopes -join "")
}

# Git operations
function Invoke-GitSync {
    param([switch]$PushChanges)

    Push-Location $RepoPath
    try {
        # Check for changes
        $status = git status --porcelain 2>&1
        if (-not $status) {
            Write-Log "No changes to sync"
            return
        }

        # Get changed files
        $changedFiles = git status --porcelain | ForEach-Object {
            $_.Substring(3)
        }

        # Determine scope
        $scope = Get-CommitScope -ChangedFiles $changedFiles

        # Stage and commit
        git add -A

        $commitMsg = "$scope Auto-sync from $script:Hostname`n`nChanged files:`n"
        $commitMsg += ($changedFiles | ForEach-Object { "- $_" }) -join "`n"
        $commitMsg += "`n`nCo-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

        git commit -m $commitMsg 2>&1 | Out-Null
        Write-Log "Committed: $scope ($($changedFiles.Count) files)"

        if ($PushChanges) {
            $pushResult = git push 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Pushed to remote"
            }
            else {
                Write-Log "Push failed: $pushResult" -Level "WARN"
            }
        }
    }
    catch {
        Write-Log "Git sync error: $_" -Level "ERROR"
    }
    finally {
        Pop-Location
    }
}

function Invoke-GitPull {
    Push-Location $RepoPath
    try {
        # Fetch first
        git fetch origin 2>&1 | Out-Null

        # Check if we're behind
        $localHead = git rev-parse HEAD
        $remoteHead = git rev-parse origin/master 2>$null
        if (-not $remoteHead) {
            $remoteHead = git rev-parse origin/main
        }

        if ($localHead -ne $remoteHead) {
            Write-Log "Pulling changes from remote..."
            $pullResult = git pull --rebase 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Pull successful"
                # TODO: Trigger deploy script
                return $true
            }
            else {
                Write-Log "Pull failed: $pullResult" -Level "WARN"
            }
        }
    }
    catch {
        Write-Log "Git pull error: $_" -Level "ERROR"
    }
    finally {
        Pop-Location
    }
    return $false
}

# FileSystemWatcher setup
function Start-FileWatcher {
    Write-Log "Starting file watcher for $RepoPath"

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $RepoPath
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor
                            [System.IO.NotifyFilters]::DirectoryName -bor
                            [System.IO.NotifyFilters]::LastWrite

    # Exclude patterns
    $excludePatterns = @("\.git", "\.swp$", "~$", "\.lock$", "\.log$")

    $onChange = {
        $path = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType

        # Skip excluded patterns
        foreach ($pattern in $excludePatterns) {
            if ($path -match $pattern) { return }
        }

        # Debounce
        $now = [DateTime]::Now
        if (($now - $script:LastSyncTime).TotalSeconds -lt $script:DebounceSeconds) {
            return
        }
        $script:LastSyncTime = $now

        Write-Log "Change detected: $changeType - $path"

        # Wait for batch changes to complete
        Start-Sleep -Seconds 1

        # Sync
        Invoke-GitSync -PushChanges
    }

    Register-ObjectEvent $watcher "Changed" -Action $onChange | Out-Null
    Register-ObjectEvent $watcher "Created" -Action $onChange | Out-Null
    Register-ObjectEvent $watcher "Deleted" -Action $onChange | Out-Null
    Register-ObjectEvent $watcher "Renamed" -Action $onChange | Out-Null

    return $watcher
}

# Main watch loop
function Start-WatchLoop {
    Write-Log "Machine Sync Daemon starting on $script:Hostname"

    # Check for existing instance
    if (Test-Path $script:LockFile) {
        $existingPid = Get-Content $script:LockFile -ErrorAction SilentlyContinue
        if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
            Write-Log "Daemon already running (PID: $existingPid)" -Level "WARN"
            return
        }
    }

    # Create lock file
    $PID | Out-File $script:LockFile -Force

    try {
        # Initial pull
        Invoke-GitPull

        # Start file watcher
        $watcher = Start-FileWatcher

        # Periodic pull loop
        $lastPull = [DateTime]::Now

        Write-Log "Daemon running. Press Ctrl+C to stop."

        while ($true) {
            Start-Sleep -Seconds 30

            # Check if it's time to pull
            if (([DateTime]::Now - $lastPull).TotalMinutes -ge $PullIntervalMinutes) {
                $hasChanges = Invoke-GitPull
                if ($hasChanges) {
                    # Deploy changes
                    Write-Log "Deploying pulled changes..."
                    # TODO: Call deploy script
                }
                $lastPull = [DateTime]::Now
            }
        }
    }
    finally {
        # Cleanup
        if (Test-Path $script:LockFile) {
            Remove-Item $script:LockFile -Force
        }
        Write-Log "Daemon stopped"
    }
}

# Task Scheduler management
function Install-ScheduledTask {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = "$RepoPath\platform\windows\scripts\sync-daemon.ps1"
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode Watch"

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -RestartCount 3

    Register-ScheduledTask -TaskName $script:TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Machine Sync Daemon - Auto-syncs configurations across machines" `
        -Force

    Write-Host "Task '$script:TaskName' installed successfully" -ForegroundColor Green
    Write-Host "The daemon will start automatically at logon." -ForegroundColor Cyan
}

function Uninstall-ScheduledTask {
    Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Task '$script:TaskName' removed" -ForegroundColor Yellow
}

function Get-DaemonStatus {
    Write-Host "`nMachine Sync Daemon Status" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan

    # Check Task Scheduler
    $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "Task Status: $($task.State)" -ForegroundColor $(if ($task.State -eq "Running") { "Green" } else { "Yellow" })
    }
    else {
        Write-Host "Task Status: Not installed" -ForegroundColor Red
    }

    # Check lock file
    if (Test-Path $script:LockFile) {
        $pid = Get-Content $script:LockFile
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Daemon Process: Running (PID: $pid)" -ForegroundColor Green
        }
        else {
            Write-Host "Daemon Process: Stale lock file" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Daemon Process: Not running" -ForegroundColor Yellow
    }

    # Show recent logs
    Write-Host "`nRecent log entries:" -ForegroundColor Cyan
    if (Test-Path $script:LogFile) {
        Get-Content $script:LogFile -Tail 10
    }
    else {
        Write-Host "No logs yet" -ForegroundColor Gray
    }
}

# Main entry point
switch ($Mode) {
    "Watch" {
        Start-WatchLoop
    }
    "SyncNow" {
        Invoke-GitSync -PushChanges
    }
    "Pull" {
        Invoke-GitPull
    }
    "Status" {
        Get-DaemonStatus
    }
    "Install" {
        Install-ScheduledTask
    }
    "Uninstall" {
        Uninstall-ScheduledTask
    }
}
