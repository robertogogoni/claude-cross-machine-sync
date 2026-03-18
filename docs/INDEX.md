# Navigation Index

Quick-start guide: find what you need, fast.

---

## I need to...

### Set up a new machine
| Resource | Description |
|----------|-------------|
| [bootstrap.sh](../bootstrap.sh) | One-command setup for Linux/macOS |
| [bootstrap.ps1](../bootstrap.ps1) | One-command setup for Windows |
| [SETUP.md](../SETUP.md) | Step-by-step manual setup guide |
| [linux-setup.sh](../scripts/linux-setup.sh) | Linux-specific automated setup |
| [windows-setup.ps1](../scripts/windows-setup.ps1) | Windows-specific automated setup |
| [machines/registry.yaml](../machines/registry.yaml) | Machine registry with all known hosts |

### Troubleshoot a problem
| Resource | Description |
|----------|-------------|
| [chrome-extension-troubleshooting](../learnings/chrome-extension-troubleshooting.md) | Native messaging, bridge reconnect, Canary host registration |
| [beeper-package-conflict-fix](../learnings/beeper-package-conflict-fix.md) | Resolving Beeper AUR package conflicts |
| [github-profile-widgets-troubleshooting](../learnings/github-profile-widgets-troubleshooting.md) | Fixing Vercel-based GitHub profile widgets |
| [system-diagnostics-patterns](../learnings/system-diagnostics-patterns.md) | Linux performance debugging patterns |
| [PERSISTENCE_STATUS.md](system/PERSISTENCE_STATUS.md) | What survives a reboot and what doesn't |
| [reboot-proof-verification.md](system/reboot-proof-verification.md) | Verifying configs persist across reboots |

### Understand why something works this way
| Resource | Description |
|----------|-------------|
| [INSIGHTS.md](INSIGHTS.md) | The WHY behind every major decision |
| [Architecture Decision Records](decisions/architecture-decisions.md) | Formal ADRs with context, decision, and consequences |
| [ROADMAP.md](../ROADMAP.md) | Where the project is headed and current progress |

### See the big picture
| Resource | Description |
|----------|-------------|
| [Ecosystem Map](diagrams/ecosystem-map.md) | All machines, cloud services, and their connections |
| [Repository Structure](diagrams/repo-structure.md) | Directory tree showing the three-tier classification |
| [Full Repo Map](diagrams/full-repo-map.md) | File distribution across 2,300+ files by category |
| [MCP Topology](diagrams/mcp-topology.md) | MCP server distribution across CLI and Desktop |
| [Memory Architecture](diagrams/memory-architecture.md) | Three-layer memory system (files, Cortex, profile) |
| [Multi-Machine State](diagrams/multi-machine-state.md) | Machine registry and sync status |
| [Hooks Lifecycle](diagrams/hooks-lifecycle.md) | Session start to end: what runs and when |
| [Chrome Extension Bridge](diagrams/chrome-extension-bridge.md) | Native messaging chain from CLI to Chrome |
| [Knowledge Graph](diagrams/knowledge-graph.md) | How the 20 learning documents connect |
| [Hookify Rules Flow](diagrams/hookify-rules-flow.md) | Keyword-triggered skill enforcement system |
| [AI History Map](diagrams/ai-history-map.md) | Cross-platform AI tool usage (Warp, Gemini, Claude) |

### Find a specific config
| Path | Description |
|------|-------------|
| `universal/claude/` | Cross-platform Claude configs (agents, commands, hooks, skills, memory) |
| `universal/claude/commands/` | Custom slash commands: analyze, eureka, explain, refactor, security-scan, think-harder |
| `universal/claude/agents/` | Subagent definitions: code-reviewer, debugger, planner, test-writer |
| `universal/claude/skills/` | Reusable skills: code-review, debugging, testing |
| `universal/claude/hooks/` | Hook scripts: session-start, session-end, skill-activator |
| `universal/claude/memory/` | Universal memory files synced to all machines |
| `universal/claude/mcp-servers/` | Custom MCP server code (memory-sync) |
| `universal/claude/scripts/audit/` | Security check, config validation, audit summary |
| `universal/compose/XCompose` | Compose key sequences (cedilla fix) |
| `universal/electron/electron-flags.conf` | Electron Ozone/Wayland flags |
| `platform/linux/omarchy/` | Hyprland, waybar, terminal, and walker configs |
| `platform/linux/scripts/` | Sync daemon, Claude Desktop updater |
| `platform/linux/systemd/` | Systemd units for auto-update timer |
| `platform/linux/memory/` | Linux-specific memory files |
| `platform/windows/scripts/` | PowerShell sync daemon |
| `machines/samsung-laptop/` | Samsung-specific: chrome flags, hypr overrides, memory |
| `machines/macbook-air/` | MacBook-specific: chrome flags, fcitx5, hypr overrides |
| `machines/dell-g15/` | Dell G15 machine spec (machine.yaml) |
| `hookify-rules/` | Hookify rule files for skill enforcement |
| `skills/` | Top-level skills: beeper-chat, omarchy, tool-discovery |
| `connections/` | Personal communication registry |

### Learn from past sessions
| Resource | Description |
|----------|-------------|
| [2026-01-17 Cross-Machine Sync](sessions/2026-01-17-cross-machine-sync.md) | Initial multi-machine setup session |
| [2026-03-18 Samsung Setup](sessions/2026-03-18-samsung-setup.md) | Full Samsung laptop configuration session |
| [Episodic Memory](../episodic-memory/) | JSONL session logs from MacBook and Windows |
| [Breakthroughs Index](../learnings/breakthroughs/INDEX.md) | Technical breakthroughs captured via `/eureka` |

### Check system health
| Resource | Description |
|----------|-------------|
| [security-check.sh](../universal/claude/scripts/audit/security-check.sh) | Scan for exposed secrets, bad permissions, missing .gitignore |
| [validate-configs.sh](../universal/claude/scripts/audit/validate-configs.sh) | Validate JSON syntax across all config files |
| [audit-summary.sh](../universal/claude/scripts/audit/audit-summary.sh) | Generate a full audit summary |
| [tools-inventory.md](system/tools-inventory.md) | Installed tools and versions per machine |
| [OPTIMIZATION_REPORT.md](system/OPTIMIZATION_REPORT.md) | System optimization status and recommendations |
| [system-report-and-recommendations.md](system/system-report-and-recommendations.md) | Hardware-aware system report |

### Update or add configs
| Resource | Description |
|----------|-------------|
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Contribution guidelines and PR process |
| [machine-sync-patterns](../learnings/machine-sync-patterns.md) | Auto-categorization system: how files get classified |
| [cross-machine-sync](../learnings/cross-machine-sync.md) | Sync patterns and conflict resolution strategies |
| [INSIGHTS.md -- Classification](INSIGHTS.md) | Why configs are split into universal/platform/machine tiers |

### Work with MCP servers
| Resource | Description |
|----------|-------------|
| [MCP Topology diagram](diagrams/mcp-topology.md) | Visual map of all MCP servers and their distribution |
| [claude-desktop-config.template.json](../universal/claude/claude-desktop-config.template.json) | Template for Claude Desktop MCP config |
| [memory-sync server](../universal/claude/mcp-servers/memory-sync/server.cjs) | Custom MCP server bridging CLI memory to Desktop |

### Work with Chrome/extensions
| Resource | Description |
|----------|-------------|
| [chrome-performance-tuning](../learnings/chrome-performance-tuning.md) | Field trials, Vulkan, raster threads, extension audit |
| [chrome-extension-troubleshooting](../learnings/chrome-extension-troubleshooting.md) | Native messaging, bridge reconnect, Canary host |
| [native-messaging-chrome-canary](../learnings/native-messaging-chrome-canary.md) | Chrome Canary native messaging via symlink |
| [Chrome Extension Bridge diagram](diagrams/chrome-extension-bridge.md) | Connection chain from CLI to Chrome |
| [chrome-canary-flags-guide](guides/chrome-canary-flags-guide.md) | Comprehensive Chrome Canary flags reference |
| [electron-wayland](../learnings/electron-wayland.md) | Ozone flags, GPU compositing, scale factor separation |

### Work with memories
| Resource | Description |
|----------|-------------|
| [Memory Architecture diagram](diagrams/memory-architecture.md) | Three-layer system: CLI files, Cortex DB, profile bridge |
| [memory-sync-bridge](../learnings/memory-sync-bridge.md) | How CLI memory syncs to Desktop via MCP |
| [custom-instructions-optimization](../learnings/custom-instructions-optimization.md) | Optimizing Claude custom instructions for context efficiency |
| [ADR-001: Memory System](decisions/architecture-decisions.md) | Why three layers exist |
| [Universal memory files](../universal/claude/memory/) | Shared memory deployed to all machines |

### Work with Beeper
| Resource | Description |
|----------|-------------|
| [Beeper Knowledge Base](../learnings/beeper.md) | Comprehensive Beeper learnings and patterns |
| [beeper-package-conflict-fix](../learnings/beeper-package-conflict-fix.md) | Resolving AUR package conflicts |
| [Beeper MCP auto-renewal guide](beeper/beeper-mcp-auto-renewal-guide.md) | Keeping Beeper MCP token fresh |
| [Beeper design docs](beeper/) | Bridge manager plan, developer community analysis |
| [Beeper Extended v2 design](plans/2026-02-15-beeper-extended-v2-design.md) | Extended Beeper integration design |
| [Beeper Knowledge Base design](plans/2026-02-15-beeper-knowledge-base-design.md) | Structured Beeper KB design |

### Work with Omarchy/Hyprland
| Resource | Description |
|----------|-------------|
| [Omarchy Hyprland configs](../platform/linux/omarchy/hypr/) | bindings, apps, envs, workspace rules |
| [Omarchy app configs](../platform/linux/omarchy/hypr/apps/) | Per-app window rules (20+ apps) |
| [Terminal configs](../platform/linux/omarchy/terminals/) | Alacritty, Ghostty, Kitty configs |
| [Waybar config](../platform/linux/omarchy/waybar/) | Bar config and style |
| [Walker config](../platform/linux/omarchy/walker/) | App launcher config |
| [electron-wayland](../learnings/electron-wayland.md) | Electron/Wayland integration patterns |
| [Omarchy sync skill](../skills/omarchy-skill.md) | Omarchy config sync skill definition |
| [Cedilla fix design](plans/2026-02-25-wayland-cedilla-fix-design.md) | Wayland cedilla input fix |

---

## Learnings by Topic

### System & Infrastructure
| Learning | Description |
|----------|-------------|
| [electron-wayland](../learnings/electron-wayland.md) | Ozone flags, GPU compositing, scale factor separation for Electron on Wayland |
| [system-diagnostics-patterns](../learnings/system-diagnostics-patterns.md) | Linux performance debugging: sensors, power, disk, network patterns |
| [bash-patterns](../learnings/bash-patterns.md) | Reusable bash scripting patterns and anti-patterns |

### Chrome & Browser
| Learning | Description |
|----------|-------------|
| [chrome-performance-tuning](../learnings/chrome-performance-tuning.md) | Field trials, Vulkan, raster threads, extension audit for low-end hardware |
| [chrome-extension-troubleshooting](../learnings/chrome-extension-troubleshooting.md) | Native messaging, bridge reconnect, Canary host registration |
| [native-messaging-chrome-canary](../learnings/native-messaging-chrome-canary.md) | Symlink trick for Chrome Canary native messaging support |

### Claude Code & AI Tools
| Learning | Description |
|----------|-------------|
| [claude-code-permissions](../learnings/claude-code-permissions.md) | Permission modes, autonomy levels, and trust tiers |
| [claude-desktop-linux](../learnings/claude-desktop-linux.md) | Running Claude Desktop on Arch Linux with Hyprland/Wayland |
| [cli-intelligence-patterns](../learnings/cli-intelligence-patterns.md) | Tab completion, intent detection, smart suggestions engine |
| [custom-instructions-optimization](../learnings/custom-instructions-optimization.md) | Reducing token waste in custom instructions |
| [skill-enforcement-hooks](../learnings/skill-enforcement-hooks.md) | Hookify system for automatic skill activation |
| [ai-data-extraction](../learnings/ai-data-extraction.md) | Techniques for extracting data from AI tool histories |

### Sync & Memory
| Learning | Description |
|----------|-------------|
| [cross-machine-sync](../learnings/cross-machine-sync.md) | Core sync patterns, conflict resolution, offline handling |
| [machine-sync-patterns](../learnings/machine-sync-patterns.md) | Auto-categorization system v2.0 for commit tagging |
| [memory-sync-bridge](../learnings/memory-sync-bridge.md) | Bridging CLI memory to Desktop via MCP server |

### Beeper & Communication
| Learning | Description |
|----------|-------------|
| [beeper](../learnings/beeper.md) | Beeper knowledge base: bridges, Matrix API, Scout patterns |
| [beeper-package-conflict-fix](../learnings/beeper-package-conflict-fix.md) | Resolving Beeper Desktop AUR package conflicts |
| [personal-communication](../learnings/personal-communication.md) | Personal communication patterns and contact registry |

### GitHub & DevOps
| Learning | Description |
|----------|-------------|
| [vercel-github-widgets](../learnings/vercel-github-widgets.md) | Vercel-hosted GitHub profile widget troubleshooting |
| [github-profile-widgets-troubleshooting](../learnings/github-profile-widgets-troubleshooting.md) | Fixing broken GitHub profile widgets and badges |

---

*Last generated: 2026-03-18*
