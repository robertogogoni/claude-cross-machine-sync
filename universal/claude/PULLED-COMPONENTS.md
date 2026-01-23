# Pulled Components from Community

**Date**: 2026-01-23
**Purpose**: Leverage battle-tested Claude Code configurations from the community

## Sources

| Repository | Author | What We Pulled |
|------------|--------|----------------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | affaan-m | Hooks, Agents |
| [claude-code-settings](https://github.com/feiskyer/claude-code-settings) | feiskyer | Commands |
| [claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | ChrisWiles | GitHub Actions |

## Components

### Hooks (`hooks/`)

| File | Purpose |
|------|---------|
| `session-start.sh` | Load previous context on new session |
| `session-end.sh` | Persist session state when ending |

### Agents (`agents/`)

| File | Purpose |
|------|---------|
| `planner.md` | Expert planning specialist for complex features |
| `code-reviewer.md` | Code review with security and quality checks |

### Commands (`commands/`)

| File | Purpose |
|------|---------|
| `think-harder.md` | Enhanced analytical thinking for complex problems |
| `eureka.md` | Capture technical breakthroughs as documentation |

### GitHub Actions (`.github/workflows/`)

| File | Frequency | Purpose |
|------|-----------|---------|
| `pr-claude-code-review.yml` | On PR | Automated code review |
| `scheduled-docs-sync.yml` | Monthly | Keep docs aligned with code |

## Setup Required

### 1. GitHub Actions (requires secrets)

Add to your repository secrets:
- `ANTHROPIC_API_KEY` - Your Anthropic API key

### 2. Hooks (requires local config)

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{"matcher": "*", "hooks": [{"type": "command", "command": "~/.claude/hooks/session-start.sh"}]}],
    "Stop": [{"matcher": "*", "hooks": [{"type": "command", "command": "~/.claude/hooks/session-end.sh"}]}]
  }
}
```

### 3. Commands (auto-available)

Commands in `.claude/commands/` are automatically available as slash commands:
- `/think-harder [problem]`
- `/eureka [breakthrough]`

### 4. Agents (auto-available)

Agents in `.claude/agents/` are available for Task tool delegation.

## Customization

Feel free to modify these components for your workflow:
- Adjust review checklist in `code-reviewer.md`
- Change planning format in `planner.md`
- Modify session template in `session-end.sh`

## License

These components are sourced from open-source repositories. Check original repos for license terms.
