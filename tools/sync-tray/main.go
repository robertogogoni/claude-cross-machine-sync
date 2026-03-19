package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"fyne.io/systray"
)

// SyncStatus represents the daemon's current state
type SyncStatus struct {
	Timestamp string `json:"timestamp"`
	Event     string `json:"event"`
	Detail    string `json:"detail"`
	Status    string `json:"status"`
	Hostname  string `json:"hostname"`
	Machine   string `json:"machine"`
	PID       int    `json:"pid"`
}

var (
	statusFile string
	logFile    string
	repoDir    string
)

func init() {
	home, _ := os.UserHomeDir()
	statusFile = filepath.Join(home, ".local/state/omarchy-sync-status.json")
	logFile = filepath.Join(home, ".local/state/omarchy-sync.log")
	repoDir = filepath.Join(home, "claude-cross-machine-sync")
}

func main() {
	systray.Run(onReady, onExit)
}

func onReady() {
	// Set initial icon and title
	systray.SetIcon(iconSynced)
	systray.SetTitle("Sync")
	systray.SetTooltip("Claude Sync: Starting...")

	// Menu items
	mStatus := systray.AddMenuItem("Loading...", "Current sync status")
	mStatus.Disable()

	mLastSync := systray.AddMenuItem("Last sync: --", "Last sync event")
	mLastSync.Disable()

	mMachine := systray.AddMenuItem("Machine: --", "Current machine")
	mMachine.Disable()

	systray.AddSeparator()

	mWatching := systray.AddMenuItem("Watching: -- dirs", "Directories being watched")
	mWatching.Disable()

	systray.AddSeparator()

	mSyncNow := systray.AddMenuItem("Sync Now", "Trigger manual sync")
	mViewLog := systray.AddMenuItem("View Log (last 20)", "Show recent log entries")
	mOpenRepo := systray.AddMenuItem("Open Repo", "Open sync repo in file manager")

	systray.AddSeparator()

	mRestart := systray.AddMenuItem("Restart Daemon", "Restart the sync daemon")
	mQuit := systray.AddMenuItem("Quit Tray", "Remove tray icon (daemon keeps running)")

	// Status polling goroutine
	go func() {
		ticker := time.NewTicker(2 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				status := readStatus()
				updateUI(status, mStatus, mLastSync, mMachine, mWatching)
			case <-mSyncNow.ClickedCh:
				triggerSync()
			case <-mViewLog.ClickedCh:
				showLog()
			case <-mOpenRepo.ClickedCh:
				exec.Command("xdg-open", repoDir).Start()
			case <-mRestart.ClickedCh:
				restartDaemon()
			case <-mQuit.ClickedCh:
				systray.Quit()
			}
		}
	}()
}

func onExit() {}

func readStatus() *SyncStatus {
	data, err := os.ReadFile(statusFile)
	if err != nil {
		return nil
	}
	var s SyncStatus
	if err := json.Unmarshal(data, &s); err != nil {
		return nil
	}
	return &s
}

func updateUI(s *SyncStatus, mStatus, mLastSync, mMachine, mWatching *systray.MenuItem) {
	if s == nil {
		systray.SetIcon(iconError)
		systray.SetTooltip("Claude Sync: Daemon not running")
		mStatus.SetTitle("Daemon not running")
		return
	}

	// Check if daemon is alive (status file not stale > 10 min)
	ts, err := time.Parse(time.RFC3339, s.Timestamp)
	if err == nil && time.Since(ts) > 10*time.Minute {
		systray.SetIcon(iconError)
		systray.SetTooltip("Claude Sync: Daemon stale")
		mStatus.SetTitle("Daemon stale (no updates in 10m)")
		return
	}

	// Update icon based on event
	switch s.Event {
	case "sync", "change":
		systray.SetIcon(iconSyncing)
		systray.SetTooltip(fmt.Sprintf("Claude Sync: Syncing %s", s.Detail))
	case "idle", "started":
		systray.SetIcon(iconSynced)
		systray.SetTooltip("Claude Sync: Watching")
	default:
		systray.SetIcon(iconSynced)
		systray.SetTooltip("Claude Sync: " + s.Event)
	}

	// Update menu items
	mStatus.SetTitle(fmt.Sprintf("Status: %s", s.Event))
	mMachine.SetTitle(fmt.Sprintf("Machine: %s", s.Machine))

	if s.Detail != "" {
		detail := s.Detail
		if len(detail) > 50 {
			detail = "..." + detail[len(detail)-47:]
		}
		mLastSync.SetTitle(fmt.Sprintf("Last: %s", detail))
	}

	// Count watched dirs
	watchCount := countWatchedDirs()
	mWatching.SetTitle(fmt.Sprintf("Watching: %d dirs (config + claude)", watchCount))
}

func countWatchedDirs() int {
	home, _ := os.UserHomeDir()
	dirs := []string{
		"hypr", "waybar", "alacritty", "kitty", "ghostty", "walker", "mako",
	}
	claudeDirs := []string{
		".claude/agents", ".claude/commands", ".claude/skills",
	}

	count := 0
	for _, d := range dirs {
		path := filepath.Join(home, ".config", d)
		if info, err := os.Stat(path); err == nil && info.IsDir() {
			count++
		}
	}
	for _, d := range claudeDirs {
		path := filepath.Join(home, d)
		if info, err := os.Stat(path); err == nil && info.IsDir() {
			count++
		}
	}
	// Count project memory dirs
	matches, _ := filepath.Glob(filepath.Join(home, ".claude/projects/*/memory"))
	count += len(matches)

	return count
}

func triggerSync() {
	cmd := exec.Command(
		filepath.Join(repoDir, "omarchy/sync-to-repo.sh"),
		"--commit", "--push",
	)
	cmd.Dir = filepath.Join(repoDir, "omarchy")
	cmd.Start()
}

func showLog() {
	out, err := exec.Command("tail", "-20", logFile).Output()
	if err != nil {
		out = []byte("Could not read log file")
	}

	// Show in a terminal notification or popup
	lines := strings.TrimSpace(string(out))
	cmd := exec.Command("notify-send", "-a", "Claude Sync", "Recent Sync Log", lines)
	cmd.Run()
}

func restartDaemon() {
	exec.Command("systemctl", "--user", "restart", "omarchy-sync.service").Run()
}
