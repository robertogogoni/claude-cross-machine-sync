# Claude Code Permissions & Autonomy Modes

**Last Updated**: 2026-01-17
**Applies To**: Claude Code 2.0+

## Platform Legend

| Icon | Platform |
|------|----------|
| 🪟 | Windows only |
| 🐧 | Linux/macOS only |
| 🔄 | Cross-platform (Windows + Linux + macOS) |

---

## Overview

Claude Code has a permission system that prompts for approval before executing potentially dangerous operations (file edits, bash commands, etc.). For power users who want full autonomy, there are several approaches.

---

## Permission Approaches Comparison

| Approach | Safety | Setup Effort | Use Case | Platform |
|----------|--------|--------------|----------|----------|
| **Default** | ✅ Safest | None | New users, learning | 🔄 |
| **Settings allow-list** | ⚠️ Medium | Low | Specific tool permissions | 🔄 |
| **Wildcard permissions** | ⚠️ Medium | Low | Category-based access | 🔄 |
| **Docker sandbox** | ✅ Safe | Medium | Full autonomy, isolated | 🔄 |
| **`--dangerously-skip-permissions`** | ❌ Dangerous | Low | Full autonomy, trusted env | 🔄 |
| **PowerShell alias** | N/A | Low | Quick launch | 🪟 |
| **Bash/Zsh alias** | N/A | Low | Quick launch | 🐧 |

---

## 1. Default Permission System 🔄

Claude prompts before:
- Editing files
- Running bash commands
- Installing packages
- Modifying system configs

**Pros**: Safe, educational, prevents mistakes
**Cons**: Friction for experienced users

---

## 2. Settings Allow-List 🔄

Configure in `~/.claude/settings.json` or `~/.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "Bash"
    ]
  }
}
```

**Granular Bash permissions** (prefix matching):
```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(python *)"
    ]
  }
}
```

**Key Learning**: Permissions use prefix matching. `Bash(git` matches `git status`, `git commit`, etc.

---

## 3. Wildcard Permissions (v2.1.0+) 🔄

Claude Code 2.1.0 introduced wildcard support:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(git *)",
      "Bash(cargo *)",
      "Bash(python *)",
      "mcp__*"
    ]
  }
}
```

**Pros**: More granular than full Bash, safer than skip-permissions
**Cons**: Still need to anticipate what commands you'll use

---

## 4. Docker Sandbox (Recommended for Yolo Mode) 🔄

Use `claude-code-container` or `run-claude-docker` from [superpowers-marketplace](https://github.com/obra/superpowers-marketplace):

```bash
# Full autonomy INSIDE container, can't touch host system
docker run -it --rm \
  -v "$(pwd):/workspace" \
  claude-code-container --dangerously-skip-permissions
```

**Pros**: Full autonomy with safety, can't damage host system
**Cons**: Setup overhead, may not have access to all host tools

---

## 5. `--dangerously-skip-permissions` (Yolo Mode) 🔄

```bash
claude --dangerously-skip-permissions
```

**What it enables**:
- ✅ Edit/delete any file without prompts
- ✅ Run any bash command
- ✅ Install packages system-wide
- ✅ Modify system configurations
- ✅ Full MCP tool access

**Risks**:
- Claude can delete important files
- Can run destructive commands
- Can modify system configs
- Can install unwanted software

**When to use**:
- Trusted development environment
- Isolated VM or container
- When you understand the codebase well
- For experienced users who can review changes

---

## Shell Aliases for Yolo Mode

### PowerShell 🪟

Add to `$PROFILE` (`~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`):

```powershell
# Claude Code "Jarvis Mode"
function jarvis { claude --dangerously-skip-permissions @args }
Set-Alias -Name j -Value jarvis
```

**PowerShell splatting**: `@args` passes all arguments through, so `jarvis --resume` becomes `claude --dangerously-skip-permissions --resume`.

### Bash/Zsh 🐧

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Claude Code "Jarvis Mode"
alias jarvis='claude --dangerously-skip-permissions'
alias j='jarvis'
```

### Fish 🐧

Add to `~/.config/fish/config.fish`:

```fish
# Claude Code "Jarvis Mode"
alias jarvis 'claude --dangerously-skip-permissions'
alias j jarvis
```

---

## Cross-Machine Sync 🔄

To keep permissions consistent across machines:

1. **Symlink settings**: Point `~/.claude/settings.json` to your sync repo
2. **Document aliases**: Add shell aliases to your dotfiles repo
3. **Use the same approach**: Pick one method (settings vs CLI flag) and stick with it

---

## Best Practices 🔄

1. **Start with settings allow-list** - Learn what you actually need
2. **Graduate to wildcards** - `Bash(npm *)` is safer than full `Bash`
3. **Use Docker for risky work** - Unknown codebases, experiments
4. **Reserve yolo mode for trusted work** - Your own projects, known codebases

---

## Troubleshooting

### Permissions Not Working

1. Check settings file exists: `ls ~/.claude/settings.json`
2. Validate JSON syntax
3. Restart Claude Code session
4. Check for typos in permission names

### Alias Not Found

1. Reload shell profile: `source ~/.bashrc` or open new terminal
2. Check profile path matches your shell
3. Verify function syntax for PowerShell vs Bash

---

## Resources

- [Claude Code Docs](https://docs.anthropic.com/claude-code)
- [Superpowers Plugin](https://github.com/obra/superpowers)
- [Superpowers Marketplace](https://github.com/obra/superpowers-marketplace) - Docker containers
- [Claude Code Resource List](https://www.scriptbyai.com/claude-code-resource-list/)
