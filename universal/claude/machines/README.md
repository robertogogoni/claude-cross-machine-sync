# Machine Profiles

This directory contains profiles for each machine you use with Claude Code.

## Purpose

Machine profiles enable:
- **Automatic machine detection** - Claude knows which machine you're on
- **Machine-specific settings** - Different configurations per machine
- **Resource-aware behavior** - Adapt to each machine's capabilities
- **Synchronized preferences** - Track settings across all your machines

## Structure

Each machine has its own profile file:
```
~/.claude/machines/
├── README.md                    # This file
├── current.json                 # Symlink to active machine profile
├── omarchy-samsung.json         # Samsung laptop profile
├── macbook-air.json             # MacBook Air profile
└── detect-machine.sh            # Auto-detection script
```

## Machine Detection

Machine identity is determined by:
1. **Hostname** - Primary identifier (e.g., "omarchy")
2. **Machine ID** - Unique system identifier from `/etc/machine-id`
3. **Hardware signature** - CPU model, vendor, memory

## Profile Format

Each profile contains:
- **Identity**: Name, hostname, machine ID
- **Hardware**: CPU, RAM, storage, graphics
- **OS**: Distribution, kernel, architecture
- **Network**: Typical IP ranges, interfaces
- **Preferences**: Machine-specific Claude settings
- **Capabilities**: What this machine is good for

## Usage

**Detect current machine:**
```bash
~/.claude/machines/detect-machine.sh
```

**Check current machine:**
```bash
cat ~/.claude/machines/current.json
```

**List all machines:**
```bash
ls ~/.claude/machines/*.json
```

**In Claude Code:**
```
"Which machine am I on?"
"Show my current machine profile"
"What are the specs of this machine?"
```

## Adding a New Machine

1. Run detection script on the new machine
2. Create profile: `machine-name.json`
3. Update current symlink
4. Sync profiles across machines (optional)

---

*Machine profiles are automatically loaded at session start*
