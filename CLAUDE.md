# Claude Code Cross-Machine Setup

**Last Updated**: 2026-03-19
**Machines**: Dell G15 (Windows), MacBook Air (Linux), Samsung Laptop (Linux)
**Repository**: https://github.com/robertogogoni/claude-cross-machine-sync

## Machine Identification

This repository syncs configuration across:
- **Dell G15 5530** (Windows 11) - Gaming laptop, hostname: Rob-Dell, user: rober
- **MacBook Air** (Arch Linux/Omarchy) - hostname: macbook-air, user: rob
- **Samsung Laptop** (Arch Linux/Omarchy) - hostname: omarchy, user: robthepirate

See `machines/registry.yaml` for the complete machine ecosystem configuration.

## Purpose

This repository is a **comprehensive AI intelligence hub** that:
1. Synchronizes Claude Code settings, memory, and skills across machines
2. Aggregates AI conversation history from multiple tools (Claude, Warp, Gemini)
3. Preserves learnings and patterns discovered during development
4. Provides searchable access to past solutions via episodic memory

## Quick Links

- **Episodic Memory**: `/episodic-memory:search-conversations "keyword"`
- **Settings**: `.claude/settings.json` (shared), `~/.claude/settings.json` (per-machine)
- **Skills**: `skills/` directory - custom Claude Code capabilities
- **Warp AI History**: `warp-ai/` - 1,708 queries, 49 agent conversations
- **Gemini Sessions**: `antigravity-history/gemini-brain/` - 15 task sessions

---

## 🤖 Auto-Categorization System (v2.0)

**NEW**: Comprehensive AI-driven auto-categorization for the entire machine ecosystem.

### Directory Structure

```
machines/                      # Machine-specific configs
├── registry.yaml              # Source of truth for all machines
├── dell-g15/                  # Windows gaming laptop
│   ├── machine.yaml           # Hardware specs
│   ├── claude/                # Claude Code settings
│   └── shell/                 # PowerShell configs
├── macbook-air/               # Linux laptop
│   ├── machine.yaml
│   ├── claude/
│   └── hypr/                  # Hyprland configs
└── samsung-laptop/            # Linux laptop (pending)

platform/                      # Platform-specific (all machines of type)
├── windows/
│   └── scripts/sync-daemon.ps1
└── linux/
    ├── scripts/sync-daemon.sh
    └── omarchy/               # Hyprland universal configs

universal/                     # Cross-platform (works everywhere)
└── claude/
    └── settings.json
```

### Commit Tag Conventions

| Tag | Meaning | Example |
|-----|---------|---------|
| `[universal]` | Works on all machines | Settings, shared configs |
| `[windows]` | Windows-specific | PowerShell scripts, .ps1 files |
| `[linux]` | Linux-specific | Bash scripts, systemd, Hyprland |
| `[machine:dell-g15]` | Specific machine only | GPU tweaks, monitor layout |

### Categorization Decision Tree

```
Is it hardware-dependent (monitor, GPU, trackpad)?
  └─YES→ [machine:<hostname>] → machines/<hostname>/

Is it OS-specific (PowerShell vs Bash, systemd vs Task Scheduler)?
  └─YES→ [windows] or [linux] → platform/<os>/

Otherwise:
  └─NO→ [universal] → universal/
```

### Background Sync Daemons

**Windows (Task Scheduler)**:
```powershell
# Status
.\platform\windows\scripts\sync-daemon.ps1 -Mode Status

# Manual sync
.\platform\windows\scripts\sync-daemon.ps1 -Mode SyncNow

# Install/Uninstall
.\platform\windows\scripts\sync-daemon.ps1 -Mode Install
.\platform\windows\scripts\sync-daemon.ps1 -Mode Uninstall
```

**Linux (systemd)**:
```bash
# Status
./platform/linux/scripts/sync-daemon.sh --status

# Manual run
./platform/linux/scripts/sync-daemon.sh

# Install systemd service
./platform/linux/scripts/sync-daemon.sh --install
```

### Bootstrap New Machine

**One-command setup**:
```bash
# Windows (PowerShell)
.\bootstrap.ps1

# Linux
./bootstrap.sh
```

Bootstrap automatically:
1. Detects hardware (vendor, model, CPU, GPU, RAM)
2. Registers machine in `machines/registry.yaml`
3. Creates machine-specific directory
4. Installs sync daemon
5. Deploys configs
6. Commits and pushes to git

### Current Machine Status

| Machine | Hostname | Platform | Daemon | Status |
|---------|----------|----------|--------|--------|
| Dell G15 5530 | Rob-Dell | Windows 11 | Running | ✅ Active |
| MacBook Air | macbook-air | Arch Linux | Pending | ⏳ Migration |
| Samsung 270E5J | omarchy | Arch Linux | Manual | ✅ Active |

---

## Recent Solutions & Fixes

### 2026-02-02: System Update Errors & GitHub Profile Fixes

**Session Goal**: Fix system update errors and troubleshoot GitHub profile widgets

**What We Accomplished**:

#### 1. Fixed beeper-v4-bin AUR Package Conflict

**Problem**: `yay -Syu` failed with "file exists in filesystem" errors (75+ files)

**Root Cause**:
- `update-beeper` script installs Beeper to `/opt/beeper` without pacman tracking
- `beeper-v4-bin` AUR package owns the same files
- Pacman detects modified files and refuses to overwrite

**Solution**:
1. Removed AUR package: `sudo pacman -Rdd --noconfirm beeper-v4-bin`
2. Restored from backup: `sudo cp -a /opt/beeper-backups/beeper-backup-*/* /opt/beeper/`
3. Added to yay ignore list in `omarchy-update-system-pkgs`
4. Created migration script at `migrations/1770031300.sh`

**Key Learning**: Pacman's `-Rdd` flag only skips dependency checks, it still removes files. There's no clean way to "orphan" files in pacman.

**Documentation**: `learnings/beeper-package-conflict-fix.md`

#### 2. Fixed GitHub Profile Widget Errors

**Problem**: "Something went wrong" error on profile widgets

**Issues Found & Fixed**:

| Issue | Root Cause | Fix |
|-------|------------|-----|
| Repo pin widget broken | `claude-cross-machine-sync` is PRIVATE | Replaced with public `awesome-beeper` |
| Snake animation broken | Workflow lacked `contents: write` permission | Added permissions block |
| No output branch | Workflow couldn't push | Fixed by permission change |

**Key Learning**: GitHub readme-stats widgets cannot display PRIVATE repositories even with a PAT on Vercel - visitors can't authenticate.

**Files Modified**:
- `.github/workflows/snake.yml` - Added `permissions: contents: write`
- `README.md` - Replaced private repo widget

**Documentation**: `learnings/github-profile-widgets-troubleshooting.md`

#### 3. Stored Insights to Cortex

Captured 6 patterns/learnings:
- Pacman `-Rdd` behavior
- AUR package conflict resolution pattern
- GitHub Actions workflow permissions
- Private repo widget limitations
- Cache busting for Vercel widgets
- Widget theme naming conventions

**Commits Made**:
- `omarchy`: Fix beeper-v4-bin AUR package conflict
- `claude-cross-machine-sync`: Documentation (2 commits)
- `update-beeper`: CHANGELOG update
- `robertogogoni/robertogogoni`: Widget and workflow fixes (2 commits)

---

### 2026-01-27: Cortex v2.0.0 Production Release

**Session Goal**: Complete implementation of Cortex MCP server and ship to production

**What We Accomplished**:

#### 1. Completed 43-Task Implementation Plan

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1-3 | Documentation, Core Skills, UX Polish | ✅ Complete |
| Phase 4-5 | MCP Resources & Prompts | ✅ Complete |
| Phase 6 | MCP Sampling | ✅ Design Decision (uses direct API) |
| Phase 7 | MCP Elicitation | ⏳ Deferred (client support pending) |
| Phase 8 | Security Layer | ✅ Complete |
| Phase 9 | Future-Proofing | ✅ Complete |

#### 2. Security Layer Implementation

Created comprehensive security infrastructure:
- **Input Validation** (`core/validation.cjs`): Sanitization for all 6 MCP tools
- **Rate Limiting** (`core/rate-limiter.cjs`): Sliding window, tiered limits (Haiku vs Sonnet)
- **Audit Logging** (`core/audit-logger.cjs`): JSONL with rotation, correlation IDs
- **Encryption** (`core/encryption.cjs`): AES-256-GCM at-rest with PBKDF2 key derivation

#### 3. MCP Server Features

| Feature | Implementation |
|---------|---------------|
| **6 Tools** | query, recall, reflect, infer, learn, consolidate |
| **Resources** | 7 URI patterns for memory browsing |
| **Prompts** | 5 predefined workflows |
| **Dual-Model** | Haiku (~$0.25/1M) for fast, Sonnet (~$3/1M) for deep |

#### 4. Repository Status

- **Repository**: https://github.com/robertogogoni/cortex-claude
- **Files**: 75 tracked
- **Tests**: 31/31 passing
- **Commits**: 8 new commits pushed to master

#### 5. Configuration Setup

Added API key to `~/.claude.json` for Cortex MCP:
```json
{
  "mcpServers": {
    "cortex": {
      "command": "node",
      "args": ["/home/rob/.claude/memory/cortex/server.cjs"],
      "env": {
        "ANTHROPIC_API_KEY": "..."
      }
    }
  }
}
```

**Key Learnings**:
- MCP servers run as child processes, inherit parent env vars
- Direct Anthropic API preferred over MCP Sampling for cost control
- OWASP recommends 100,000+ PBKDF2 iterations for key derivation
- Sliding window rate limiting prevents boundary burst attacks

**Next Steps**:
1. Restart Claude Code to test `/cortex health`
2. Submit to awesome-mcp-servers for visibility
3. Post on r/ClaudeAI and Anthropic Discord

**Session Summary**: `~/.claude/memory/docs/sessions/2026-01-27-cortex-production-release.md`

---

### 2026-01-24: Unified CLI Intelligence System Design

**Session Goal**: Design a system for natural language skill activation, automatic memory management, and intelligent auto-completion

**What We Accomplished**:

#### 1. Deep GitHub Research (20+ Projects Analyzed)

| Category | Key Projects | Main Insight |
|----------|--------------|--------------|
| **Skill Auto-Activation** | claude-skills-supercharged, claude-code-infrastructure-showcase | Haiku-powered intent detection with confidence scoring |
| **Continuous Learning** | Claudeception | Auto-extract skills when solving hard problems |
| **Memory Management** | mcp-memory-service, claude-mem | "Dream-inspired" consolidation, auto-capture |
| **Terminal AI** | autocomplete-sh, nl-sh, ai-shell | Natural language → shell commands |
| **Fuzzy Matching** | fzf, fuzzball.js, fuzz-run | Typo-tolerant command matching |

#### 2. Discovered The #1 Skill Problem

**The core issue**: Claude Code skills don't activate on their own. Users must:
- Know exact skill names
- Manually invoke them with `/skill-name`
- Remember which skill applies to which situation

**The solution**: UserPromptSubmit hook + AI intent analyzer:
```
User prompt → Haiku analyzes intent → Score each skill (0.0-1.0)
  → Auto-inject if >0.65
  → Suggest if 0.50-0.65
  → Ignore if <0.50
```

#### 3. Designed 4-Part Unified System

**Part 1: Natural Language Skill Activation**
- skill-registry.json maps patterns/aliases to skills
- Haiku API for intent detection (~$1-2/month)
- MD5-cached prompts (1hr TTL, ~95% API reduction)
- Fallback chain: Semantic → Fuzzy → Regex → Suggestions

**Part 2: Automatic Memory Management**
- 4-layer hierarchy: Working → Short-Term → Long-Term → Cross-Machine
- SessionEnd hook extracts learnings automatically
- Daily consolidation daemon
- Syncs to claude-cross-machine-sync repo

**Part 3: Intelligent Auto-Completion**
- Multi-source: skills, plugins, MCP tools, shell history, memory
- Semantic + fuzzy + recency ranking
- PowerShell and Bash integration modules

**Part 4: Continuous Learning (Claudeception)**
- Auto-creates skills when you solve hard problems
- Quality gates ensure only useful knowledge persists
- Syncs auto-extracted skills across machines

#### 4. Installed SuperNavigator 6.1.0 (Enhanced)

- **Location**: `~/.claude/plugins/supernavigator`
- **Skills**: 34 total (17 OS Layer + 14 App Layer + 3 Integration)
- **New skills created**:
  - `nav-sync`: Cross-machine .agent/ synchronization
  - `nav-notify`: Beeper notifications for task events
  - `nav-search`: Episodic memory search before debugging

#### 5. Created Comprehensive Design Document

- **Location**: `docs/plans/2026-01-24-unified-cli-intelligence-design.md`
- **Content**: Architecture, code examples, implementation phases, dependencies

**Key Learnings**:
- UserPromptSubmit hook intercepts every prompt (great for injection)
- Haiku is cheap/fast enough for per-prompt analysis
- skill-rules.json pattern matching for API-free fallback
- Sentence transformers for semantic similarity
- Progressive disclosure keeps skill loading efficient (~100 tokens metadata)
- Claudeception research: Voyager (2023), CASCADE (2024), SEAgent (2025)

**Key GitHub Resources**:
- [claude-skills-supercharged](https://github.com/jefflester/claude-skills-supercharged) - 7-stage AI injection
- [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) - Auto-activation technique
- [Claudeception](https://github.com/blader/Claudeception) - Autonomous skill extraction
- [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) - Dream-inspired memory
- [autocomplete-sh](https://github.com/closedLoop-technologies/autocomplete-sh) - AI terminal completion

#### 6. Implemented Phase 1: Skill Activator Engine

**Files Created**:
- `~/.claude/data/skill-registry.json` - All 34 skills with triggers
- `~/.claude/hooks/skill-activator.js` - Hook that analyzes prompts
- `~/.claude/settings.json` - Hook configuration added

**Skill Registry Format**:
```json
{
  "name": "systematic-debugging",
  "aliases": ["debug", "fix bug", "troubleshoot"],
  "triggers": {
    "keywords": ["bug", "error", "broken", "crash"],
    "patterns": ["not working", "doesn't work", "getting.*error"],
    "intent_phrases": ["something is broken", "help me debug"]
  },
  "confidence_boost": 0.25
}
```

**Scoring Algorithm**:
| Match Type | Score | Example |
|------------|-------|---------|
| Keyword | +0.15 | "bug" in prompt |
| Pattern (regex) | +0.20 | "not working" matches |
| Intent phrase (fuzzy) | +0.25 × similarity | "help debug" ≈ "help me debug" |
| Alias | +0.10 | "tdd" for test-driven-development |
| Confidence boost | varies | +0.25 for debugging (high priority) |

**Test Results**:
```
"Help me debug this error"     → systematic-debugging (1.0) ✓
"write tests for function"     → test-driven-development (1.0) ✓
"brainstorm new feature"       → brainstorming (0.95) ✓
"create a checkpoint"          → nav-marker (1.0) ✓
```

**Session Tracking**: Prevents duplicate skill injections per session using `~/.claude/data/session-skills.json`

**Synced to**: `universal/claude/hooks/` and `universal/claude/data/` in sync repo

#### 7. Implemented Phase 2: Haiku API Integration

**Files Created**:
- `~/.claude/engine/haiku-intent.js` - Claude Haiku client for semantic intent
- `~/.claude/hooks/skill-activator-v2.js` - Enhanced hook with AI fallback

**Priority Chain**:
```
User Prompt → Check Cache → Try Haiku API → Keyword Fallback → Return Results
```

**Haiku API Features**:
- Model: `claude-3-5-haiku-20241022`
- Cost: ~$0.25/1M input tokens (~$1-2/month at 100 prompts/day)
- Latency: ~200ms first call, <10ms cached
- Automatic fallback to keywords if API unavailable

**Cache System**:
- MD5 hash of prompt as key
- 60-minute TTL with auto-cleanup
- ~95% cache hit rate for repeated patterns

#### 8. Implemented Phase 3: Terminal Auto-Completion

**Files Created**:
- `~/.claude/engine/completion-engine.js` - Multi-source aggregator
- `~/.claude/shell/ClaudeComplete.psm1` - PowerShell module
- `~/.claude/shell/claude-complete.sh` - Bash/Zsh functions

**Completion Sources (4)**:
| Source | Count | Example |
|--------|-------|---------|
| Skills | 34 | /systematic-debugging, /brainstorming |
| Plugins | 3 | superpowers, episodic-memory |
| MCP Tools | 6 | beeper:search, chrome:navigate |
| History | tracked | Recently used commands |

**Ranking Algorithm**:
- Name match (prefix/contains/fuzzy): 50% weight
- Alias match: 30% weight
- Keyword match: 20% weight
- Recency boost: +0.15 (<1hr), +0.10 (<24hr), +0.05 (<1wk)
- Frequency boost: +0.02 per use (max +0.10)

**Usage**:
```powershell
# PowerShell (add to $PROFILE)
Import-Module "$HOME\.claude\shell\ClaudeComplete.psm1"
claude /deb<TAB>  # → /systematic-debugging
```
```bash
# Bash/Zsh (add to .bashrc/.zshrc)
source ~/.claude/shell/claude-complete.sh
claude /nav<TAB>  # → nav-init, nav-start, etc.
```

**Test Results**:
```
"debug" → /systematic-debugging (0.90)
"brain" → /brainstorming (0.97)
"nav"   → /nav-init (0.91), /nav-start, /nav-sync...
"sync"  → /nav-sync (0.90)
```

---

### 2026-01-23: Machine Sync Auto-Categorization System

**Session Goal**: Build comprehensive AI-driven auto-categorization for multi-machine ecosystem

**What We Accomplished**:

#### 1. Designed 3-Layer Architecture
- **Claude AI Layer**: Intelligent categorization decisions
- **Directory Structure Layer**: Physical organization
- **Git Conventions Layer**: Searchable commit history with tags

#### 2. Created Machine Registry
- **Location**: `machines/registry.yaml`
- **Purpose**: Single source of truth for all machines
- **Contains**: Hardware specs, hostnames, platforms, status

#### 3. Built Background Sync Daemons
- **Windows**: PowerShell with FileSystemWatcher + Task Scheduler
- **Linux**: Bash with inotifywait + systemd user service
- **Features**: Debouncing, auto-categorization, push/pull sync

#### 4. One-Command Bootstrap
- `bootstrap.ps1` for Windows
- `bootstrap.sh` for Linux
- Auto-detects hardware, registers machine, installs daemon

#### 5. Migrated Legacy Structure
- `omarchy/machines/` → `machines/`
- `omarchy/universal/` → `platform/linux/omarchy/`
- Fixed broken symlinks

**Key Learnings**:
- FileSystemWatcher in PowerShell for real-time file monitoring
- `$pid` is reserved in PowerShell (use `$daemonPid` instead)
- inotifywait for Linux file watching
- Git commit tags enable powerful `git log --grep` searches

**Files Created**:
- `machines/registry.yaml` - Machine ecosystem definition
- `machines/dell-g15/machine.yaml` - Hardware specs
- `platform/windows/scripts/sync-daemon.ps1` - Windows daemon
- `platform/linux/scripts/sync-daemon.sh` - Linux daemon
- `bootstrap.ps1` and `bootstrap.sh` - Setup scripts
- `docs/plans/2026-01-23-machine-sync-auto-categorization-design.md`

---

### 2026-01-21: Claude in Chrome Extension Troubleshooting & Bug Report

**Session Goal**: Fix "Chrome extension is not detected" warning at Claude Code startup

**What We Accomplished**:

#### 1. Fixed Extension Detection Cache
- **Problem**: Claude Code showed "Chrome extension is not detected" every startup
- **Root Cause**: Stale `cachedChromeExtensionInstalled: false` in `~/.claude.json`
- **Fix**: Changed to `cachedChromeExtensionInstalled: true`
- **Why it happens**: Claude Code caches detection to speed startup; cache becomes stale after updates

#### 2. Discovered & Reported Navigate Tool Bug
- **Problem**: `mcp__claude-in-chrome__navigate` corrupts special URL schemes
- **Example**: `chrome://extensions` becomes `https://chrome//extensions` (malformed)
- **Also affected**: `about:blank` returns "Invalid URL" error
- **Root Cause**: Tool prepends `https://` without recognizing `chrome://`, `about://`, etc.
- **Bug Report**: https://github.com/anthropics/claude-code/issues/19911

#### 3. Documented Multi-Browser Consideration
- Extension installed ONLY in Chrome Canary
- Native messaging hosts configured in ALL browsers (Chrome, Canary, Chromium)
- This mismatch can cause detection failures

#### 4. Created Comprehensive Documentation
- **Location**: `learnings/chrome-extension-troubleshooting.md`
- **Content**: CLI flags, key settings, native messaging setup, diagnostic commands
- **Also in**: `~/repos/robertogogoni/notes/claude-code/` (personal repo)

**Key Learnings**:
- `--chrome` / `--no-chrome` CLI flags control integration
- `~/.claude.json` contains critical cache values
- Native host at `~/.claude/chrome/chrome-native-host`
- Extension ID: `fcoeoabgfenejglbffodgkkbkcdhcgfn`

**Resources**:
- [Bug #19911](https://github.com/anthropics/claude-code/issues/19911) - Navigate URL corruption
- [Chrome Extension Troubleshooting](learnings/chrome-extension-troubleshooting.md)

---

### 2026-01-21: Self-Hosted GitHub Profile Widgets (Vercel)

**Session Goal**: Set up self-hosted GitHub stats widgets to include private repository data

**What We Accomplished**:

#### 1. Deployed github-readme-stats to Vercel
- **URL**: `github-readme-stats-zeta-blush-29.vercel.app`
- **PAT**: Added as `PAT_1` environment variable
- **Benefit**: Stats now include private repo commits, stars, PRs

#### 2. Deployed github-readme-activity-graph to Vercel
- **URL**: `github-readme-activity-graph-sage.vercel.app`
- **PAT**: Added as `TOKEN` environment variable
- **Benefit**: Activity graph shows all contributions including private

#### 3. Discovered PHP Limitation for Streak Stats
- `github-readme-streak-stats` is a **PHP/Heroku project**
- Not compatible with Vercel (Node.js serverless only)
- **Solution**: Use public instance `streak-stats.demolab.com` (streak data is public anyway)

#### 4. Updated GitHub Profile README
- All widgets use `tokyonight` theme for consistency
- Added streak stats and activity graph widgets
- Both self-hosted (private data) and public (streak) widgets

#### 5. Updated Sync Repo Status
- Windows Desktop: `📋 Pending` → `✅ Configured`

**Vercel Deployment Process**:
```bash
# Clone, deploy, add PAT, redeploy
git clone --depth 1 https://github.com/anuraghazra/github-readme-stats.git
cd github-readme-stats
vercel --yes
printf "ghp_TOKEN" | vercel env add PAT_1 production
vercel --prod --yes
```

**Key Learnings**:
- Vercel CLI device auth flow for Wayland: `vercel login` → copy URL manually
- PHP projects (Heroku buildpacks) won't work on Vercel
- PAT needs `repo` + `user` scopes for private data
- Different projects use different env var names (`PAT_1` vs `TOKEN`)

**Resources**:
- [Vercel GitHub Widgets Guide](learnings/vercel-github-widgets.md)
- Personal profile: https://github.com/robertogogoni

---

### 2026-01-17: Personal Communication System & Connections Registry

**Session Goal**: Help elaborate a personal message and establish a system for future interactions

**What We Accomplished**:

#### 1. Elaborated Response for Daiana (WhatsApp)
- **Context**: She sent a vulnerable, detailed message about herself
- **Challenge**: Match her depth, tone, and communication style
- **Process**:
  - Analyzed her message style (fluido, sem bullets, parágrafos conectados)
  - Collected personal information through focused questions
  - Used MyHeritage DNA traits (via Chrome integration) for personality insights
  - Rewrote multiple times based on feedback
- **Key Learnings**:
  - Espelhar o estilo do interlocutor
  - Evitar estruturas artificiais (bullets, headers)
  - Usar conectores naturais entre assuntos
  - Reformular dados de testes como autopercepção

#### 2. Created Connections Registry
- **Location**: `connections/`
- **Purpose**: Track people, context, and communication preferences
- **Files Created**:
  - `connections/README.md` - Guidelines and index
  - `connections/daiana.md` - First connection profile

#### 3. Documented Communication Patterns
- **Location**: `learnings/personal-communication.md`
- **Content**: Process for helping with personal messages, anti-patterns, quality checklist

---

### 2026-01-17: "Jarvis Mode" - Full Autonomy Permission Setup

**Session Goal**: Eliminate permission prompts for a fully autonomous Claude Code experience
**Machine**: Windows Desktop

**Problem**: Claude Code prompts for permission on every file edit, bash command, etc. Too much friction for power users.

**Solutions Explored**:

| Approach | Command/Config | Safety Level | Platform |
|----------|----------------|--------------|----------|
| CLI Flag | `claude --dangerously-skip-permissions` | ⚠️ Full access | 🔄 All |
| Docker Container | `claude-code-container` | ✅ Sandboxed | 🔄 All |
| Settings Permissions | Broad `"Bash"` in settings.json | ⚠️ Medium | 🔄 All |
| Wildcard Permissions | `Bash(npm *)`, `Bash(git *)` (v2.1.0+) | ⚠️ Scoped | 🔄 All |
| PowerShell Alias | `jarvis` function + `j` alias | N/A | 🪟 Windows |
| Bash/Zsh Alias | `alias jarvis=...` | N/A | 🐧 Linux/macOS |

**Platform Legend**: 🪟 Windows | 🐧 Linux/macOS | 🔄 Cross-platform

**Chosen Solution (Windows)**: CLI flag with PowerShell alias

**Implementation** 🪟:
```powershell
# Added to both PowerShell profiles:
# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
# ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1

function jarvis { claude --dangerously-skip-permissions @args }
Set-Alias -Name j -Value jarvis
```

**Equivalent for Linux/macOS** 🐧:
```bash
# Add to ~/.bashrc or ~/.zshrc
alias jarvis='claude --dangerously-skip-permissions'
alias j='jarvis'
```

**Usage** 🔄:
```bash
jarvis              # Launch with full autonomy
j                   # Short alias
j --resume          # Resume with autonomy (args pass through)
```

**Key Learnings**:
- 🪟 `@args` in PowerShell is "splatting" - passes all arguments through to the underlying command
- 🐧 Bash aliases are simpler: just string substitution
- 🔄 `--dangerously-skip-permissions` is officially nicknamed "yolo mode"
- 🔄 Docker containers (claude-code-container, run-claude-docker) provide safe sandboxed yolo mode
- 🔄 Claude Code 2.1.0+ supports wildcard bash permissions: `Bash(npm *)`

**Resources**:
- [Superpowers Plugin](https://github.com/obra/superpowers) - Skills framework
- [Superpowers Marketplace](https://github.com/obra/superpowers-marketplace) - Docker containers & tools

---

### 2026-01-17: Comprehensive AI History Extraction & Cross-Machine Sync

**Session Goal**: Set up Claude Code on Windows with everything synced across all machines

**What We Accomplished**:

#### 1. Warp Terminal AI History Extraction
- **Problem**: AI queries and agent conversations stored in SQLite, not accessible
- **Location**: `~/.local/state/warp-terminal/warp.sqlite` and `warp-terminal-preview/`
- **Solution**: Extracted to CSV/JSON for human-readable, searchable format

```bash
# Extraction commands used
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv

sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  "SELECT * FROM ai_agent_conversations;" > warp-ai/agents/all-conversations.json
```

**Results**:
| Source | AI Queries | Agent Conversations |
|--------|------------|---------------------|
| Warp Terminal | 570 | 13 |
| Warp Preview | 1,138 | 36 |
| **Total** | **1,708** | **49** |

**Key Learning**: Warp stores AI history in SQLite tables `ai_queries` and `ai_agent_conversations`. The `input` field in queries is JSON containing query text, context, and attachments.

---

#### 2. Antigravity/Gemini Brain Recovery
- **Problem**: Google Antigravity IDE AI task files scattered and potentially lost
- **Location**: `~/.gemini/antigravity/brain/`
- **Solution**: Copied 15 complete task sessions with all .md files

**Session Types Recovered**:
- Debug Critical Functionality
- Install Warp Terminal
- Keyboard Layout Configuration
- Trackpad/Mouse Optimization
- Install Stremio
- System optimization tasks
- And 9 more sessions

**File Types per Session**:
- `task.md` - Task definition and requirements
- `implementation_plan.md` - Step-by-step implementation
- `walkthrough.md` - Guided walkthrough
- `verification_plan.md` - Testing and verification steps

**Key Learning**: Gemini stores task sessions by UUID in `~/.gemini/<app>/brain/`. Each session is self-contained with markdown files for each phase.

---

#### 3. Git LFS for Large Files
- **Problem**: Episodic memory archive is 128MB, too large for regular git
- **Solution**: Configured Git LFS to track `.jsonl` files

```bash
# Setup
git lfs install
git lfs track "*.jsonl"
git add .gitattributes
```

**Key Learning**: Git LFS stores large files as pointers in the repo, with actual content in LFS storage. Cloning is fast; content downloads on demand.

---

#### 4. Comprehensive Documentation
- **Created**: Polished README.md with badges, tables, collapsible sections
- **Created**: Windows setup guide (`docs/WINDOWS-SETUP.md`)
- **Created**: Warp AI index (`warp-ai/INDEX.md`)
- **Created**: Antigravity history index (`antigravity-history/INDEX.md`)

---

### 2026-01-06: Fixed Invalid Settings

**Problem**: Claude Code showed "invalid settings" error
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/settings.local.json`

**Issue Found**:
Lines 88-107 had invalid Bash permission entries trying to break down shell scripts:
```json
"Bash(for file in ...)",
"Bash(do)",
"Bash(if grep -q ...)",
// etc - shell syntax broken into individual lines
```

**Solution**:
Removed invalid shell syntax entries and replaced with proper command patterns:
```json
"Bash(sqlite3:*)",
"Bash(sudo sh:*)",
"Bash(lsattr:*)",
"Bash([ -d:*)",
"Bash([ -f:*)"
```

**Key Learning**: Bash permissions use prefix matching on complete commands, not individual shell syntax keywords.

---

### 2026-01-06: Simplified Permissions to Full Access

**Problem**: Too many specific permission entries making maintenance difficult
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/settings.local.json`

**Solution**:
Replaced 93 specific permission entries with broad tool access:
```json
{
  "permissions": {
    "allow": [
      "Bash",
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "Skill",
      "LSP",
      "NotebookEdit",
      "mcp__beeper__search_chats",
      "mcp__claude-in-chrome__*"
    ]
  }
}
```

**Apply to other machines**: Copy this simplified config to all machines.

---

### 2026-01-06: Created Tool Discovery Skill

**Problem**: Needed proactive tool suggestions and auto-search for missing tools
**Machine**: MacBook Air (Main)
**Location**: `~/.claude/skills/tool-discovery/SKILL.md`

**Features**:
- Auto-activates when asking "what tools are available?"
- Lists all installed MCP servers and tools
- Searches GitHub/npm/PyPI for new tools when needed
- Provides installation guidance

**Trigger phrases**:
- "what tools are available?"
- "is there a tool for..."
- "can Claude do..."
- "how can I..."

---

### 2026-01-06: Chrome Extension Connection

**Problem**: Chrome extension installed but not connecting to Claude Code
**Machine**: MacBook Air (Main)
**Status**: ⚠️ Pending installation

**Solution**:
1. Visit https://claude.ai/chrome in Chrome/Chrome Canary
2. Install the Claude extension
3. Extension auto-connects to running MCP server
4. Tools become available immediately (permissions already configured)

---

## Data Sources & Locations

### AI History Sources

| Tool | Data Location | Format | Extraction Method |
|------|---------------|--------|-------------------|
| **Claude Code** | `~/.config/superpowers/conversation-archive/` | JSONL | Direct copy (Git LFS) |
| **Warp Terminal** | `~/.local/state/warp-terminal/warp.sqlite` | SQLite | SQL query to CSV/JSON |
| **Warp Preview** | `~/.local/state/warp-terminal-preview/warp.sqlite` | SQLite | SQL query to CSV/JSON |
| **Antigravity/Gemini** | `~/.gemini/antigravity/brain/` | Markdown | Direct copy |
| **Cursor** | `~/.config/Cursor/` | Various | Minimal AI data found |
| **Zed** | `~/.local/share/zed/db/` | SQLite | No AI tables found |

### Configuration Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Claude settings | `~/.claude/settings.json` | User-level settings |
| Claude skills | `~/.claude/skills/` | Custom skill definitions |
| Project settings | `.claude/settings.json` | Project-specific overrides |
| MCP servers | `~/.claude.json` | MCP server configurations |

---

## Machine-Specific Notes

### MacBook Air (Main)

| Property | Value |
|----------|-------|
| **Hardware** | Apple MacBookAir7,2 (Early 2015) |
| **CPU** | Intel Core i5-5250U @ 1.60GHz (2 cores, 4 threads) |
| **Memory** | 8GB RAM |
| **Disk** | 111GB SSD (53GB used) |
| **OS** | Arch Linux (rolling), Kernel 6.18.x |
| **Hostname** | macbook-air |
| **User** | rob |
| **Claude Version** | 2.0.76+ |

**Installed Components**:
- **MCP Servers**: Beeper, Claude in Chrome, Episodic Memory, Playwright
- **Plugins**: superpowers, episodic-memory
- **Custom Skills**: tool-discovery, beeper-chat, omarchy
- **Dev Tools**: Git 2.52+, Node.js v25+, npm 11+

### Linux Notebook 2
- **Status**: To be configured
- **Setup Guide**: Follow `docs/WINDOWS-SETUP.md` (Linux sections)

### Windows Desktop
- **Status**: ✅ Configured (2026-01-17)
- **Setup Guide**: `docs/WINDOWS-SETUP.md`
- **Jarvis Mode**: `jarvis` or `j` aliases configured in PowerShell
- **User**: rober

---

## Repository Statistics

| Category | Count | Size |
|----------|-------|------|
| AI Queries (Warp) | 1,708 | ~2MB |
| Agent Conversations | 49 | ~1MB |
| Gemini Sessions | 15 | ~500KB |
| Episodic Memory | Full archive | ~128MB |
| Documentation Files | 25+ | ~300KB |
| Custom Skills | 4 | ~50KB |
| **Total** | **599+ files** | **~308MB** |

---

## Cross-Machine Workflows

### Workflow 1: Syncing Changes
```bash
# After making changes on any machine
cd ~/claude-cross-machine-sync
git add .
git commit -m "Updated: <description>"
git push

# On other machines
git pull
```

### Workflow 2: Finding Past Solutions
```bash
# Natural language (Claude searches episodic memory)
"What was the solution to X?"
"How did I configure Y?"

# Direct command
/episodic-memory:search-conversations "keyword"

# Search Warp history
grep -i "keyword" warp-ai/queries/all-queries.csv
```

### Workflow 3: Adding New Machine
1. Install Git LFS: `git lfs install`
2. Clone: `git clone https://github.com/robertogogoni/claude-cross-machine-sync.git`
3. Copy settings: `cp .claude/settings.json ~/.claude/`
4. Copy skills: `cp -r skills/* ~/.claude/skills/`
5. Install plugins via Claude Code

### Workflow 4: Personal Communication Assistance
1. Consultar `connections/<pessoa>.md` para contexto
2. Usar Beeper MCP para ler mensagens recentes
3. Analisar estilo de comunicação do interlocutor
4. Coletar informações através de perguntas focadas (uma por vez)
5. Elaborar resposta espelhando o estilo do interlocutor
6. Revisar: sem bullets, texto fluido, transições naturais
7. Atualizar arquivo da conexão após interação

### Workflow 5: Extracting AI History (Future Updates)
```bash
# Warp Terminal
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv

# Commit new data
git add warp-ai/
git commit -m "Updated Warp AI history"
git push
```

---

## File Structure

```
~/claude-cross-machine-sync/
├── CLAUDE.md                    # This file (project memory)
├── README.md                    # Repository documentation
├── .gitattributes               # Git LFS configuration
├── bootstrap.ps1                # Windows one-command setup
├── bootstrap.sh                 # Linux one-command setup
│
├── machines/                    # Machine-specific configurations
│   ├── registry.yaml            # Source of truth for all machines
│   ├── dell-g15/                # Windows gaming laptop
│   │   ├── machine.yaml         # Hardware specs
│   │   ├── claude/              # Claude Code settings
│   │   └── shell/               # PowerShell configs
│   ├── macbook-air/             # Linux laptop
│   │   ├── machine.yaml
│   │   ├── claude/
│   │   └── hypr/                # Hyprland configs
│   └── samsung-laptop/          # Linux laptop (pending)
│
├── platform/                    # Platform-specific (OS level)
│   ├── windows/
│   │   └── scripts/
│   │       └── sync-daemon.ps1  # Windows sync daemon
│   └── linux/
│       ├── scripts/
│       │   └── sync-daemon.sh   # Linux sync daemon
│       └── omarchy/             # Universal Hyprland configs
│
├── universal/                   # Cross-platform configs
│   └── claude/
│       └── settings.json        # Shared Claude settings
│
├── .claude/                     # Claude Code configuration
│   ├── settings.json            # Project settings
│   └── machine-info.json        # Machine identification
│
├── skills/                      # Custom Claude Code skills
│   ├── tool-discovery/          # Auto-discover tools
│   ├── beeper-chat/             # Beeper messaging
│   └── omarchy-skill.md         # Linux desktop config
│
├── episodic-memory/             # Conversation archive (Git LFS)
│   ├── -home-rob/               # JSONL conversation files
│   └── conversation-index/      # Search index
│
├── warp-ai/                     # Warp Terminal AI history
│   ├── queries/                 # AI queries (CSV)
│   ├── agents/                  # Agent conversations (JSON)
│   └── INDEX.md                 # Documentation
│
├── learnings/                   # AI-generated knowledge
│   ├── machine-sync-patterns.md # Sync daemon & categorization
│   ├── cross-machine-sync.md    # General sync patterns
│   ├── bash-patterns.md         # Shell patterns
│   ├── claude-code-permissions.md # Permission modes
│   └── ...                      # Other learnings
│
├── connections/                 # Personal connections registry
│   └── <person>.md              # Individual profiles
│
└── docs/                        # Documentation
    ├── WINDOWS-SETUP.md         # Windows guide
    ├── plans/                   # Design documents
    │   └── 2026-01-23-machine-sync-auto-categorization-design.md
    └── ...                      # Other docs
```

---

## Troubleshooting

### Git LFS Issues
```bash
# Verify LFS is installed
git lfs version

# Check tracked files
git lfs ls-files

# Pull LFS content
git lfs pull
```

### Settings Not Applying
- Check `.claude/settings.json` exists in project root
- Restart Claude Code session
- Run `/config` to see loaded settings

### Episodic Memory Not Working
- Verify plugin: `/plugin list`
- Check archive exists in `episodic-memory/`
- Try specific keywords

### Warp Data Not Updating
```bash
# Re-extract from SQLite
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > warp-ai/queries/all-queries.csv
```

---

## Checklist: New Machine Setup

**Automated (recommended)**:
```bash
# Windows
.\bootstrap.ps1

# Linux
./bootstrap.sh
```

**Manual Setup**:
- [ ] Install Git and Git LFS
- [ ] Clone: `git clone https://github.com/robertogogoni/claude-cross-machine-sync.git`
- [ ] Run bootstrap script (auto-detects hardware)
- [ ] Verify daemon running: `sync-daemon.ps1 -Mode Status` or `sync-daemon.sh --status`
- [ ] Install Claude Code plugins
- [ ] Test with a small config change (should auto-sync)

---

## Resources

- **Repository**: https://github.com/robertogogoni/claude-cross-machine-sync
- **Claude Code Docs**: https://docs.anthropic.com/claude-code
- **Superpowers Plugin**: https://github.com/obra/superpowers
- **Git LFS**: https://git-lfs.github.com/

---

*This file is automatically loaded by Claude Code. Update it whenever you discover new solutions!*

*Last session: 2026-01-23 - Machine Sync Auto-Categorization System v2.0*
