# Session: Cross-Machine Sync & AI History Extraction

**Date**: 2026-01-17
**Duration**: ~2 hours
**Machine**: MacBook Air (Arch Linux)

## Objective

Set up Claude Code on Windows with comprehensive cross-machine synchronization, including all AI-generated intelligence from multiple tools.

## What We Built

### 1. Cross-Machine Sync Repository

Created a comprehensive sync system that aggregates:
- Claude Code settings and skills
- Episodic memory (conversation history)
- Warp Terminal AI history
- Antigravity/Gemini brain task sessions
- Documentation and learnings

**Repository**: https://github.com/robertogogoni/claude-cross-machine-sync

### 2. AI Data Extraction Pipeline

Discovered and extracted AI history from multiple tools:

| Tool | Location | Format | Records |
|------|----------|--------|---------|
| Warp Terminal | `~/.local/state/warp-terminal/warp.sqlite` | SQLite | 570 queries, 13 conversations |
| Warp Preview | `~/.local/state/warp-terminal-preview/warp.sqlite` | SQLite | 1,138 queries, 36 conversations |
| Antigravity | `~/.gemini/antigravity/brain/` | Markdown | 15 task sessions |
| Claude Code | `~/.config/superpowers/conversation-archive/` | JSONL | 128MB archive |

### 3. Documentation

Created:
- Polished README with badges, tables, collapsible sections
- Windows setup guide with PowerShell commands
- Warp AI index documenting data format
- Antigravity history index with session summaries
- Updated CLAUDE.md with comprehensive project memory

## Key Discoveries

### Warp Terminal AI Storage

Warp stores AI interactions in SQLite:

```sql
-- Tables discovered
ai_queries           -- Individual AI queries
ai_agent_conversations   -- Agent conversation threads
```

The `input` field in `ai_queries` contains JSON with:
- Query text
- Working directory context
- Execution environment
- Referenced attachments

### Gemini Brain Structure

Antigravity (Google's VSCode-based IDE) stores AI task sessions in:
```
~/.gemini/antigravity/brain/<uuid>/
├── task.md              # Task definition
├── implementation_plan.md   # Step-by-step plan
├── walkthrough.md       # Guided implementation
└── verification_plan.md # Testing steps
```

### Git LFS for Large Archives

Episodic memory (128MB) requires Git LFS:
```bash
git lfs install
git lfs track "*.jsonl"
```

Benefits:
- Fast cloning (only pointers in repo)
- On-demand content download
- No repository bloat

## Commands Used

### SQLite Extraction
```bash
# Export AI queries to CSV
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  ".headers on" ".mode csv" \
  "SELECT * FROM ai_queries;" > all-queries.csv

# Export agent conversations to JSON
sqlite3 ~/.local/state/warp-terminal/warp.sqlite \
  "SELECT * FROM ai_agent_conversations;" > all-conversations.json
```

### Git LFS Setup
```bash
git lfs install
git lfs track "*.jsonl"
git add .gitattributes
git commit -m "Configure Git LFS for large files"
```

### Finding AI Data Sources
```bash
# Find SQLite databases
find ~ -name "*.sqlite" -o -name "*.db" 2>/dev/null

# Check tables in a database
sqlite3 file.sqlite ".tables"

# Find markdown files
find ~/.gemini -name "*.md" 2>/dev/null
```

## Patterns Learned

### 1. AI Tools Store Data in Predictable Locations
- `~/.local/state/<app>/` - Application state (Warp)
- `~/.config/<app>/` - Configuration (Claude, Cursor)
- `~/.gemini/<app>/` - Gemini-related apps (Antigravity)

### 2. SQLite is Common for AI History
Most AI-enabled tools use SQLite for persistence. Look for:
- Tables with "ai", "query", "conversation", "agent" in names
- JSON blobs in text columns for complex data

### 3. Markdown for Human-Readable AI Artifacts
AI task planning tools (Gemini, Antigravity) output markdown for:
- Task definitions
- Implementation plans
- Verification steps

### 4. Git LFS for Large AI Archives
Conversation archives grow large quickly. Use Git LFS to:
- Keep repo manageable
- Enable fast cloning
- Preserve full history

## Files Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `README.md` | Rewritten | Comprehensive repo documentation |
| `CLAUDE.md` | Updated | Project memory with session details |
| `docs/WINDOWS-SETUP.md` | Created | Windows installation guide |
| `warp-ai/INDEX.md` | Created | Warp data documentation |
| `warp-ai/queries/*.csv` | Created | Extracted AI queries |
| `warp-ai/agents/*.json` | Created | Extracted conversations |
| `antigravity-history/` | Created | Recovered Gemini sessions |
| `learnings/cross-machine-sync.md` | Created | Sync patterns |
| `learnings/ai-data-extraction.md` | Created | Extraction techniques |

## Next Steps

1. **Windows Setup**: Clone repo on Windows, follow setup guide
2. **Periodic Updates**: Re-extract Warp data periodically
3. **Additional Machines**: Add Linux Notebook 2 to sync
4. **Automation**: Consider cron job for Warp extraction

## Metrics

| Metric | Value |
|--------|-------|
| Total AI queries preserved | 1,708 |
| Agent conversations | 49 |
| Gemini task sessions | 15 |
| Repository size | ~308MB |
| Files in repository | 599+ |
| Git commits in session | 3 |

---

*Session completed successfully. All AI intelligence aggregated and synced.*
