# Memory Persistence Solutions for Claude Code

**Research Date**: 2026-01-26
**Goal**: Achieve true cross-session memory for Claude Code

---

## Executive Summary

This research covers all available approaches to making Claude Code remember context across sessions. The solutions range from Anthropic's official features to community-built tools.

### Quick Recommendation

| Use Case | Best Solution | Effort | Maturity |
|----------|---------------|--------|----------|
| **Immediate use** | Episodic Memory Plugin (already installed) | Low | High |
| **Team knowledge** | CLAUDE.md + .claude/rules/ | Low | Official |
| **Autonomous learning** | claude-mem + Claudeception | Medium | Community |
| **Knowledge graph** | @modelcontextprotocol/server-memory | Medium | Official |
| **Full autonomy** | Custom SessionEnd hook + AI extraction | High | Custom |

---

## Part 1: Anthropic Official Solutions

### 1.1 Claude Memory (Web/Desktop) - September 2025

**What it is**: Anthropic's official persistent memory for Claude.ai, later expanded to Claude Code.

**Key Details**:
- Rolled out to Team/Enterprise September 2025
- Pro/Max users October 2025
- Uses CLAUDE.md file-based approach (not vector database)
- Memory loaded into 200K context window

**How it works**:
- All memory files loaded at session start
- Hierarchical: Enterprise → Project → User → Local
- Supports imports via `@path/to/file` syntax
- Recursive discovery from cwd to root

**Limitations**:
- No auto-learning (manual updates required)
- "Fading memory" effect with large files
- Limited to context window size

**Sources**:
- [Claude AI Gains Persistent Memory](https://www.reworked.co/digital-workplace/claude-ai-gains-persistent-memory-in-latest-anthropic-update/)
- [Claude Memory Deep Dive](https://skywork.ai/blog/claude-memory-a-deep-dive-into-anthropics-persistent-context-solution/)
- [Claude Code Memory Docs](https://code.claude.com/docs/en/memory)

---

### 1.2 Claude Code Memory System

**File Hierarchy**:
```
/etc/claude-code/CLAUDE.md          # Enterprise (Linux)
~/.claude/CLAUDE.md                  # User global
./CLAUDE.md or ./.claude/CLAUDE.md   # Project
./.claude/rules/*.md                 # Modular rules
./CLAUDE.local.md                    # Personal (gitignored)
```

**Best Practices**:
- Keep files lean (<2000 tokens ideal)
- Be specific: "Use 2-space indentation" not "format code properly"
- Use `.claude/rules/` for modular organization
- Path-scoped rules with YAML frontmatter
- Import reference files with `@docs/filename.md`

**Key Commands**:
- `/init` - Bootstrap project memory
- `/memory` - View/edit memory files
- `# <text>` - Quick add to memory

**Sources**:
- [Claude Code Memory Docs](https://code.claude.com/docs/en/memory)
- [Memory Management Best Practices](https://medium.com/@codecentrevibe/claude-code-best-practices-memory-management-7bc291a87215)

---

### 1.3 Memory Tool (API) - September 2025

**What it is**: Beta API feature for Claude agents to store/retrieve memory.

**Location**: `/memory` directory in agent sandbox

**Operations**: Create, read, update, delete files in memory directory

**Use case**: Building agents that maintain state across conversations

**Source**: [Memory Tool Docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)

---

## Part 2: Official MCP Memory Server

### 2.1 @modelcontextprotocol/server-memory

**What it is**: Anthropic's official knowledge graph memory server.

**Installation**:
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "~/.claude/memory/knowledge-graph.jsonl"
      }
    }
  }
}
```

**Knowledge Graph Structure**:
- **Entities**: Nodes with name, type, observations
- **Relations**: Directed edges in active voice
- **Observations**: Atomic facts attached to entities

**Available Tools**:
- `create_entities` - Add nodes
- `create_relations` - Add edges
- `add_observations` - Add facts to entities
- `search_nodes` - Query by name/type/content
- `read_graph` - Full graph dump

**Pros**:
- Official, maintained by Anthropic
- Works with Claude Desktop and Claude Code
- Knowledge graph > flat memory

**Cons**:
- Requires manual `create_entity` calls
- No auto-extraction
- No semantic search

**Sources**:
- [npm package](https://www.npmjs.com/package/@modelcontextprotocol/server-memory)
- [GitHub source](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)

---

## Part 3: Community MCP Memory Servers

### 3.1 mcp-memory-service (doobidoo) ⭐ Recommended

**Stars**: 500+ | **Last Update**: Active

**Features**:
- Semantic search with AI embeddings
- 5ms retrieval speed
- Hybrid storage (local + cloud sync)
- Dream-inspired consolidation (decay, compression, archival)
- Works with Claude Code, VS Code, Cursor

**Installation**:
```json
{
  "mcpServers": {
    "memory-service": {
      "command": "npx",
      "args": ["-y", "mcp-memory-service"]
    }
  }
}
```

**Source**: [GitHub](https://github.com/doobidoo/mcp-memory-service)

---

### 3.2 mcp-memory-keeper (mkreyman)

**Features**:
- Persistent context for Claude Code
- SQLite storage at `~/mcp-data/memory-keeper/`
- Survives compaction/context limits
- Focus on coding assistant use case

**Source**: [GitHub](https://github.com/mkreyman/mcp-memory-keeper)

---

### 3.3 claude-memory-mcp (WhenMoon-afk)

**Features**:
- Local-only (privacy-focused)
- SQLite + FTS5 for full-text search
- Lightweight TypeScript implementation
- Storage: `~/.memory-mcp/memory.db`

**Source**: [GitHub](https://github.com/WhenMoon-afk/claude-memory-mcp)

---

### 3.4 mcp-knowledge-graph (shaneholloman)

**Features**:
- Local knowledge graph
- Entities, relations, observations
- Works with any MCP-compatible platform

**Source**: [GitHub](https://github.com/shaneholloman/mcp-knowledge-graph)

---

### 3.5 claude-continuity (donthemannn)

**Features**:
- Conversation continuity focus
- Handles token limit exhaustion
- Session handoff between conversations

**Source**: [GitHub](https://github.com/donthemannn/claude-continuity)

---

### 3.6 CCMem - Claude Code Memory (adestefa)

**Features**:
- Specifically for Claude Code
- Project memory focus
- Context-aware development assistance

**Source**: [GitHub](https://github.com/adestefa/ccmem)

---

## Part 4: Auto-Learning Plugins

### 4.1 Claudeception ⭐ Highly Recommended

**What it is**: Autonomous skill extraction and continuous learning.

**How it works**:
1. Hook injects reminder on every prompt
2. Claude evaluates if task produced extractable knowledge
3. If yes, creates new skill with retrieval-optimized description
4. Skills loaded at future session starts

**What gets extracted**:
- Non-obvious debugging solutions
- Project-specific patterns
- Tool integration knowledge
- Workarounds and fixes

**Research foundations**:
- Voyager (2023) - Game agents building skill libraries
- CASCADE (2024) - Meta-skills for acquiring skills
- SEAgent (2025) - Learning software environments

**Installation**:
```bash
# Clone to skills directory
git clone https://github.com/blader/Claudeception ~/.claude/skills/claudeception
```

**Source**: [GitHub](https://github.com/blader/Claudeception)

---

### 4.2 claude-mem (thedotmack)

**What it is**: Automatic session capture and context injection.

**How it works**:
1. Captures all tool usage during sessions
2. Uses Claude Agent SDK to compress/summarize
3. Injects relevant context at session start

**Hooks used**:
- SessionStart - Load relevant memories
- UserPromptSubmit - Track context
- PostToolUse - Capture observations
- Stop - Generate summary
- SessionEnd - Save state

**Source**: [GitHub](https://github.com/thedotmack/claude-mem)

---

### 4.3 claude-skills-automation (Toowiredd)

**What it is**: Zero-friction memory and context management.

**Features**:
- SessionEnd hook saves session state (50ms)
- Stop hook extracts decision/blocker patterns (200ms)
- Auto-extracted memories in `~/.claude-memories/`

**Source**: [GitHub](https://github.com/Toowiredd/claude-skills-automation)

---

### 4.4 claude-diary (rlancemartin)

**What it is**: Long-term memory plugin that learns from activity.

**How it works**:
- Observes your patterns over time
- Auto-updates CLAUDE.md with learnings
- Improves Claude's understanding of preferences

**Source**: [GitHub](https://github.com/rlancemartin/claude-diary)

---

### 4.5 Continuous-Claude-v3 (parcadei)

**What it is**: Context management with compounding learnings.

**Key concept**: "Each session makes the system smarter—learnings accumulate like compound interest."

**State flow**: SessionStart → Working → SessionEnd (saves Handoff, Learnings, Outcome)

**Source**: [GitHub](https://github.com/parcadei/Continuous-Claude-v3)

---

## Part 5: Currently Installed (Your Setup)

### 5.1 Episodic Memory Plugin

**Status**: ✅ Installed and working

**What it does**:
- Archives all conversations to `~/.config/superpowers/conversation-archive/`
- Provides semantic search across history
- MCP tools for Claude to query memories

**Usage**:
- `/episodic-memory:search-conversations "keyword"`
- Multi-concept AND search with arrays

**Limitation**: Requires explicit search (not auto-loaded)

---

### 5.2 CLAUDE.md (Cross-Machine Sync)

**Status**: ✅ Configured

**Location**: `~/.claude/CLAUDE.md` (synced via git)

**Limitation**: Manual updates only

---

## Part 6: Recommended Implementation Plan

### Phase 1: Enhance Current Setup (1 hour)

1. Install official memory server:
```json
// Add to ~/.claude.json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/home/rob/.claude/memory/knowledge-graph.jsonl"
      }
    }
  }
}
```

2. Configure episodic memory to search before debugging (already have nav-search skill)

### Phase 2: Add Auto-Learning (2 hours)

1. Install Claudeception:
```bash
git clone https://github.com/blader/Claudeception ~/.claude/skills/claudeception
```

2. Install claude-mem for session capture:
```bash
# Follow installation from GitHub
```

### Phase 3: Custom SessionEnd Hook (4 hours)

Create hook that:
1. Analyzes session at end
2. Extracts key learnings
3. Updates CLAUDE.md automatically
4. Syncs to claude-cross-machine-sync repo

### Phase 4: Full Autonomy (Future)

- Implement "dream-inspired" consolidation
- Daily/weekly learning aggregation
- Cross-machine memory sync daemon

---

## Part 7: AUR Packages

### Available Packages

| Package | Description | Status |
|---------|-------------|--------|
| `claude-code` | Official Claude Code CLI | Works |
| `claude-desktop-native` | Native Linux desktop app | Recommended |
| `claude-desktop-bin` | Electron-based desktop | Has MCP issues |
| `claude-desktop` | Alternative build | Available |

### MCP on Arch Linux

- MCP servers communicate via STDIO (no network)
- Docker optional dependency for isolated servers
- Filesystem MCP may need path fix in Electron build

**Sources**:
- [claude-code AUR](https://aur.archlinux.org/packages/claude-code)
- [claude-desktop-native AUR](https://aur.archlinux.org/packages/claude-desktop-native)

---

## Part 8: Future Developments

### Anthropic Roadmap (Leaked/Announced)

- Continuous learning ("not as difficult as it seems" - Dario Amodei)
- 2026 expected to be "year of continuous learning" in Silicon Valley
- Claude Cowork "permanent memory" in development

### Research Directions

- Agents learning from mistakes mid-task (Stanford/SambaNova ACE)
- Knowledge graph + vector hybrid storage
- Real-time memory sync across devices

---

## Quick Reference: All GitHub Links

### Official
- [@modelcontextprotocol/server-memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)

### MCP Servers
- [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) ⭐
- [mcp-memory-keeper](https://github.com/mkreyman/mcp-memory-keeper)
- [claude-memory-mcp](https://github.com/WhenMoon-afk/claude-memory-mcp)
- [mcp-knowledge-graph](https://github.com/shaneholloman/mcp-knowledge-graph)
- [claude-continuity](https://github.com/donthemannn/claude-continuity)
- [CCMem](https://github.com/adestefa/ccmem)
- [better-memory-mcp](https://github.com/sockeye44/better-memory-mcp)

### Auto-Learning
- [Claudeception](https://github.com/blader/Claudeception) ⭐
- [claude-mem](https://github.com/thedotmack/claude-mem)
- [claude-skills-automation](https://github.com/Toowiredd/claude-skills-automation)
- [claude-diary](https://github.com/rlancemartin/claude-diary)
- [Continuous-Claude-v3](https://github.com/parcadei/Continuous-Claude-v3)

### Utilities
- [memory-visualizer](https://github.com/mjherich/memory-visualizer)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase)

---

*This research will be kept updated as new solutions emerge.*
