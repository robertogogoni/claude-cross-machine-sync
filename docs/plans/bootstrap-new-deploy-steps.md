# Bootstrap New Deploy Steps

**Design Document**
**Date**: 2026-03-18
**Status**: Draft - Pending Manual Review
**Author**: Claude Code + Roberto Gogoni

---

## Overview

The current `bootstrap.sh` handles Steps 0-6: pre-flight validation, hardware detection, machine registry, machine directory setup, sync daemon installation, config deployment (settings.json + settings.local.json + omarchy/hypr), and git commit/push.

This document specifies **Steps 5a through 5i** -- new deploy steps to be inserted into `bootstrap.sh` between the existing Step 5 (Deploy Configs) and Step 6 (Commit and Push). These steps deploy the full Claude Code ecosystem: skills, agents, commands, scripts, machine detection, memory files, MCP servers, platform scripts, and Claude Desktop configuration.

**Important:** Do NOT modify `bootstrap.sh` directly from this document. It is complex, uses sourced library modules (`lib/validator.sh`, `lib/rollback.sh`), and supports `--dry-run` and `--rollback` modes that every new step must integrate with.

---

## Conventions Used in All Steps

Every step below follows the same patterns already established in `bootstrap.sh`:

- **Logging**: Use `step()`, `success()`, `warn()`, `info()`, `error()` functions
- **Dry-run**: Every destructive operation must be wrapped with `if dry_run "description"; then : ; else ... fi`
- **Rollback**: Snapshot is created before Step 0; all steps are covered by the existing `create_snapshot`/`rollback_snapshot` mechanism
- **Variables available**: `$REPO_DIR`, `$MACHINE_DIR`, `$MACHINE_NAME`, `$HOME`, `$CLAUDE_DIR` (set to `$HOME/.claude`), `$DRY_RUN`

---

## Step 5a: Deploy Skills

### Purpose
Copy skill definitions from the repo to `~/.claude/skills/` and create the omarchy skill symlink on Linux+Omarchy systems.

### Source Files
```
universal/claude/skills/
  debugging/SKILL.md
  code-review/SKILL.md
  testing/SKILL.md
```

### Target
```
~/.claude/skills/
  debugging/SKILL.md
  code-review/SKILL.md
  testing/SKILL.md
  omarchy -> ~/.local/share/omarchy/default/omarchy-skill  (symlink, Linux+Omarchy only)
```

### Preconditions
- `$CLAUDE_DIR` exists (guaranteed by existing Step 5)
- `$REPO_DIR/universal/claude/skills/` directory exists and contains at least one subdirectory

### Commands
```bash
step "Deploying skills..."

SKILLS_SRC="$REPO_DIR/universal/claude/skills"
SKILLS_DST="$CLAUDE_DIR/skills"

if [ -d "$SKILLS_SRC" ]; then
    if dry_run "Copy $SKILLS_SRC/* -> $SKILLS_DST/"; then
        :
    else
        mkdir -p "$SKILLS_DST"
        cp -r "$SKILLS_SRC/"* "$SKILLS_DST/"
    fi
    success "Deployed skills: $(ls -1 "$SKILLS_SRC" | tr '\n' ' ')"

    # Create omarchy symlink on Linux with omarchy installed
    OMARCHY_SKILL="$HOME/.local/share/omarchy/default/omarchy-skill"
    if [ "$(uname)" = "Linux" ] && [ -d "$OMARCHY_SKILL" ]; then
        if dry_run "Symlink $SKILLS_DST/omarchy -> $OMARCHY_SKILL"; then
            :
        else
            ln -sfn "$OMARCHY_SKILL" "$SKILLS_DST/omarchy"
        fi
        success "Created omarchy skill symlink"
    else
        info "Omarchy not detected, skipping symlink"
    fi
else
    warn "No skills directory found at $SKILLS_SRC"
fi
```

### Validation Check
```bash
# All expected skill directories exist
for skill in debugging code-review testing; do
    [ -f "$SKILLS_DST/$skill/SKILL.md" ] || warn "Missing skill: $skill"
done
```

### Rollback
Covered by the existing snapshot mechanism. The rollback would restore `~/.claude/skills/` from the pre-bootstrap snapshot.

---

## Step 5b: Deploy Agents

### Purpose
Copy subagent definitions to `~/.claude/agents/`.

### Source Files
```
universal/claude/agents/
  code-reviewer.md
  debugger.md
  planner.md
  test-writer.md
```

### Target
```
~/.claude/agents/
  code-reviewer.md
  debugger.md
  planner.md
  test-writer.md
```

### Preconditions
- `$CLAUDE_DIR` exists
- `$REPO_DIR/universal/claude/agents/` contains `.md` files

### Commands
```bash
step "Deploying agents..."

AGENTS_SRC="$REPO_DIR/universal/claude/agents"
AGENTS_DST="$CLAUDE_DIR/agents"

if [ -d "$AGENTS_SRC" ]; then
    if dry_run "Copy $AGENTS_SRC/* -> $AGENTS_DST/"; then
        :
    else
        mkdir -p "$AGENTS_DST"
        cp -r "$AGENTS_SRC/"* "$AGENTS_DST/"
    fi
    success "Deployed agents: $(ls -1 "$AGENTS_SRC" | tr '\n' ' ')"
else
    warn "No agents directory found at $AGENTS_SRC"
fi
```

### Validation Check
```bash
for agent in code-reviewer debugger planner test-writer; do
    [ -f "$AGENTS_DST/$agent.md" ] || warn "Missing agent: $agent"
done
```

### Rollback
Snapshot-based. Restores `~/.claude/agents/` from snapshot.

---

## Step 5c: Deploy Commands

### Purpose
Copy custom slash command definitions to `~/.claude/commands/`.

### Source Files
```
universal/claude/commands/
  analyze.md
  eureka.md
  explain.md
  refactor.md
  security-scan.md
  think-harder.md
```

### Target
```
~/.claude/commands/
  analyze.md
  eureka.md
  explain.md
  refactor.md
  security-scan.md
  think-harder.md
```

### Preconditions
- `$CLAUDE_DIR` exists
- `$REPO_DIR/universal/claude/commands/` contains `.md` files

### Commands
```bash
step "Deploying commands..."

COMMANDS_SRC="$REPO_DIR/universal/claude/commands"
COMMANDS_DST="$CLAUDE_DIR/commands"

if [ -d "$COMMANDS_SRC" ]; then
    if dry_run "Copy $COMMANDS_SRC/* -> $COMMANDS_DST/"; then
        :
    else
        mkdir -p "$COMMANDS_DST"
        cp -r "$COMMANDS_SRC/"* "$COMMANDS_DST/"
    fi
    success "Deployed commands: $(ls -1 "$COMMANDS_SRC" | tr '\n' ' ')"
else
    warn "No commands directory found at $COMMANDS_SRC"
fi
```

### Validation Check
```bash
for cmd in analyze eureka explain refactor security-scan think-harder; do
    [ -f "$COMMANDS_DST/$cmd.md" ] || warn "Missing command: $cmd"
done
```

### Rollback
Snapshot-based. Restores `~/.claude/commands/` from snapshot.

---

## Step 5d: Deploy Scripts

### Purpose
Copy utility scripts to `~/.claude/scripts/` and ensure shell scripts are executable.

### Source Files
```
universal/claude/scripts/
  claude-memory-sync      (executable script)
  log-bash-command.sh     (hook helper)
  audit/
    audit-summary.sh
    validate-configs.sh
    security-check.sh
```

### Target
```
~/.claude/scripts/
  claude-memory-sync
  log-bash-command.sh
  audit/
    audit-summary.sh
    validate-configs.sh
    security-check.sh
```

### Preconditions
- `$CLAUDE_DIR` exists
- `$REPO_DIR/universal/claude/scripts/` exists

### Commands
```bash
step "Deploying scripts..."

SCRIPTS_SRC="$REPO_DIR/universal/claude/scripts"
SCRIPTS_DST="$CLAUDE_DIR/scripts"

if [ -d "$SCRIPTS_SRC" ]; then
    if dry_run "Copy $SCRIPTS_SRC/* -> $SCRIPTS_DST/ and chmod +x shell scripts"; then
        :
    else
        mkdir -p "$SCRIPTS_DST"
        cp -r "$SCRIPTS_SRC/"* "$SCRIPTS_DST/"

        # Make all .sh files and scripts without extension executable
        find "$SCRIPTS_DST" -type f \( -name "*.sh" -o ! -name "*.*" \) -exec chmod +x {} \;
    fi
    success "Deployed scripts"
else
    warn "No scripts directory found at $SCRIPTS_SRC"
fi
```

### Validation Check
```bash
[ -x "$SCRIPTS_DST/claude-memory-sync" ] || warn "claude-memory-sync not executable"
[ -x "$SCRIPTS_DST/log-bash-command.sh" ] || warn "log-bash-command.sh not executable"
[ -x "$SCRIPTS_DST/audit/security-check.sh" ] || warn "security-check.sh not executable"
```

### Rollback
Snapshot-based. Restores `~/.claude/scripts/` from snapshot.

---

## Step 5e: Deploy Machine Detection

### Purpose
Copy machine detection scripts to `~/.claude/machines/`.

### Source Files
```
universal/claude/machines/
  detect-machine.sh
  show-machine.sh
  README.md
  USAGE.md
```

### Target
```
~/.claude/machines/
  detect-machine.sh
  show-machine.sh
  README.md
  USAGE.md
```

### Preconditions
- `$CLAUDE_DIR` exists
- `$REPO_DIR/universal/claude/machines/` exists

### Commands
```bash
step "Deploying machine detection..."

MACHINES_SRC="$REPO_DIR/universal/claude/machines"
MACHINES_DST="$CLAUDE_DIR/machines"

if [ -d "$MACHINES_SRC" ]; then
    if dry_run "Copy $MACHINES_SRC/* -> $MACHINES_DST/ and chmod +x shell scripts"; then
        :
    else
        mkdir -p "$MACHINES_DST"
        cp -r "$MACHINES_SRC/"* "$MACHINES_DST/"
        chmod +x "$MACHINES_DST/"*.sh 2>/dev/null || true
    fi
    success "Deployed machine detection scripts"
else
    warn "No machines directory found at $MACHINES_SRC"
fi
```

### Validation Check
```bash
[ -x "$MACHINES_DST/detect-machine.sh" ] || warn "detect-machine.sh not executable"
[ -x "$MACHINES_DST/show-machine.sh" ] || warn "show-machine.sh not executable"
```

### Rollback
Snapshot-based. Restores `~/.claude/machines/` from snapshot.

---

## Step 5f: Deploy Memory Files

### Purpose
Merge memory files from three layers (universal, platform, machine-specific) and regenerate the `MEMORY.md` index. The layering order is:
1. `universal/claude/memory/` -- base memories shared across all machines
2. `platform/<os>/memory/` -- platform-specific memories (e.g., Linux package info)
3. `machines/<name>/memory/` -- machine-specific memories (e.g., hardware profile)

Later layers override earlier ones if files share the same name.

### Source Files
```
universal/claude/memory/
  feedback_action_oriented.md
  feedback_no_dashes.md
  project_beeper_community_org.md
  project_cortex_claude.md
  project_custom_instructions.md
  project_update_beeper.md
  reference_github_repos.md
  user_profile.md

platform/linux/memory/
  project_system_packages.md
  project_claude_desktop.md
  project_chrome_canary.md

machines/samsung-laptop/memory/
  feedback_protect_system_configs.md
  project_display_scaling.md
  project_mcp_servers.md
  user_machine_samsung.md
```

### Target
```
~/.claude/projects/-home-robthepirate/memory/
  (merged set of all .md files from the three layers)
  MEMORY.md  (auto-generated index)
```

### Preconditions
- `$CLAUDE_DIR` exists
- At least one of the three source directories contains `.md` files
- The target project directory path must be derived: `$CLAUDE_DIR/projects/-home-$(whoami)/memory/`

### Commands
```bash
step "Deploying memory files..."

# Determine target path (Claude Code project memory convention)
MEMORY_DST="$CLAUDE_DIR/projects/-home-$(whoami)/memory"

# Determine platform
PLATFORM="linux"
if [[ "$(uname -s)" == "MINGW"* ]] || [[ "$(uname -s)" == "MSYS"* ]]; then
    PLATFORM="windows"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    PLATFORM="macos"
fi

MEMORY_UNIVERSAL="$REPO_DIR/universal/claude/memory"
MEMORY_PLATFORM="$REPO_DIR/platform/$PLATFORM/memory"
MEMORY_MACHINE="$REPO_DIR/machines/$MACHINE_NAME/memory"

if dry_run "Merge memory from universal + platform/$PLATFORM + machines/$MACHINE_NAME -> $MEMORY_DST"; then
    [ -d "$MEMORY_UNIVERSAL" ] && info "  Layer 1 (universal): $(ls -1 "$MEMORY_UNIVERSAL" | wc -l) files"
    [ -d "$MEMORY_PLATFORM" ] && info "  Layer 2 (platform):  $(ls -1 "$MEMORY_PLATFORM" | wc -l) files"
    [ -d "$MEMORY_MACHINE" ] && info "  Layer 3 (machine):   $(ls -1 "$MEMORY_MACHINE" | wc -l) files"
else
    mkdir -p "$MEMORY_DST"

    # Layer 1: Universal (base)
    if [ -d "$MEMORY_UNIVERSAL" ]; then
        cp "$MEMORY_UNIVERSAL/"*.md "$MEMORY_DST/" 2>/dev/null || true
        info "Copied $(ls -1 "$MEMORY_UNIVERSAL/"*.md 2>/dev/null | wc -l) universal memory files"
    fi

    # Layer 2: Platform (overrides universal)
    if [ -d "$MEMORY_PLATFORM" ]; then
        cp "$MEMORY_PLATFORM/"*.md "$MEMORY_DST/" 2>/dev/null || true
        info "Copied $(ls -1 "$MEMORY_PLATFORM/"*.md 2>/dev/null | wc -l) platform memory files"
    fi

    # Layer 3: Machine-specific (overrides both)
    if [ -d "$MEMORY_MACHINE" ]; then
        cp "$MEMORY_MACHINE/"*.md "$MEMORY_DST/" 2>/dev/null || true
        info "Copied $(ls -1 "$MEMORY_MACHINE/"*.md 2>/dev/null | wc -l) machine memory files"
    fi

    # Regenerate MEMORY.md index
    MEMORY_INDEX="$MEMORY_DST/MEMORY.md"
    {
        echo "# Memory Index"
        echo ""

        # Group files by prefix category
        for category in user feedback project reference; do
            CATEGORY_TITLE=$(echo "$category" | sed 's/^./\U&/')
            FILES=$(ls "$MEMORY_DST/${category}_"*.md 2>/dev/null || true)
            if [ -n "$FILES" ]; then
                echo "## $CATEGORY_TITLE"
                for f in $FILES; do
                    basename_f=$(basename "$f")
                    # Extract first line as description (skip # prefix)
                    desc=$(head -1 "$f" | sed 's/^#* *//')
                    echo "- [$desc]($basename_f)"
                done
                echo ""
            fi
        done

        echo "# currentDate"
        echo "Today's date is $(date +%Y-%m-%d)."
    } > "$MEMORY_INDEX"
    info "Regenerated MEMORY.md index"
fi

success "Deployed memory files (3-layer merge)"
```

### Validation Check
```bash
[ -f "$MEMORY_DST/MEMORY.md" ] || warn "MEMORY.md index not generated"
TOTAL_FILES=$(ls -1 "$MEMORY_DST/"*.md 2>/dev/null | wc -l)
[ "$TOTAL_FILES" -gt 1 ] || warn "Expected multiple memory files, found $TOTAL_FILES"
info "Total memory files deployed: $TOTAL_FILES"
```

### Rollback
Snapshot-based. The snapshot should capture `~/.claude/projects/-home-*/memory/` before the merge.

**Note:** The `create_snapshot` function in `lib/rollback.sh` should be updated to include the projects memory directory in its backup list.

---

## Step 5g: Deploy MCP Servers

### Purpose
Install the custom `memory-sync` MCP server and register it with Claude Code CLI.

### Source Files
```
universal/claude/mcp-servers/memory-sync/
  server.cjs
```

### Target
```
~/.local/share/mcp-servers/memory-sync/
  server.cjs
```

### Preconditions
- `$REPO_DIR/universal/claude/mcp-servers/memory-sync/server.cjs` exists
- `node` is available on PATH (for the MCP server to run)
- `claude` CLI is available on PATH (for `claude mcp add`)

### Commands
```bash
step "Deploying MCP servers..."

MCP_SRC="$REPO_DIR/universal/claude/mcp-servers"
MCP_DST="$HOME/.local/share/mcp-servers"

if [ -d "$MCP_SRC/memory-sync" ]; then
    if dry_run "Copy $MCP_SRC/memory-sync -> $MCP_DST/memory-sync and register with claude mcp add"; then
        :
    else
        mkdir -p "$MCP_DST/memory-sync"
        cp "$MCP_SRC/memory-sync/server.cjs" "$MCP_DST/memory-sync/server.cjs"

        # Register with Claude Code CLI (idempotent -- overwrites if exists)
        if command -v claude &>/dev/null; then
            claude mcp add memory-sync \
                --transport stdio \
                -- node "$MCP_DST/memory-sync/server.cjs" 2>/dev/null || true
            success "Registered memory-sync MCP server with Claude Code"
        else
            warn "claude CLI not found, skipping MCP registration"
            info "Manual registration: claude mcp add memory-sync --transport stdio -- node $MCP_DST/memory-sync/server.cjs"
        fi
    fi
    success "Deployed memory-sync MCP server"
else
    warn "No memory-sync MCP server found at $MCP_SRC/memory-sync"
fi
```

### Validation Check
```bash
[ -f "$MCP_DST/memory-sync/server.cjs" ] || warn "memory-sync server.cjs not deployed"
# Verify registration (if claude is available)
if command -v claude &>/dev/null; then
    claude mcp list 2>/dev/null | grep -q "memory-sync" && success "memory-sync registered in Claude Code" || warn "memory-sync not found in claude mcp list"
fi
```

### Rollback
- Remove `~/.local/share/mcp-servers/memory-sync/`
- Run `claude mcp remove memory-sync` if the CLI is available

---

## Step 5h: Deploy Platform Scripts (Linux)

### Purpose
Install platform-specific scripts to `~/.local/bin/` and enable systemd user timers.

### Source Files
```
platform/linux/scripts/
  claude-desktop-update   (script for updating Claude Desktop AppImage)
  sync-daemon.sh          (the sync daemon, already handled in Step 4 but referenced here)

platform/linux/systemd/
  claude-desktop-update.service
  claude-desktop-update.timer
```

### Target
```
~/.local/bin/
  claude-desktop-update

~/.config/systemd/user/
  claude-desktop-update.service
  claude-desktop-update.timer
```

### Preconditions
- Platform is Linux (`uname -s` == "Linux")
- systemd is available (`systemctl --user` works)
- `~/.local/bin/` is on `$PATH` (standard on most Linux distros)

### Commands
```bash
if [ "$(uname -s)" = "Linux" ]; then
    step "Deploying platform scripts (Linux)..."

    PLATFORM_SCRIPTS="$REPO_DIR/platform/linux/scripts"
    PLATFORM_SYSTEMD="$REPO_DIR/platform/linux/systemd"

    # Deploy scripts to ~/.local/bin/
    if [ -d "$PLATFORM_SCRIPTS" ]; then
        if dry_run "Copy platform scripts to ~/.local/bin/ and chmod +x"; then
            :
        else
            mkdir -p "$HOME/.local/bin"

            # Copy all scripts except sync-daemon.sh (handled in Step 4)
            for script in "$PLATFORM_SCRIPTS"/*; do
                script_name=$(basename "$script")
                if [ "$script_name" != "sync-daemon.sh" ] && [ -f "$script" ]; then
                    cp "$script" "$HOME/.local/bin/$script_name"
                    chmod +x "$HOME/.local/bin/$script_name"
                    info "Installed $script_name"
                fi
            done
        fi
        success "Deployed platform scripts to ~/.local/bin/"
    fi

    # Deploy systemd units
    if [ -d "$PLATFORM_SYSTEMD" ]; then
        if dry_run "Copy systemd units and enable timers"; then
            :
        else
            SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
            mkdir -p "$SYSTEMD_USER_DIR"

            for unit in "$PLATFORM_SYSTEMD"/*; do
                unit_name=$(basename "$unit")
                cp "$unit" "$SYSTEMD_USER_DIR/$unit_name"
                info "Installed $unit_name"
            done

            # Reload and enable timers
            systemctl --user daemon-reload

            # Enable and start timer units (files ending in .timer)
            for timer in "$PLATFORM_SYSTEMD"/*.timer; do
                if [ -f "$timer" ]; then
                    timer_name=$(basename "$timer")
                    systemctl --user enable --now "$timer_name" 2>/dev/null || warn "Failed to enable $timer_name"
                    info "Enabled timer: $timer_name"
                fi
            done
        fi
        success "Deployed and enabled systemd timers"
    fi
else
    info "Skipping platform scripts (not Linux)"
fi
```

### Validation Check
```bash
# Verify scripts are installed and executable
[ -x "$HOME/.local/bin/claude-desktop-update" ] || warn "claude-desktop-update not installed"

# Verify systemd timers are active
if command -v systemctl &>/dev/null; then
    systemctl --user is-enabled claude-desktop-update.timer &>/dev/null && \
        success "claude-desktop-update.timer enabled" || \
        warn "claude-desktop-update.timer not enabled"
fi
```

### Rollback
- Remove scripts from `~/.local/bin/` (only the ones we installed, not all)
- `systemctl --user disable --now claude-desktop-update.timer`
- Remove unit files from `~/.config/systemd/user/`
- `systemctl --user daemon-reload`

---

## Step 5i: Deploy Claude Desktop Config

### Purpose
Generate the Claude Desktop configuration file from the template, replacing placeholder variables with actual values.

### Source Files
```
universal/claude/claude-desktop-config.template.json
```

### Target
```
~/.config/Claude/claude_desktop_config.json
```

### Template Variables
| Variable | Source | Example Value |
|----------|--------|---------------|
| `${HOME}` | `$HOME` env var | `/home/robthepirate` |
| `${BRAVE_API_KEY}` | `$BRAVE_API_KEY` env var or `~/.claude/.env` | `BSA...` |

### Preconditions
- Template file exists at `$REPO_DIR/universal/claude/claude-desktop-config.template.json`
- `jq` is available (for JSON validation; not strictly required but recommended)
- `BRAVE_API_KEY` is set in the environment or readable from `~/.claude/.env`

### Commands
```bash
step "Deploying Claude Desktop config..."

DESKTOP_TEMPLATE="$REPO_DIR/universal/claude/claude-desktop-config.template.json"
DESKTOP_TARGET_DIR="$HOME/.config/Claude"
DESKTOP_TARGET="$DESKTOP_TARGET_DIR/claude_desktop_config.json"

if [ -f "$DESKTOP_TEMPLATE" ]; then
    # Source BRAVE_API_KEY from .env if not already in environment
    if [ -z "$BRAVE_API_KEY" ] && [ -f "$HOME/.claude/.env" ]; then
        # shellcheck source=/dev/null
        source "$HOME/.claude/.env" 2>/dev/null || true
    fi

    if [ -z "$BRAVE_API_KEY" ]; then
        warn "BRAVE_API_KEY not set -- brave-search MCP server will not work"
        BRAVE_API_KEY="MISSING_API_KEY"
    fi

    if dry_run "Generate $DESKTOP_TARGET from template (replacing \${HOME} and \${BRAVE_API_KEY})"; then
        :
    else
        mkdir -p "$DESKTOP_TARGET_DIR"

        # Back up existing config
        if [ -f "$DESKTOP_TARGET" ]; then
            cp "$DESKTOP_TARGET" "${DESKTOP_TARGET}.bak.$(date +%Y%m%d%H%M%S)"
            info "Backed up existing config"
        fi

        # Replace template variables
        sed \
            -e "s|\${HOME}|$HOME|g" \
            -e "s|\${BRAVE_API_KEY}|$BRAVE_API_KEY|g" \
            "$DESKTOP_TEMPLATE" > "$DESKTOP_TARGET"

        # Validate JSON syntax
        if command -v jq &>/dev/null; then
            if jq . "$DESKTOP_TARGET" >/dev/null 2>&1; then
                success "Generated valid Claude Desktop config"
            else
                error "Generated config is invalid JSON -- restoring backup"
                # Restore backup (error() calls exit, so this line would need
                # to be placed before the error call in actual implementation)
            fi
        else
            success "Generated Claude Desktop config (jq not available for validation)"
        fi
    fi
else
    warn "No desktop config template found at $DESKTOP_TEMPLATE"
fi
```

### Validation Check
```bash
[ -f "$DESKTOP_TARGET" ] || warn "Claude Desktop config not generated"
if command -v jq &>/dev/null && [ -f "$DESKTOP_TARGET" ]; then
    SERVER_COUNT=$(jq '.mcpServers | keys | length' "$DESKTOP_TARGET" 2>/dev/null)
    success "Claude Desktop config has $SERVER_COUNT MCP servers defined"
fi
```

### Rollback
- Restore from `claude_desktop_config.json.bak.*` backup created during deploy
- If no backup exists, remove the generated file

---

## Integration Notes

### Insertion Point in bootstrap.sh

All new steps should be inserted **after** the existing Step 5 block (line ~435, after the omarchy/hypr config deployment) and **before** Step 6 (line ~437, "Committing registration...").

The existing Step 6 (git commit/push) should be updated to also `git add` the new files:
```bash
git add machines/ universal/ platform/
```

### Step 6 Commit Message Update

The commit message in Step 6 should reflect the expanded deploy:
```
[machine:$MACHINE_NAME] Bootstrap: $HOSTNAME

Hardware: $VENDOR $MODEL
OS: $OS_NAME
Desktop: $DESKTOP
Deployed: settings, skills, agents, commands, scripts, machines, memory, MCP, desktop config
```

### New --skip Flags to Consider

For debugging and partial deploys:
- `--skip-skills` -- Skip Step 5a
- `--skip-agents` -- Skip Step 5b
- `--skip-commands` -- Skip Step 5c
- `--skip-scripts` -- Skip Step 5d
- `--skip-memory` -- Skip Step 5f
- `--skip-mcp` -- Skip Step 5g
- `--skip-desktop-config` -- Skip Step 5i
- `--skip-platform-scripts` -- Skip Step 5h

Or a single `--config-only` flag to only deploy settings.json (current behavior).

### Dependencies Between Steps

```
Step 5  (settings.json)     -- no dependencies, existing
Step 5a (skills)            -- no dependencies
Step 5b (agents)            -- no dependencies
Step 5c (commands)          -- no dependencies
Step 5d (scripts)           -- no dependencies
Step 5e (machine detection) -- no dependencies
Step 5f (memory)            -- depends on $MACHINE_NAME from Step 1
Step 5g (MCP servers)       -- no dependencies
Step 5h (platform scripts)  -- Linux only; no dependencies
Step 5i (desktop config)    -- depends on BRAVE_API_KEY from env/.env
```

Steps 5a-5e and 5g-5h can run in any order. Step 5f depends on the machine name being resolved. Step 5i depends on environment variables being available.

### Snapshot Coverage

The existing `create_snapshot` in `lib/rollback.sh` backs up `~/.claude/` contents. It should be updated to also snapshot:
- `~/.local/share/mcp-servers/memory-sync/` (Step 5g)
- `~/.local/bin/claude-desktop-update` (Step 5h)
- `~/.config/systemd/user/claude-desktop-update.*` (Step 5h)
- `~/.config/Claude/claude_desktop_config.json` (Step 5i)

### Testing Strategy

1. **Dry-run first**: `./bootstrap.sh --dry-run` should print all planned operations without touching the filesystem
2. **Fresh machine**: Test on a machine with no existing `~/.claude/` directory
3. **Existing machine**: Test on a machine with pre-existing configs to verify overwrite behavior
4. **Rollback**: Run `./bootstrap.sh --rollback` after a full bootstrap and verify all files are restored
5. **Partial deploy**: Test with individual `--skip-*` flags

---

## Summary Table

| Step | What | Source | Target | Platform |
|------|------|--------|--------|----------|
| 5a | Skills | `universal/claude/skills/` | `~/.claude/skills/` | All |
| 5b | Agents | `universal/claude/agents/` | `~/.claude/agents/` | All |
| 5c | Commands | `universal/claude/commands/` | `~/.claude/commands/` | All |
| 5d | Scripts | `universal/claude/scripts/` | `~/.claude/scripts/` | All |
| 5e | Machine detection | `universal/claude/machines/` | `~/.claude/machines/` | All |
| 5f | Memory files | universal + platform + machine | `~/.claude/projects/-home-*/memory/` | All |
| 5g | MCP servers | `universal/claude/mcp-servers/` | `~/.local/share/mcp-servers/` | All |
| 5h | Platform scripts | `platform/linux/scripts/` + `systemd/` | `~/.local/bin/` + systemd user | Linux |
| 5i | Desktop config | `universal/claude/claude-desktop-config.template.json` | `~/.config/Claude/` | All |
