# Tools & Software Inventory

**Last updated:** 2026-03-18
**Scope:** All machines in the sync ecosystem

## Samsung Laptop (omarchy-samsung)

### Core Stack
| Tool | Version | Purpose |
|------|---------|---------|
| Arch Linux | Rolling | OS |
| Hyprland | Latest | Wayland compositor (via Omarchy) |
| Ghostty | Latest | Terminal emulator |
| Chrome Canary | 147.0.7700.0 | Default browser |
| Claude Code CLI | 2.1.78 | AI coding assistant |
| Claude Desktop | 1.1.7203 (AUR) | AI desktop app |

### Development Tools
| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 25.2.1 (via mise) | JS/TS runtime |
| npm | 11.6.2 | Package manager |
| uvx | 0.10.11 | Python tool runner (for MCP servers) |
| git | system | Version control |
| gh CLI | system | GitHub CLI |

### System Utilities Installed
| Package | Purpose | Installed |
|---------|---------|-----------|
| vulkan-intel | GPU Vulkan driver (ANV) | 2026-03-17 |
| libva-intel-driver | VA-API video decode | 2026-03-17 |
| thermald | Intel thermal management | 2026-03-17 |
| earlyoom | OOM killer (10% threshold) | 2026-03-17 |
| xdotool | X11 mouse/keyboard automation | 2026-03-18 |
| scrot | X11 screenshots | 2026-03-18 |
| grim + slurp | Wayland screenshots | Pre-existing |
| wl-clipboard | Wayland clipboard | Pre-existing |
| imagemagick | Image processing | Pre-existing |
| python-secretstorage | Keyring access from Python | 2026-03-18 |
| Playwright chromium | Browser automation (MCP) | 2026-03-18 |

### MCP Servers (13 CLI + 13 Desktop)
See `machines/samsung-laptop/memory/project_mcp_servers.md` for full list.

### Custom Scripts
| Script | Location | Purpose |
|--------|----------|---------|
| claude-memory-sync | ~/.local/bin/ | Compiles CLI memories into profile |
| claude-desktop-update | ~/.local/bin/ | Auto-updates Claude Desktop from AUR |
| log-bash-command.sh | ~/.claude/scripts/ | Logs all bash commands with timestamps |
| security-check.sh | ~/.claude/scripts/audit/ | Security audit of Claude configs |
| detect-machine.sh | ~/.claude/machines/ | Auto-detects hardware profile |

### Chrome Extensions (46, audited 2026-03-18)
Key extensions: Claude (v1.0.62), Browser MCP (v1.3.4), AdGuard, Tampermonkey, Refined GitHub, Gitako.
6 performance hotspots identified, 20 ghost entries, 8 already disabled.

### systemd User Services
| Unit | Purpose | Status |
|------|---------|--------|
| claude-desktop-update.timer | Daily Claude Desktop update check | enabled |

### Hooks (Claude Code CLI)
| Hook | Trigger | Action |
|------|---------|--------|
| File Protection | PreToolUse (Edit/Write) | Blocks edits to .env, credentials, SSH keys, system configs |
| Bash Logging | PostToolUse (Bash) | Logs commands to ~/.claude/logs/bash-commands.log |
| Machine Detection | SessionStart | Auto-detects and loads machine profile |
| Cortex Start | SessionStart | Initializes cortex memory system |
| Cortex End | SessionEnd | Persists cortex learnings |
| Memory Sync | SessionEnd | Compiles CLI memories for Desktop |
| Cortex Compact | PreCompact | Preserves memories before context compression |
| Cortex Stop | Stop | Final cortex cleanup |
