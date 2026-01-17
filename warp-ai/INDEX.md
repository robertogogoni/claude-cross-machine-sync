# Warp Terminal AI History

Extracted from Warp Terminal and Warp Terminal Preview on MacBook Air.

## Summary

| Source | AI Queries | Agent Conversations | Workflows |
|--------|------------|---------------------|-----------|
| Warp Terminal | 570 | 13 | 3 |
| Warp Preview | 1,138 | 36 | ? |
| **Total** | **1,708** | **49** | **3+** |

## Files

### Warp Terminal (Stable)
- `queries/all-queries.csv` - 570 AI queries with timestamps, inputs, models
- `agents/all-conversations.json` - 13 agent conversation threads
- `workflows.json` - 3 saved workflows

### Warp Terminal Preview
- `preview-queries/all-queries.csv` - 1,138 AI queries
- `preview-agents/all-conversations.json` - 36 agent conversations
- `preview-workflows.json` - Saved workflows

## Models Used

Based on query data, models include:
- `gpt-5-1-medium-reasoning` - GPT-5 medium reasoning
- `gpt-5-1-high-reasoning` - GPT-5 high reasoning
- `claude-4-5-sonnet-thinking` - Claude 4.5 Sonnet with thinking

## Data Format

### AI Queries (CSV)
```csv
conversation_id,start_ts,input,output_status,model_id
```

The `input` field contains JSON with:
- Query text
- Context (working directory, current time, execution environment)
- Referenced attachments

### Agent Conversations (JSON)
Each line contains:
- `conversation_id` - Unique conversation identifier
- `conversation_data` - Full conversation JSON with messages
- `last_modified_at` - Timestamp

## Date Range

- **Earliest**: ~November 2025
- **Latest**: December 2025

## Source Databases

- `~/.local/state/warp-terminal/warp.sqlite`
- `~/.local/state/warp-terminal-preview/warp.sqlite`

## Usage

These files can be used to:
1. Search past terminal AI assistance
2. Recreate workflows
3. Find solutions to problems you've solved before
4. Analyze AI usage patterns

---

*Extracted: 2026-01-17*
