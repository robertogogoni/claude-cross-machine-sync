# Cross-Machine Sync Patterns

**Created**: 2026-01-17
**Context**: Setting up Claude Code synchronization across MacBook Air, Linux Notebook, and Windows Desktop

## Core Concept

Synchronize all AI-related configuration, history, and learnings across machines using git as the transport layer.

## What to Sync

### High Priority (Essential)
| Item | Location | Why |
|------|----------|-----|
| Settings | `~/.claude/settings.json` | Permissions, preferences |
| Skills | `~/.claude/skills/` | Custom capabilities |
| Project memory | `CLAUDE.md` | Context and solutions |

### Medium Priority (Valuable)
| Item | Location | Why |
|------|----------|-----|
| Episodic memory | `~/.config/superpowers/conversation-archive/` | Searchable history |
| Learnings | `learnings/` | Extracted patterns |
| Documentation | `docs/` | Guides and references |

### Low Priority (Nice to Have)
| Item | Location | Why |
|------|----------|-----|
| Warp AI history | SQLite extraction | Past terminal AI queries |
| Gemini sessions | Direct copy | AI task planning history |

## Sync Architecture

```
GitHub Repository (Private)
       │
       ├── .claude/settings.json     ─── User settings
       ├── skills/                   ─── Custom skills
       ├── CLAUDE.md                 ─── Project memory
       ├── episodic-memory/          ─── Conversation archive (LFS)
       ├── warp-ai/                  ─── Warp AI history
       ├── learnings/                ─── Patterns & knowledge
       └── docs/                     ─── Documentation

       │
       ▼
┌──────────────────────────────────────────────────────┐
│                    git clone / pull                   │
└──────────────────────────────────────────────────────┘
       │                    │                    │
       ▼                    ▼                    ▼
   MacBook Air        Linux Notebook      Windows Desktop
   (Main)             (Secondary)         (Secondary)
```

## Setup Workflow

### Initial Setup (Main Machine)
```bash
# 1. Create repository
mkdir ~/claude-cross-machine-sync
cd ~/claude-cross-machine-sync
git init

# 2. Copy configuration
cp -r ~/.claude/settings.json .claude/
cp -r ~/.claude/skills/* skills/

# 3. Set up Git LFS for large files
git lfs install
git lfs track "*.jsonl"

# 4. Push to remote
git remote add origin <url>
git push -u origin master
```

### Clone on New Machine
```bash
# 1. Install Git LFS first
git lfs install

# 2. Clone
git clone <url> ~/claude-cross-machine-sync

# 3. Copy to Claude locations
cp ~/claude-cross-machine-sync/.claude/settings.json ~/.claude/
cp -r ~/claude-cross-machine-sync/skills/* ~/.claude/skills/

# 4. Install plugins
# /plugin marketplace add obra/superpowers-marketplace
# /plugin install episodic-memory@superpowers-marketplace
```

## Key Patterns

### 1. Settings Hierarchy
Claude Code loads settings in order:
1. Project `.claude/settings.json` (highest priority)
2. User `~/.claude/settings.json`
3. Defaults

**Pattern**: Keep shared settings in sync repo, machine-specific in user location.

### 2. Git LFS for Large Files
Episodic memory archives can be 100MB+. Use Git LFS:
```bash
git lfs track "*.jsonl"
```

**Pattern**: Track large archives with LFS, small files normally.

### 3. CLAUDE.md as Living Memory
The `CLAUDE.md` file is auto-loaded by Claude Code. Use it for:
- Solutions and fixes (with dates)
- Machine-specific notes
- Workflows and patterns
- Troubleshooting guides

**Pattern**: Update CLAUDE.md after every significant session.

### 4. Skills are Portable
Custom skills in `~/.claude/skills/` work across machines:
```
skills/
├── tool-discovery/SKILL.md
├── beeper-chat/SKILL.md
└── omarchy-skill.md
```

**Pattern**: Store skills in sync repo, copy to `~/.claude/skills/` on each machine.

## Windows Considerations

Windows uses different paths:
| Linux/macOS | Windows |
|-------------|---------|
| `~/.claude/` | `%USERPROFILE%\.claude\` |
| `~/.config/` | `%APPDATA%\` |

PowerShell equivalents:
```powershell
# Copy settings
Copy-Item ".\claude-cross-machine-sync\.claude\settings.json" "$env:USERPROFILE\.claude\" -Force

# Copy skills
Copy-Item -Recurse ".\claude-cross-machine-sync\skills\*" "$env:USERPROFILE\.claude\skills\" -Force
```

## Troubleshooting

### Settings Not Loading
1. Check file exists: `ls ~/.claude/settings.json`
2. Validate JSON: `cat ~/.claude/settings.json | jq .`
3. Restart Claude Code session
4. Check `/config` output

### Git LFS Not Working
```bash
# Verify installation
git lfs version

# Re-install hooks
git lfs install

# Fetch LFS content
git lfs pull
```

### Episodic Memory Not Searchable
1. Check plugin installed: `/plugin list`
2. Verify archive exists in `episodic-memory/`
3. Re-index if needed

## Best Practices

1. **Commit often**: After solving problems, commit immediately
2. **Document solutions**: Add to CLAUDE.md with date and context
3. **Pull before sessions**: Always `git pull` before starting work
4. **Push after sessions**: Share learnings across machines
5. **Keep repo clean**: Don't commit temporary or machine-specific files

## Related Files

- [CLAUDE.md](../CLAUDE.md) - Main project memory
- [WINDOWS-SETUP.md](../docs/WINDOWS-SETUP.md) - Windows installation
- [ssh-setup.md](../docs/ssh-setup.md) - Remote access

---

*Pattern: Treat your AI tools' memory as code - version it, sync it, back it up.*
