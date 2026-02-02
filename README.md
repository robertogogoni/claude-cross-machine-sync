<div align="center">

```
   _____ _                 _         _____
  / ____| |               | |       / ____|
 | |    | | __ _ _   _  __| | ___  | (___  _   _ _ __   ___
 | |    | |/ _` | | | |/ _` |/ _ \  \___ \| | | | '_ \ / __|
 | |____| | (_| | |_| | (_| |  __/  ____) | |_| | | | | (__
  \_____|_|\__,_|\__,_|\__,_|\___| |_____/ \__, |_| |_|\___|
                                            __/ |
   M A C H I N E   S Y N C                 |___/  v1.0.0
```

**Your Claude Code settings, everywhere. Safely.**

[![CI](https://github.com/robertogogoni/claude-cross-machine-sync/actions/workflows/ci.yml/badge.svg)](https://github.com/robertogogoni/claude-cross-machine-sync/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-blue)]()
[![Tests](https://img.shields.io/badge/tests-24%20passing-brightgreen)]()
[![Bash](https://img.shields.io/badge/bash-4.0+-green)]()
[![PowerShell](https://img.shields.io/badge/powershell-5.1+-blue)]()

[Features](#-features) • [Installation](#-installation) • [Roadmap](#-roadmap) • [Contributing](#contributing)

</div>

---

## 🤔 The Problem

You use Claude Code on multiple machines. You've configured permissions, installed skills, set up hooks, and tuned settings *just right*. Then you switch to your laptop and... **start from scratch**.

**Common pain points:**
- ❌ Settings don't sync between machines
- ❌ Manual copying leads to drift and conflicts
- ❌ Git conflicts in configs are scary to resolve
- ❌ No rollback when things break
- ❌ Offline work creates sync nightmares

**Machine Sync solves this.** Production-grade config synchronization with safety built in.

---

## ✨ Features

### 🚀 Core Sync
| Feature | Description |
|---------|-------------|
| **One-command bootstrap** | `./bootstrap.sh` and you're done |
| **Real-time watching** | Changes sync automatically via inotifywait/FileSystemWatcher |
| **Smart categorization** | Auto-tags commits as `[universal]`, `[linux]`, `[windows]`, or `[machine:hostname]` |
| **Background daemon** | systemd (Linux) or Task Scheduler (Windows) |

### 🛡️ Safety First
| Feature | Description |
|---------|-------------|
| **Pre-flight validation** | Checks git, network, disk space, permissions BEFORE running |
| **Snapshot & rollback** | Every bootstrap creates a restore point |
| **Dry-run mode** | `--dry-run` shows what would happen without doing it |
| **Path sanitization** | Protects against path traversal attacks |

### 🌐 Network Resilience
| Feature | Description |
|---------|-------------|
| **Offline queue** | Commits save locally when offline, push when connected |
| **Exponential backoff** | Failed pushes retry at 5s → 15s → 60s intervals |
| **Three-tier conflict resolution** | Auto-resolve → Stash & retry → Conflict branch |

### 💻 Cross-Platform
| Platform | Components |
|----------|------------|
| **Linux** | Bash + inotifywait + systemd |
| **Windows** | PowerShell + FileSystemWatcher + Task Scheduler |
| **macOS** | Bash + fswatch *(experimental)* |

---

## 📦 Installation

### Quick Start (Linux/macOS)

```bash
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git ~/machine-sync
cd ~/machine-sync && ./bootstrap.sh
```

### Quick Start (Windows PowerShell)

```powershell
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git $HOME\machine-sync
cd $HOME\machine-sync; .\bootstrap.ps1
```

### What Happens

1. ✅ Hardware auto-detected (vendor, model, CPU, GPU, RAM)
2. ✅ Machine registered in `machines/registry.yaml`
3. ✅ Sync daemon installed (systemd or Task Scheduler)
4. ✅ Configs deployed to `~/.claude/`
5. ✅ First sync pushed to git

### CLI Options

```bash
./bootstrap.sh --dry-run        # Preview without changes
./bootstrap.sh --skip-preflight # Skip validation checks
./bootstrap.sh --rollback       # Undo last bootstrap
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLI Interface                               │
│         bootstrap.sh | sync-daemon.sh | rollback                │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Bootstrap  │  │  Sync Daemon │  │   Validator  │          │
│  │    Engine    │  │    Engine    │  │    Engine    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│  ┌──────┴─────────────────┴─────────────────┴───────┐          │
│  │              Core Library (lib/)                  │          │
│  ├───────────────────────────────────────────────────┤          │
│  │ • validator.sh    • rollback.sh    • categorizer  │          │
│  │ • Git Operations  • File Watcher  • Offline Queue │          │
│  └───────────────────────────────────────────────────┘          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                Platform Adapters                          │  │
│  │   Linux (systemd)  │  Windows (Task Sched)  │  macOS      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
machine-sync/
├── bootstrap.sh          # Linux/macOS setup
├── bootstrap.ps1         # Windows setup
├── lib/
│   ├── validator.sh      # Pre-flight checks (454 lines)
│   └── rollback.sh       # Snapshot/restore (370 lines)
├── machines/
│   ├── registry.yaml     # Machine definitions
│   └── <hostname>/       # Machine-specific configs
├── platform/
│   ├── linux/scripts/    # Linux daemon (667 lines)
│   └── windows/scripts/  # Windows daemon
├── universal/            # Cross-platform shared configs
└── tests/                # 24 unit tests
```

---

## 🗺️ Roadmap

### Progress: `████████████░░░░░░░░` 60%

### ✅ v1.0.0 - Production Ready (Current)

#### Phase 1: Foundation
- [x] Pre-flight validation system (`lib/validator.sh`)
- [x] Dry-run mode for all commands
- [x] Snapshot & rollback mechanism (`lib/rollback.sh`)
- [x] Path sanitization security

#### Phase 2: Reliability
- [x] Retry logic with exponential backoff
- [x] Offline commit queue
- [x] Three-tier conflict resolution
- [ ] Beeper notifications on sync failures

#### Phase 5: Testing & CI/CD
- [x] Unit test framework (24 tests)
- [x] GitHub Actions CI (Linux, Windows, macOS)
- [ ] Integration tests
- [ ] Code coverage reporting

#### Phase 6: Documentation
- [x] README rewrite (this file!)
- [x] CONTRIBUTING.md
- [x] ROADMAP.md
- [ ] Architecture deep-dive docs
- [ ] Video walkthrough

### ⏳ v1.1.0 - Enhanced Features

- [ ] Full macOS support (fswatch + launchd)
- [ ] Secrets encryption at rest (age/GPG)
- [ ] Selective sync patterns (`.syncignore`)
- [ ] Web dashboard for status monitoring
- [ ] Unified CLI wrapper (`claude-sync`)

### 🔮 v1.2.0 - Future

- [ ] Multi-repository support
- [ ] Team sync (shared configs)
- [ ] Claude Code plugin integration
- [ ] Ansible/Terraform modules

---

## 🔧 Configuration

### Machine Registry (`machines/registry.yaml`)

```yaml
machines:
  my-laptop:
    hostname: my-laptop
    platform: linux
    status: active
    hardware:
      vendor: Dell
      model: XPS 15
      cpu: Intel i7-12700H
      memory: 32GB
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SNAPSHOT_DIR` | `~/.local/state/machine-sync/snapshots` | Snapshot storage |
| `SNAPSHOT_RETENTION_DAYS` | `30` | Auto-cleanup threshold |
| `RETRY_COUNT` | `3` | Push retry attempts |
| `OFFLINE_QUEUE_DIR` | `~/.local/state/machine-sync/offline-queue` | Offline commits |

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Development setup
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync

# Run tests
./tests/run_all.sh

# Lint
shellcheck -x lib/*.sh bootstrap.sh
```

### Commit Convention

Use scope tags for smart categorization:

| Tag | When to Use |
|-----|-------------|
| `[universal]` | Changes that work on all platforms |
| `[linux]` | Linux-specific changes |
| `[windows]` | Windows-specific changes |
| `[machine:hostname]` | Machine-specific configs |

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

Built with [Claude Code](https://claude.ai/code) by Anthropic.

**Inspired by:**
- [chezmoi](https://www.chezmoi.io/) - Dotfile management
- [yadm](https://yadm.io/) - Yet Another Dotfiles Manager
- [stow](https://www.gnu.org/software/stow/) - Symlink farm manager

---

<div align="center">

**[Documentation](docs/) • [Report Bug](https://github.com/robertogogoni/claude-cross-machine-sync/issues) • [Request Feature](https://github.com/robertogogoni/claude-cross-machine-sync/issues)**

Made with ☕ and Claude Code

⭐ Star this repo if it helps you!

</div>
