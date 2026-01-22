# Omarchy Config Sync

Machine-aware configuration sync for [Omarchy](https://github.com/omarchy/omarchy) (Hyprland-based Linux desktop).

## Quick Start (New Machine)

```bash
# Clone and setup in one command
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git ~/claude-cross-machine-sync
~/claude-cross-machine-sync/omarchy/setup.sh
```

That's it! The setup script will:
1. ✅ Check dependencies (install `inotify-tools` if needed)
2. ✅ Create machine-specific config from your current setup
3. ✅ Install and enable the auto-sync daemon
4. ✅ Deploy universal configs
5. ✅ Sync your configs to the repo

### Setup Options

```bash
./setup.sh              # Interactive setup (recommended)
./setup.sh --auto       # Non-interactive (use defaults)
./setup.sh --uninstall  # Remove daemon and service
```

## Structure

```
omarchy/
├── universal/              # Works on ANY omarchy system
│   ├── hypr/
│   │   ├── bindings.conf   # App shortcuts, workspace nav
│   │   ├── envs.conf       # Wayland environment vars
│   │   ├── workspace-window-rules.conf
│   │   └── apps/           # Per-app window rules
│   ├── waybar/
│   ├── terminals/
│   └── walker/
│
├── machines/
│   ├── macbook-air/        # MacBook Air specific
│   │   ├── machine.yaml    # Hardware metadata
│   │   └── hypr/
│   │       ├── monitors.conf    # Display config
│   │       ├── input.conf       # Keyboard/trackpad
│   │       ├── looknfeel.conf   # Performance tweaks
│   │       └── bindings.conf    # HW-specific keys
│   │
│   └── linux-notebook-2/   # Second machine (template)
│       └── hypr/
│
└── deploy.sh               # Deployment script
```

## Usage

### Deploy configs to this machine

```bash
cd ~/claude-cross-machine-sync/omarchy
./deploy.sh
hyprctl reload
```

### Add a new machine

1. Create directory: `machines/<hostname>/`
2. Copy machine.yaml template and customize
3. Add machine-specific configs (monitors, input, etc.)
4. Run `./deploy.sh`

## Categorization Rules

### Machine-Specific → `machines/<hostname>/`

| Category | Examples | Why |
|----------|----------|-----|
| **Monitors** | Resolution, scale, position | Different screens |
| **Input devices** | Touchpad sensitivity, device names | Different hardware |
| **Performance** | Blur, shadows, animations | Different GPUs |
| **Power** | Battery profiles, lid actions | Laptop vs desktop |
| **Hardware keys** | Fn keys, keyboard backlight | Device-specific |

### Universal → `universal/`

| Category | Examples | Why |
|----------|----------|-----|
| **Keybindings** | App launchers, screenshots | Same workflow |
| **Window rules** | Workspace assignments | Same apps |
| **Environment** | Wayland vars, themes | Cross-platform |
| **App configs** | Terminal colors, fonts | Preference |

## How It Works

1. `deploy.sh` checks `$(hostname)` to find machine-specific configs
2. Universal configs are deployed first as the base
3. Machine-specific configs override where needed
4. Combined `bindings.conf` sources both universal and machine-specific

## Files Modified

The deploy script creates/updates:

- `~/.config/hypr/bindings-universal.conf` - Universal bindings
- `~/.config/hypr/bindings-machine.conf` - Machine-specific bindings
- `~/.config/hypr/bindings.conf` - Combined (sources both above)
- `~/.config/hypr/monitors.conf` - From machine-specific
- `~/.config/hypr/input.conf` - From machine-specific
- `~/.config/hypr/looknfeel.conf` - From machine-specific
- `~/.config/hypr/envs.conf` - From universal
- `~/.config/hypr/workspace-window-rules.conf` - From universal
- `~/.config/waybar/*` - From universal
- `~/.config/*/` - Terminal, walker configs

## Auto-Sync Daemon

The `omarchy-sync-daemon.sh` provides automatic bidirectional sync:

### Features
- **Watches** `~/.config/hypr`, `waybar`, terminals for changes
- **Auto-categorizes** changes as machine-specific or universal
- **Commits & pushes** changes to git automatically
- **Pulls & deploys** changes from other machines (every 5 min)
- **Reloads Hyprland** when changes are deployed

### Usage

```bash
# Manual control
./omarchy-sync-daemon.sh           # Run in foreground
./omarchy-sync-daemon.sh --bg      # Run in background
./omarchy-sync-daemon.sh --stop    # Stop daemon
./omarchy-sync-daemon.sh --status  # Check status

# Systemd service (recommended)
systemctl --user enable omarchy-sync   # Enable on boot
systemctl --user start omarchy-sync    # Start now
systemctl --user status omarchy-sync   # Check status
journalctl --user -u omarchy-sync -f   # View logs
```

### Log File

Logs are written to: `~/.local/state/omarchy-sync.log`

## Claude Code Integration

When Claude Code modifies omarchy configs:
1. Changes can be made directly to `~/.config/` for immediate effect
2. The daemon auto-syncs to the repo with proper categorization
3. Or Claude can manually run `./sync-to-repo.sh --commit --push`
