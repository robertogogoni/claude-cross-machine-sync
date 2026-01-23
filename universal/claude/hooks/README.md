# Session Persistence Hooks

Source: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)

These hooks provide session persistence across Claude Code sessions.

## Installation

Copy to your `~/.claude/hooks/` directory:

```bash
# Linux/macOS
mkdir -p ~/.claude/hooks
cp universal/claude/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

```powershell
# Windows (PowerShell) - hooks need to be adapted for Windows
# These bash hooks work in Git Bash or WSL
```

## Configuration

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/session-start.sh"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/session-end.sh"
      }]
    }]
  }
}
```

## How It Works

### session-start.sh
- Runs when a new Claude session starts
- Checks for recent session files (last 7 days)
- Reports available context to load
- Checks for learned skills

### session-end.sh
- Runs when Claude session ends
- Creates/updates daily session file at `~/.claude/sessions/YYYY-MM-DD-session.tmp`
- Maintains template for tracking:
  - Completed tasks
  - In-progress work
  - Notes for next session
  - Files to load

## Session File Location

Session files are stored in `~/.claude/sessions/`:
```
~/.claude/sessions/
├── 2026-01-23-session.tmp
├── 2026-01-22-session.tmp
└── ...
```

## Cross-Machine Sync

To sync session files across machines, add to your machine-specific sync:

```yaml
# In machines/<hostname>/machine.yaml
sync_paths:
  - ~/.claude/sessions/
```
