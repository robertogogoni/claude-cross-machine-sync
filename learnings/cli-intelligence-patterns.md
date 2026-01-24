# CLI Intelligence Patterns

**Created**: 2026-01-24
**Category**: Claude Code Enhancement, AI Automation, Memory Systems

---

## Overview

This document captures patterns and techniques for building intelligent CLI systems that:
- Activate skills via natural language (not exact names)
- Automatically manage memory across sessions
- Provide intelligent auto-completion
- Learn continuously from work sessions

---

## Pattern 1: AI-Powered Skill Activation

### The Problem
Claude Code skills don't activate on their own. Users must know exact skill names and manually invoke them.

### The Solution: Intent Detection Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    UserPromptSubmit Hook                        │
├─────────────────────────────────────────────────────────────────┤
│  1. Capture user prompt                                         │
│  2. Send to Intent Analyzer (Claude Haiku - fast, cheap)       │
│  3. Score each available skill (0.0 - 1.0)                     │
│  4. Auto-inject skills with score > 0.65                       │
│  5. Suggest skills with score 0.50-0.65                        │
│  6. Track injected skills per session (prevent duplicates)     │
└─────────────────────────────────────────────────────────────────┘
```

### Key Implementation Details

**Why Haiku?**
- Fast: ~200ms first call, <10ms cached
- Cheap: ~$1-2/month at 100 prompts/day
- Good enough: Intent detection doesn't need Opus-level reasoning

**Caching Strategy**:
- MD5 hash the prompt as cache key
- 1 hour TTL (prompts don't change meaning over time)
- ~95% cache hit rate for repeated patterns

**Fallback Chain** (when API unavailable):
1. Semantic similarity (sentence-transformers)
2. Fuzzy keyword match (fuzzball.js, 0.7 threshold)
3. Pattern regex (direct matching)
4. Last resort: Show top 3 suggestions

### Skill Registry Format

```json
{
  "skills": [
    {
      "name": "test-driven-development",
      "aliases": ["tdd", "write tests first"],
      "triggers": {
        "keywords": ["test", "testing", "spec", "jest"],
        "patterns": ["write.*test", "add.*test"],
        "intent_phrases": ["I want to add tests", "help me test"]
      },
      "confidence_boost": 0.2
    }
  ]
}
```

### Key Insight
> "Description quality determines skill activation. A generic entry like 'helps with database problems' rarely triggers, whereas 'Fix for PrismaClientKnownRequestError in serverless' matches when developers encounter that specific error."
> — Claudeception documentation

---

## Pattern 2: Multi-Layer Memory Architecture

### The Problem
Memory storage is too manual. Learnings get lost between sessions.

### The Solution: 4-Layer Hierarchy

```
Layer 1: Working Memory (session)
├── Current task context
├── Recent tool outputs
└── Active decisions

Layer 2: Short-Term Memory (24h)
├── Today's learnings
├── Recent solutions
└── Pending follow-ups

Layer 3: Long-Term Memory (persistent)
├── Episodic memory archive
├── Extracted patterns
└── Project-specific knowledge

Layer 4: Cross-Machine Memory (synced)
├── Machine registry
├── Universal configs
└── Platform-specific adaptations
```

### Automatic Capture Hooks

**SessionEnd Hook** (Dream-inspired consolidation):
```javascript
// hooks/session-memory-capture.js
module.exports = {
  event: "Stop",
  script: async (context) => {
    // 1. Analyze conversation for extractable knowledge
    // 2. Categorize: bug-fix, pattern, decision, config
    // 3. Store with semantic tags for future retrieval
    // 4. Sync to cross-machine repo if enabled
  }
};
```

**PostToolUse Hook** (Capture significant outputs):
```javascript
module.exports = {
  event: "PostToolUse",
  script: async (context) => {
    const significantTools = ['Bash', 'Edit', 'Write'];
    if (significantTools.includes(context.tool.name)) {
      // Extract and index meaningful outputs
      // Flag errors for future reference
    }
  }
};
```

### Consolidation Schedule

| Trigger | Action |
|---------|--------|
| Session End | Extract learnings, update short-term |
| Daily (3 AM) | Consolidate short-term → long-term |
| Weekly | Pattern extraction across sessions |
| On Sync | Push to cross-machine repo |

### Key Insight
> The "dream-inspired" consolidation metaphor: Just as humans consolidate memories during sleep, the system processes and compresses learnings during off-hours, extracting patterns and discarding noise.

---

## Pattern 3: Continuous Learning (Claudeception)

### The Problem
Each session starts fresh. Learned patterns and solutions don't persist as skills.

### The Solution: Skill Auto-Extraction

**Trigger Conditions**:
- Session ends with meaningful discovery
- Bug fixes requiring investigation
- Non-obvious solutions
- Project-specific patterns

**Quality Gates** (only extract if):
- Required actual discovery (not just docs lookup)
- Clear trigger conditions exist
- Verified through testing
- Genuinely useful for future

### Auto-Extracted Skill Format

```markdown
---
name: prisma-serverless-fix
description: Fix PrismaClientKnownRequestError in serverless environments
trigger-patterns:
  - PrismaClientKnownRequestError
  - connection pool exhausted
extracted-from: session-2026-01-24-debug-api
confidence: 0.92
---

# Prisma Serverless Connection Fix

## Problem
[Description of the issue]

## Solution
[Step-by-step solution]

## Implementation
[Code examples from the session]
```

### Research References
- **Voyager (2023)**: Established that persistent skill libraries outperform zero-start sessions
- **CASCADE (2024)**: Introduced "meta-skills" for skill acquisition itself
- **SEAgent (2025)**: Demonstrated agents learning through environmental trial-and-error

---

## Pattern 4: Intelligent Auto-Completion

### Multi-Source Completion Engine

```
Input: User typing...

Sources:
├── Skills (34 from SuperNavigator)
├── Plugins (superpowers, episodic-memory)
├── MCP Tools (beeper, chrome, etc.)
├── Recent Commands (shell history)
├── Project Files (context-aware)
└── Memory (past solutions)

Ranking:
1. Semantic relevance (embeddings)
2. Recency (recent = higher score)
3. Frequency (often used = higher score)
4. Context match (file type, project)
```

### Terminal Integration

**PowerShell**:
```powershell
Register-ArgumentCompleter -CommandName claude -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    Invoke-ClaudeComplete -Prefix $wordToComplete
}
```

**Bash**:
```bash
_claude_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(claude-complete query "$cur" --format=bash))
}
complete -F _claude_complete claude
```

---

## Key GitHub Projects

| Project | Purpose | URL |
|---------|---------|-----|
| claude-skills-supercharged | 7-stage AI injection pipeline | [GitHub](https://github.com/jefflester/claude-skills-supercharged) |
| claude-code-infrastructure-showcase | Auto-activation technique | [GitHub](https://github.com/diet103/claude-code-infrastructure-showcase) |
| Claudeception | Autonomous skill extraction | [GitHub](https://github.com/blader/Claudeception) |
| mcp-memory-service | Dream-inspired memory | [GitHub](https://github.com/doobidoo/mcp-memory-service) |
| autocomplete-sh | AI terminal completion | [GitHub](https://github.com/closedLoop-technologies/autocomplete-sh) |
| nl-sh | Natural Language Shell | [GitHub](https://github.com/mikecvet/nl-sh) |
| ai-shell | NL to shell commands | [GitHub](https://github.com/BuilderIO/ai-shell) |
| fzf | Universal fuzzy finder | [GitHub](https://github.com/junegunn/fzf) |

---

## npm Dependencies

```json
{
  "dependencies": {
    "fuzzball": "^2.1.2",
    "sentence-transformers": "^3.0",
    "lru-cache": "^10.0.0",
    "chokidar": "^3.5.3",
    "glob": "^10.3.0"
  }
}
```

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Skill activation accuracy | >90% |
| False positive rate | <5% |
| Intent detection latency | <200ms (first), <10ms (cached) |
| Memory capture coverage | >80% of significant learnings |
| Auto-completion relevance | >85% top-3 hit rate |

---

## Anti-Patterns to Avoid

1. **Loading all skills at once**: Defeats token optimization. Use progressive disclosure.
2. **Generic skill descriptions**: "Helps with X" rarely triggers. Be specific.
3. **No caching**: API calls on every prompt = expensive and slow.
4. **Manual-only memory**: If it requires user action, it won't happen consistently.
5. **Session-scoped only**: Cross-session learning is where the real value lies.

---

## Related Files

- `docs/plans/2026-01-24-unified-cli-intelligence-design.md` - Full design document
- `docs/plans/2026-01-24-supernavigator-enhancements.md` - SuperNavigator integration
- `~/.claude/plugins/supernavigator/` - Enhanced plugin with 34 skills
