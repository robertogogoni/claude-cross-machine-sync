# Unified CLI Intelligence System Design

**Created**: 2026-01-24
**Status**: Design Draft
**Goal**: Natural language skill activation, automatic memory management, intelligent auto-completion

---

## Executive Summary

This design combines insights from 20+ GitHub projects into a unified system that:
1. **Triggers skills via natural language** (not exact names)
2. **Automatically manages memory** (recursive, secure, cross-machine)
3. **Provides intelligent auto-completion** (skills, plugins, terminal commands)
4. **Learns continuously** from sessions

---

## Part 1: Natural Language Skill Activation

### Problem Statement
Skills don't activate on their own. Users must know exact skill names and manually invoke them.

### Solution: AI-Powered Intent Detection

**Architecture** (inspired by [claude-skills-supercharged](https://github.com/jefflester/claude-skills-supercharged)):

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

**Key Components**:

1. **skill-intent-analyzer.js** - Uses Haiku for intent detection
2. **skill-registry.json** - Maps natural language patterns to skills
3. **skill-cache.js** - MD5-hashed prompt caching (1hr TTL, ~95% API reduction)

### Skill Registry Format

```json
{
  "skills": [
    {
      "name": "test-driven-development",
      "aliases": ["tdd", "write tests first", "test first"],
      "triggers": {
        "keywords": ["test", "testing", "spec", "jest", "pytest"],
        "patterns": ["write.*test", "add.*test", "fix.*failing"],
        "intent_phrases": [
          "I want to add tests",
          "help me test this",
          "the tests are failing"
        ]
      },
      "confidence_boost": 0.2  // Boost when matching patterns
    },
    {
      "name": "systematic-debugging",
      "aliases": ["debug", "fix bug", "troubleshoot"],
      "triggers": {
        "keywords": ["bug", "error", "broken", "crash", "fail"],
        "patterns": ["why.*not working", "doesn't work", "getting.*error"],
        "intent_phrases": [
          "something is broken",
          "help me debug",
          "I can't figure out why"
        ]
      }
    }
  ]
}
```

### Fallback Chain (when API unavailable)

```
1. Semantic Similarity → sentence-transformers embedding match
2. Fuzzy Keyword Match → fuzzball.js (0.7 threshold)
3. Pattern Regex → Direct pattern matching
4. Last Resort → Show top 3 most relevant skills as suggestions
```

---

## Part 2: Automatic Memory Management

### Problem Statement
Memory storage is too manual. Learnings, decisions, and solutions get lost between sessions.

### Solution: Multi-Layer Memory System

**Architecture** (inspired by [claude-mem](https://github.com/thedotmack/claude-mem) and [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service)):

```
┌─────────────────────────────────────────────────────────────────┐
│                    Memory Hierarchy                              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Working Memory (session)                              │
│  ├── Current task context                                       │
│  ├── Recent tool outputs                                        │
│  └── Active decisions                                           │
│                                                                 │
│  Layer 2: Short-Term Memory (24h)                               │
│  ├── Today's learnings                                          │
│  ├── Recent solutions                                           │
│  └── Pending follow-ups                                         │
│                                                                 │
│  Layer 3: Long-Term Memory (persistent)                         │
│  ├── Episodic memory archive (already have)                     │
│  ├── Extracted patterns                                         │
│  ├── Project-specific knowledge                                 │
│  └── Cross-project learnings                                    │
│                                                                 │
│  Layer 4: Cross-Machine Memory (synced)                         │
│  ├── Machine registry                                           │
│  ├── Universal configs                                          │
│  └── Platform-specific adaptations                              │
└─────────────────────────────────────────────────────────────────┘
```

### Automatic Capture Hooks

**SessionEnd Hook** - Dream-inspired consolidation:
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

**PostToolUse Hook** - Capture significant outputs:
```javascript
// hooks/tool-output-capture.js
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

### Memory Consolidation Schedule

| Trigger | Action |
|---------|--------|
| Session End | Extract learnings, update short-term |
| Daily (3 AM) | Consolidate short-term → long-term |
| Weekly | Pattern extraction across sessions |
| On Sync | Push to cross-machine repo |

---

## Part 3: Intelligent Auto-Completion

### Problem Statement
No unified auto-completion for skills, plugins, terminal commands, and context-aware suggestions.

### Solution: Multi-Source Completion Engine

**Architecture** (inspired by [autocomplete-sh](https://github.com/closedLoop-technologies/autocomplete-sh) and [fzf](https://github.com/junegunn/fzf)):

```
┌─────────────────────────────────────────────────────────────────┐
│                  Completion Engine                               │
├─────────────────────────────────────────────────────────────────┤
│  Input: User typing...                                          │
│                                                                 │
│  Sources:                                                       │
│  ├── Skills (34 from SuperNavigator)                           │
│  ├── Plugins (superpowers, episodic-memory, supernavigator)    │
│  ├── MCP Tools (beeper, chrome, etc.)                          │
│  ├── Recent Commands (shell history)                           │
│  ├── Project Files (context-aware)                             │
│  └── Memory (past solutions)                                   │
│                                                                 │
│  Ranking:                                                       │
│  1. Semantic relevance (embeddings)                            │
│  2. Recency (recent = higher score)                            │
│  3. Frequency (often used = higher score)                      │
│  4. Context match (file type, project)                         │
│                                                                 │
│  Output: Ranked suggestions with descriptions                   │
└─────────────────────────────────────────────────────────────────┘
```

### Terminal Integration (PowerShell/Bash)

**PowerShell Module** (`complete-claude.psm1`):
```powershell
function Invoke-ClaudeComplete {
    param([string]$Prefix)

    # Query completion engine
    $suggestions = & claude-complete query $Prefix --json

    # Return as PowerShell completions
    $suggestions | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.value,
            $_.display,
            'ParameterValue',
            $_.description
        )
    }
}

Register-ArgumentCompleter -CommandName claude -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    Invoke-ClaudeComplete -Prefix $wordToComplete
}
```

**Bash Integration** (`.bashrc` addition):
```bash
_claude_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(claude-complete query "$cur" --format=bash))
}
complete -F _claude_complete claude
```

### Skill Suggestions Banner

When a skill is auto-detected but not auto-injected (score 0.50-0.65):

```
┌──────────────────────────────────────────────────────────────┐
│ 💡 Suggested Skills                                          │
├──────────────────────────────────────────────────────────────┤
│ • test-driven-development (0.58) - "You mentioned testing"  │
│ • systematic-debugging (0.52) - "Error keyword detected"    │
│                                                              │
│ Type /skill-name to activate, or continue naturally         │
└──────────────────────────────────────────────────────────────┘
```

---

## Part 4: Continuous Learning (Claudeception)

### Problem Statement
Each session starts fresh. Learned patterns and solutions don't persist as skills.

### Solution: Skill Auto-Extraction

**Architecture** (from [Claudeception](https://github.com/blader/Claudeception)):

```
┌─────────────────────────────────────────────────────────────────┐
│                  Skill Extraction Pipeline                       │
├─────────────────────────────────────────────────────────────────┤
│  Trigger: Session ends with meaningful discovery                │
│                                                                 │
│  1. Analyze session for extractable knowledge:                  │
│     - Bug fixes requiring investigation                         │
│     - Non-obvious solutions                                     │
│     - Project-specific patterns                                 │
│     - Environment configurations                                │
│                                                                 │
│  2. Quality gates:                                              │
│     ✓ Required actual discovery (not just docs)                │
│     ✓ Clear trigger conditions                                 │
│     ✓ Verified through testing                                 │
│     ✓ Genuinely useful for future                              │
│                                                                 │
│  3. Generate skill file:                                        │
│     - Create SKILL.md with frontmatter                         │
│     - Include specific trigger patterns                        │
│     - Document the solution                                    │
│                                                                 │
│  4. Store in user skills directory:                            │
│     ~/.claude/skills/auto-extracted/                           │
│                                                                 │
│  5. Sync to cross-machine repo                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Auto-Extracted Skill Example

```markdown
---
name: prisma-serverless-fix
description: Fix PrismaClientKnownRequestError in serverless environments
trigger-patterns:
  - PrismaClientKnownRequestError
  - connection pool exhausted
  - serverless prisma timeout
extracted-from: session-2026-01-24-debug-api
confidence: 0.92
---

# Prisma Serverless Connection Fix

## Problem
PrismaClientKnownRequestError occurs in serverless due to connection pool exhaustion.

## Solution
1. Use connection pooling with PgBouncer or Prisma Accelerate
2. Set `connection_limit = 1` in connection string
3. Implement connection cleanup in handler

## Implementation
[Code examples from the session]
```

---

## Part 5: Implementation Plan

### Phase 1: Foundation (Week 1)

1. **Create skill registry** (`skill-registry.json`)
   - Map all 34 SuperNavigator skills
   - Define aliases, keywords, patterns
   - Add intent phrases

2. **Implement UserPromptSubmit hook**
   - Basic keyword matching
   - Fuzzy fallback with fuzzball.js
   - Session tracking

3. **Set up memory capture hooks**
   - SessionEnd learnings extraction
   - PostToolUse significant output capture

### Phase 2: AI Enhancement (Week 2)

4. **Add Haiku intent analyzer**
   - Confidence scoring (0.0-1.0)
   - Caching layer (MD5, 1hr TTL)
   - Fallback chain

5. **Implement skill suggestions banner**
   - Display for 0.50-0.65 scores
   - Inline activation

6. **Memory consolidation daemon**
   - Daily consolidation script
   - Integration with nav-sync

### Phase 3: Auto-Completion (Week 3)

7. **Build completion engine**
   - Multi-source aggregation
   - Ranking algorithm
   - JSON/bash output formats

8. **Terminal integration**
   - PowerShell module
   - Bash completion function
   - Zsh plugin

### Phase 4: Continuous Learning (Week 4)

9. **Claudeception integration**
   - Session analysis for extractable knowledge
   - Quality gates
   - Skill generation

10. **Cross-machine sync**
    - Auto-extracted skills sync
    - Memory sync
    - Config sync

---

## Project Structure

```
~/.claude/
├── plugins/
│   └── supernavigator/           # Enhanced with these additions
│       └── skills/os-layer/
│           └── intelligence/     # NEW: CLI intelligence skills
│               ├── skill-activator/
│               ├── memory-manager/
│               ├── auto-completer/
│               └── skill-extractor/
├── hooks/
│   ├── skill-intent-hook.js      # UserPromptSubmit
│   ├── memory-capture-hook.js    # SessionEnd
│   └── output-tracker-hook.js    # PostToolUse
├── engine/
│   ├── intent-analyzer.js        # Haiku-powered analysis
│   ├── completion-engine.js      # Multi-source completions
│   ├── memory-consolidator.js    # Layer 2 → Layer 3
│   └── skill-extractor.js        # Claudeception logic
├── data/
│   ├── skill-registry.json       # Pattern → skill mapping
│   ├── skill-cache.json          # Prompt → score cache
│   ├── memory/
│   │   ├── short-term.json       # 24h memory
│   │   └── patterns.json         # Extracted patterns
│   └── completions/
│       └── history.json          # Command/skill history
└── skills/
    └── auto-extracted/           # Claudeception output
```

---

## Dependencies

### npm packages

```json
{
  "dependencies": {
    "fuzzball": "^2.1.2",           // Fuzzy matching
    "sentence-transformers": "^3.0", // Semantic similarity
    "lru-cache": "^10.0.0",         // Efficient caching
    "chokidar": "^3.5.3",           // File watching
    "glob": "^10.3.0"               // Pattern matching
  }
}
```

### API Requirements

- Claude Haiku API access (for intent analysis)
- ~$1-2/month at 100 prompts/day

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

## References

### Core Inspiration

- [claude-skills-supercharged](https://github.com/jefflester/claude-skills-supercharged) - AI-powered skill injection
- [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) - Auto-activation technique
- [Claudeception](https://github.com/blader/Claudeception) - Autonomous skill extraction
- [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) - Dream-inspired memory

### Terminal Tools

- [autocomplete-sh](https://github.com/closedLoop-technologies/autocomplete-sh) - AI terminal completion
- [nl-sh](https://github.com/mikecvet/nl-sh) - Natural Language Shell
- [ai-shell](https://github.com/BuilderIO/ai-shell) - NL to commands
- [fzf](https://github.com/junegunn/fzf) - Universal fuzzy finder

### Memory Systems

- [claude-mem](https://github.com/thedotmack/claude-mem) - Auto context capture
- [episodic-memory](https://github.com/obra/superpowers) - Already installed

### Skills Ecosystem

- [awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) - Curated skill list
- [claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) - 500+ skills

---

## Next Steps

1. **Review this design** - Does it cover your needs?
2. **Prioritize features** - Which part first?
3. **Begin implementation** - Start with Phase 1 foundation

---

*This design synthesizes insights from 20+ GitHub projects into a unified system tailored for your cross-machine ecosystem.*
