# Machine Profile System - Usage Guide

## Quick Start

### View Current Machine
```bash
~/.claude/machines/show-machine.sh
```

### Detect Machine
```bash
~/.claude/machines/detect-machine.sh
```

### Check Which Machine You're On (in Claude Code)
```
"Which machine am I on?"
"Show my current machine profile"
"What are the specs of this machine?"
```

---

## Available Machines

### 1. omarchy-samsung (Primary) ⭐
- **Type:** Samsung Laptop
- **OS:** Arch Linux
- **CPU:** Intel Core i7-4510U (4 cores)
- **RAM:** 7.7GB
- **Status:** ✅ Fully configured
- **Profile:** `~/.claude/machines/omarchy-samsung.json`

### 2. macbook-air (Template)
- **Type:** MacBook Air
- **OS:** macOS
- **Status:** ⚠️ Template - needs population
- **Profile:** `~/.claude/machines/macbook-air.json`
- **Action Required:** Run detection script when on MacBook Air

---

## Common Tasks

### Add a New Machine

**When you're on the new machine:**

1. **Copy the detection script** (if not already synced):
   ```bash
   scp ~/.claude/machines/detect-machine.sh new-machine:~/.claude/machines/
   ```

2. **Run detection** to gather machine info:
   ```bash
   ~/.claude/machines/detect-machine.sh --json > /tmp/machine-info.json
   cat /tmp/machine-info.json
   ```

3. **Create profile** based on detection output:
   ```bash
   # Use omarchy-samsung.json as a template
   cp ~/.claude/machines/omarchy-samsung.json ~/.claude/machines/new-machine.json
   # Edit with detected values
   nano ~/.claude/machines/new-machine.json
   ```

4. **Update machine identity** in the JSON:
   ```json
   {
     "identity": {
       "name": "new-machine",
       "hostname": "from-detection",
       "machineId": "from-detection"
     }
   }
   ```

5. **Set as current**:
   ```bash
   cd ~/.claude/machines
   ln -sf new-machine.json current.json
   ```

### Update Existing Profile

**Edit the profile file:**
```bash
nano ~/.claude/machines/omarchy-samsung.json
```

**Update the lastUpdated timestamp:**
```bash
jq '.metadata.lastUpdated = "'$(date -I)'"' ~/.claude/machines/omarchy-samsung.json > /tmp/updated.json
mv /tmp/updated.json ~/.claude/machines/omarchy-samsung.json
```

### Sync Profiles Across Machines

**Option 1: Git (Recommended)**
```bash
cd ~/.claude/machines
git init
git add .
git commit -m "Machine profiles"
git remote add origin <your-repo>
git push -u origin main
```

**On other machines:**
```bash
cd ~/.claude/machines
git pull
```

**Option 2: Cloud Sync**
```bash
# Dropbox/Google Drive
ln -s ~/Dropbox/claude-machines ~/.claude/machines
```

**Option 3: Manual Copy**
```bash
scp ~/.claude/machines/*.json other-machine:~/.claude/machines/
```

---

## Machine Detection

### How It Works

The detection script matches machines using:

1. **Hostname** (primary identifier)
   - Example: `omarchy` → omarchy-samsung.json

2. **Machine ID** (unique system identifier)
   - Linux: `/etc/machine-id`
   - macOS: System UUID
   - Fallback: Hardware signature

3. **Hardware Signature** (secondary validation)
   - CPU model
   - System vendor
   - Memory configuration

### Detection Modes

**Human-readable output:**
```bash
~/.claude/machines/detect-machine.sh
```
Output:
```
✅ Detected machine: omarchy-samsung
Profile: ~/.claude/machines/omarchy-samsung.json
```

**JSON output:**
```bash
~/.claude/machines/detect-machine.sh --json
```
Output:
```json
{
  "detected": "true",
  "name": "omarchy-samsung",
  "hostname": "omarchy",
  "machineId": "289969333a234ba5915b5f1378f0821c",
  "osType": "linux",
  "timestamp": "2026-01-07T11:58:46-03:00"
}
```

**Name only:**
```bash
~/.claude/machines/detect-machine.sh --name-only
```
Output:
```
omarchy-samsung
```

### Automatic Detection

**When Claude Code starts:**
- SessionStart hook runs automatically
- Detects current machine
- Updates `current.json` symlink
- Machine profile available to Claude

**Manual trigger:**
```bash
~/.claude/machines/detect-machine.sh
```

---

## Machine-Specific Settings

### Customize Claude Code Per Machine

**Example: Different output styles**

In `omarchy-samsung.json`:
```json
{
  "claudeCode": {
    "preferences": {
      "outputStyle": "Explanatory"
    }
  }
}
```

In `macbook-air.json`:
```json
{
  "claudeCode": {
    "preferences": {
      "outputStyle": "Concise"
    }
  }
}
```

### Resource-Aware Behavior

Claude can adapt based on machine capabilities:

**Low-power machine (MacBook Air on battery):**
- Suggest lighter builds
- Recommend resource-efficient tools
- Avoid heavy parallel operations

**Workstation (omarchy-samsung):**
- Can run heavy Docker containers
- Parallel processing OK
- More aggressive caching

### Example Usage in Claude Code

```
User: "Build the project with all optimizations"

Claude checks machine profile:
- If omarchy-samsung: "Running full production build with parallel processing"
- If macbook-air: "Running optimized build (battery-friendly mode)"
```

---

## Querying Machine Info

### From Command Line

**Show full profile:**
```bash
~/.claude/machines/show-machine.sh
```

**Get specific value:**
```bash
jq -r '.hardware.cpu.model' ~/.claude/machines/current.json
```

**List all machines:**
```bash
ls ~/.claude/machines/*.json | grep -v current.json
```

**Compare machines:**
```bash
echo "=== omarchy-samsung ===" && jq -r '.hardware.cpu.model' ~/.claude/machines/omarchy-samsung.json
echo "=== macbook-air ===" && jq -r '.hardware.cpu.model' ~/.claude/machines/macbook-air.json
```

### In Claude Code Conversations

**Ask Claude:**
```
"Which machine am I on?"
"Show current machine specs"
"What's the CPU on this machine?"
"How much RAM does this machine have?"
"What's this machine good for?"
"Compare this machine to my MacBook Air"
```

**Claude will read from:**
1. `~/.claude/machines/current.json` (auto-updated)
2. `~/.claude/memory/machines.md` (summary)

---

## Troubleshooting

### Machine Not Detected

**Check hostname:**
```bash
hostname
```

**Check machine ID:**
```bash
cat /etc/machine-id  # Linux
# or
ioreg -rd1 -c IOPlatformExpertDevice | grep UUID  # macOS
```

**Manually create profile:**
```bash
~/.claude/machines/detect-machine.sh --json > /tmp/info.json
# Use info.json to create profile
```

### current.json Points to Wrong Machine

**Fix symlink:**
```bash
cd ~/.claude/machines
rm current.json
ln -sf omarchy-samsung.json current.json
```

### Profile Out of Date

**Update profile:**
```bash
# Re-run detection
~/.claude/machines/detect-machine.sh --json

# Update profile manually
nano ~/.claude/machines/omarchy-samsung.json

# Update timestamp
jq '.metadata.lastUpdated = "'$(date -I)'"' ~/.claude/machines/omarchy-samsung.json
```

---

## Best Practices

### 1. Keep Profiles in Sync

Use git or cloud sync to keep profiles synchronized across machines.

### 2. Update Profiles After Hardware Changes

When you upgrade RAM, change CPU, or modify the system:
```bash
nano ~/.claude/machines/$(hostname).json
# Update hardware section
```

### 3. Use Descriptive Names

Good: `omarchy-samsung`, `macbook-air-m2`, `desktop-workstation`
Bad: `machine1`, `laptop`, `computer`

### 4. Include Usage Notes

Document what each machine is used for:
```json
{
  "usage": {
    "notes": "Primary dev machine. Use for Docker, heavy builds. Has VPN access to production."
  }
}
```

### 5. Track Machine-Specific Tools

```json
{
  "software": {
    "development": {
      "languages": ["python3", "node", "go"],
      "tools": ["docker", "kubectl", "terraform"]
    }
  }
}
```

---

## Files & Directories

```
~/.claude/machines/
├── README.md               # System overview
├── USAGE.md               # This file
├── current.json          # Symlink → active machine
├── detect-machine.sh     # Auto-detection script
├── show-machine.sh       # Display current profile
├── omarchy-samsung.json  # Samsung laptop profile
└── macbook-air.json      # MacBook Air profile (template)
```

---

## Integration with Claude Code

### Memory System
Machine profiles are integrated with Claude's memory:
- `~/.claude/memory/machines.md` - Summary of all machines
- `~/.claude/machines/*.json` - Detailed profiles

### Auto-Loading
- SessionStart hook detects machine automatically
- No manual intervention needed
- current.json always points to correct profile

### Usage in Conversations
Claude automatically knows which machine you're on and can:
- Adapt recommendations
- Suggest machine-appropriate solutions
- Reference machine-specific configurations

---

## Next Steps

1. **Populate MacBook Air profile** when you're on that machine
2. **Sync profiles** across machines using git
3. **Customize** machine-specific preferences
4. **Add notes** about each machine's purpose and tools

---

*Machine profiles make Claude Code machine-aware and context-sensitive*
*For support, see: ~/.claude/machines/README.md*
