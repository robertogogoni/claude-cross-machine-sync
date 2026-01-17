# AI Data Extraction Techniques

**Created**: 2026-01-17
**Context**: Extracting and preserving AI conversation history from various tools

## Overview

Modern AI-enabled tools store conversation history locally. This document covers techniques for finding, extracting, and preserving this data.

## Common Storage Patterns

### SQLite Databases
Most AI tools use SQLite for local storage:

| Tool | Database Location | Key Tables |
|------|-------------------|------------|
| Warp Terminal | `~/.local/state/warp-terminal/warp.sqlite` | `ai_queries`, `ai_agent_conversations` |
| Warp Preview | `~/.local/state/warp-terminal-preview/warp.sqlite` | Same as above |
| Zed | `~/.local/share/zed/db/` | Various (no AI tables found) |
| Cursor | `~/.config/Cursor/` | Various |

### Markdown Files
AI task planning tools output human-readable markdown:

| Tool | Location | File Types |
|------|----------|------------|
| Antigravity/Gemini | `~/.gemini/antigravity/brain/<uuid>/` | `task.md`, `implementation_plan.md`, `walkthrough.md` |

### JSONL Archives
Conversation archives often use JSON Lines format:

| Tool | Location | Format |
|------|----------|--------|
| Claude Code (Episodic Memory) | `~/.config/superpowers/conversation-archive/` | JSONL per project |

## Discovery Commands

### Finding Databases
```bash
# Find all SQLite databases
find ~ -name "*.sqlite" -o -name "*.db" 2>/dev/null

# Find in specific locations
find ~/.local/state -name "*.sqlite" 2>/dev/null
find ~/.config -name "*.sqlite" 2>/dev/null
```

### Exploring SQLite Structure
```bash
# List all tables
sqlite3 database.sqlite ".tables"

# Show table schema
sqlite3 database.sqlite ".schema table_name"

# Preview data
sqlite3 database.sqlite "SELECT * FROM table_name LIMIT 5;"
```

### Finding Markdown Files
```bash
# Find all .md files in AI-related directories
find ~/.gemini ~/.config ~/.local -name "*.md" 2>/dev/null

# Find AI-related markdown by content
grep -r "implementation" ~/.gemini --include="*.md" 2>/dev/null
```

## Extraction Techniques

### Warp Terminal

```bash
# Export AI queries to CSV
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" \
  ".mode csv" \
  "SELECT * FROM ai_queries;" > all-queries.csv

# Export agent conversations to JSON (one per line)
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  "SELECT * FROM ai_agent_conversations;" > all-conversations.json

# Export with specific columns
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" \
  ".mode csv" \
  "SELECT conversation_id, start_ts, input, model_id FROM ai_queries;" > queries.csv
```

### Warp Data Format

The `ai_queries` table structure:
```sql
conversation_id  -- UUID for the query
start_ts         -- Timestamp
input            -- JSON blob with query details
output_status    -- Status (e.g., "SUCCESS")
model_id         -- Model used (e.g., "gpt-5-1-medium-reasoning")
```

The `input` JSON contains:
```json
{
  "query": "actual query text",
  "context": {
    "working_directory": "/path/to/dir",
    "current_time": "timestamp",
    "execution_environment": "terminal info"
  },
  "attachments": []
}
```

### Antigravity/Gemini

```bash
# Copy all brain sessions
cp -r ~/.gemini/antigravity/brain/ ./gemini-brain/

# List sessions by date
ls -lt ~/.gemini/antigravity/brain/

# Find specific task types
grep -l "install" ~/.gemini/antigravity/brain/*/task.md
```

### Claude Code Episodic Memory

```bash
# Copy entire archive (large!)
cp -r ~/.config/superpowers/conversation-archive/ ./episodic-memory/

# Check archive size first
du -sh ~/.config/superpowers/conversation-archive/

# List conversation files
ls ~/.config/superpowers/conversation-archive/-home-rob/
```

## Parsing Extracted Data

### Parsing Warp CSV in Python
```python
import csv
import json

with open('all-queries.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        input_data = json.loads(row['input'])
        query = input_data.get('query', '')
        model = row['model_id']
        print(f"[{model}] {query[:100]}...")
```

### Searching Warp History with Grep
```bash
# Find queries about Docker
grep -i docker all-queries.csv

# Find queries with specific model
grep "gpt-5-1-high-reasoning" all-queries.csv

# Count queries per model
cut -d',' -f5 all-queries.csv | sort | uniq -c
```

### Parsing Gemini Sessions
```bash
# Extract task summaries
for dir in gemini-brain/*/; do
    echo "=== $(basename $dir) ==="
    head -5 "$dir/task.md" 2>/dev/null
    echo
done
```

## Storage Considerations

### Git LFS for Large Archives
Episodic memory can be 100MB+. Use Git LFS:

```bash
# Setup
git lfs install
git lfs track "*.jsonl"
git add .gitattributes

# Verify
git lfs ls-files
```

### Incremental Updates
For Warp data, consider incremental extraction:

```bash
# Export only recent queries (last 7 days)
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" \
  ".mode csv" \
  "SELECT * FROM ai_queries WHERE start_ts > datetime('now', '-7 days');" > recent-queries.csv
```

## Data Quality Notes

### Warp
- Queries are comprehensive with full context
- Agent conversations include full thread history
- Some queries may have truncated outputs

### Gemini/Antigravity
- Sessions are complete but may reference external files
- Some sessions have images alongside markdown
- UUIDs make sessions hard to identify by name (use task.md content)

### Claude Code
- JSONL files can be very large
- Each project has separate archive
- Index databases enable fast search

## Automation Ideas

### Periodic Warp Extraction
```bash
#!/bin/bash
# Save as ~/bin/sync-warp-ai.sh

cd ~/claude-cross-machine-sync/warp-ai

# Extract queries
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > queries/all-queries.csv

# Extract from preview
sqlite3 ~/.local/state/warp-terminal-preview/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > preview-queries/all-queries.csv

# Commit if changed
git add .
git diff --staged --quiet || git commit -m "Update Warp AI history $(date +%Y-%m-%d)"
```

### Cron Job
```bash
# Add to crontab (weekly extraction)
0 0 * * 0 ~/bin/sync-warp-ai.sh
```

## Security Considerations

1. **Queries may contain sensitive data** - Don't share exports publicly
2. **Context includes file paths** - May reveal project structure
3. **Use private repositories** - AI history is personal data
4. **Review before committing** - Check for API keys, passwords

## Related Files

- [warp-ai/INDEX.md](../warp-ai/INDEX.md) - Warp data documentation
- [antigravity-history/INDEX.md](../antigravity-history/INDEX.md) - Gemini session index
- [cross-machine-sync.md](./cross-machine-sync.md) - Sync patterns

---

*Pattern: Your AI conversations are valuable data - extract, preserve, and make them searchable.*
