# Cortex Project Reference

## Overview
- **Name**: Cortex — Claude's Cognitive Memory Layer
- **Version**: 3.0.0
- **Repo (GitHub)**: `robertogogoni/cortex-claude`
- **Installed copy**: `~/.claude/memory/`
- **Language**: Node.js (CommonJS, `.cjs` extension throughout)
- **Module count**: ~58 `.cjs` files
- **Test files**: 22 test files, ~12,078 lines total
- **Tests passing**: 447+

## Architecture

### Core Modules (`core/`)
| Module | Purpose |
|--------|---------|
| `types.cjs` | Shared types, `expandPath()` utility |
| `rate-limiter.cjs` | Sliding window rate limiter (per-tool, burst 3x, cooldown 10s) |
| `api-key.cjs` | API key detection and source identification |
| `embedder.cjs` | Singleton embedding engine (Xenova/transformers) |
| `query-cache.cjs` | MD5-keyed query result cache |

### Adapters (`adapters/`, 10 adapters)
| Adapter | Source | Type |
|---------|--------|------|
| `jsonl-adapter.cjs` | Local JSONL files (working/short-term/long-term) | File-based |
| `claudemd-adapter.cjs` | CLAUDE.md files | File-based |
| `episodic-memory-adapter.cjs` | Episodic Memory MCP plugin | MCP |
| `knowledge-graph-adapter.cjs` | Knowledge Graph MCP server | MCP |
| `warp-sqlite-adapter.cjs` | Warp Terminal AI history | SQLite |
| `gemini-adapter.cjs` | Google Gemini/Antigravity sessions | File-based |
| `vector-adapter.cjs` | Local vector search (hnswlib-node) | Native |
| `episodic-annotations-layer.cjs` | Annotation overlay for episodic results | Layer |
| `base-adapter.cjs` | Abstract base class | Base |
| `index.cjs` | Adapter registry and loading | Registry |

### Hooks (`hooks/`)
| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start.cjs` | SessionStart | Memory injection into Claude context |
| `injection-formatter.cjs` | (library) | Formats memories in rich/compact/xml/markdown |
| `cli-renderer.cjs` | (library) | CLI output: spinners, progress bars, banners |

### CLI (`bin/cortex.cjs`)
- Single 29KB entry point
- Commands: `search`, `status`, `learn`, `consolidate`, `setup-key`
- Subcommands route to adapters and core modules

### Storage (`data/`)
```
data/memories/
├── working.jsonl      # High-priority, current session
├── short-term.jsonl   # 7-day sliding window
└── long-term.jsonl    # Permanent storage
data/skills/
└── index.jsonl        # Extracted procedures
data/cache/
└── query-cache.json   # MD5-keyed result cache
```

## Native Dependencies
- `better-sqlite3` — SQLite access for Warp adapter
- `hnswlib-node` — HNSW vector index for semantic search
- `@xenova/transformers` — Embedding model (all-MiniLM-L6-v2)

## Rate Limits (per tool)
| Tier | Tools | Per Minute | Per Hour | Per Day |
|------|-------|-----------|----------|---------|
| Haiku (cheap) | query, recall | 120 | 3,000 | 50,000 |
| Sonnet (expensive) | reflect, infer, learn | 60 | 600 | 5,000 |
| Consolidate | consolidate | 30 | 300 | 2,000 |

## Key Design Decisions
- **Zero external runtime deps** for CLI rendering (no chalk, ora, etc.)
- **Clack-style box-drawing** characters (╭╰├│) instead of emojis for alignment
- **Text markers** (learn, pattern, skill, fix, pref, memo) instead of emoji icons
- **Backward-compat aliases**: `getStatus()` → `getStats()` for stale MCP processes
- **Embedder singleton**: Shared across adapters to avoid model reload (~2s savings)
- **Parallelized Haiku calls**: Concurrent API requests for multi-adapter queries

## Performance Benchmarks (2026-02-26)
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Average | 7.01s | 6.08s | -13% |
| P50 | 7.35s | 5.56s | -24% |
| API calls | 45 | 30 | -33% |

## Plan Documents

### Master Index
**Start here**: [`2026-03-02-cortex-implementation-index.md`](~/repos/cortex-claude/docs/plans/2026-03-02-cortex-implementation-index.md) — links all phase plans, dependency graph, file inventory

### Early Design Docs
| Plan | Scope |
|------|-------|
| `2026-01-26-cortex-cognitive-layer-design.md` | Original v1 design |
| `2026-01-27-cortex-ux-enhancements.md` | UX improvements |
| `2026-02-01-cortex-adapter-expansion.md` | Adding more adapters |

### v3 Roadmap & Design Documents
| Plan | Scope |
|------|-------|
| `2026-02-25-cortex-v3-full-transformation.md` | Phases A-G (original master plan, ~1500 lines) |
| `2026-02-25-cortex-cli-renderer-design.md` | Phase CR: CortexRenderer class design |
| `2026-02-25-cortex-cli-renderer-plan.md` | Phase CR: implementation plan |
| `2026-03-02-cortex-unified-roadmap-phases-h-k.md` | Phases H-K: high-level design, dependencies, cost analysis |
| `2026-03-02-cortex-implementation-index.md` | **Master index**: all phases A-K with links |

### Individual Phase TDD Plans (test-first code for every task)
| Plan | Phase | Tasks | Est. Days |
|------|-------|-------|-----------|
| `2026-03-02-cortex-phase-f-implementation.md` | F: Research-Backed Retrieval | 5 | 7 |
| `2026-03-02-cortex-phase-g-implementation.md` | G: Memory Lifecycle | 3 | 5 |
| `2026-03-02-cortex-phase-h-implementation.md` | H: Human-Readable Bridge | 10 | 10 |
| `2026-03-02-cortex-phase-i-implementation.md` | I: Memory Intelligence | 11 | 10 |
| `2026-03-02-cortex-phase-j-implementation.md` | J: Advanced Memory Science | 7 | 15 |
| `2026-03-02-cortex-phase-k-implementation.md` | K: Ecosystem & Platform | 8 | 15 |

All phase files are cross-referenced: each links to the master index and unified roadmap.

## v3.0 Transformation Roadmap
**Master plan**: `docs/plans/2026-02-25-cortex-v3-full-transformation.md`
**Master index**: `docs/plans/2026-03-02-cortex-implementation-index.md`
**Total scope**: 11 phases (A-K), 86 tasks, ~90 estimated days

### 11 Phases (A-K)
| Phase | Name | Version | Tasks | Status |
|-------|------|---------|-------|--------|
| A | Ship | v2.0.0 | 5 | **DONE** |
| E | Direct SQLite | v2.1.0 | 4 | **DONE** |
| B | Core Engine (Dual-path LLM) | v3.0.0 | 9 | **TDD Plan Ready** |
| C | Quality Engine | v3.0.0 | 5 | **TDD Plan Ready** |
| CR | CortexRenderer | v3.0.0 | 11 | **TDD Plan Ready** |
| D | Distribution | v3.0.0 | 3 | **TDD Plan Ready** |
| F | Research-Backed Retrieval | v3.0.0 | 5 | TDD Plan Ready |
| G | Memory Lifecycle | v3.0.0 | 3 | TDD Plan Ready |
| H | Human-Readable Bridge | v3.1.0 | 10 | TDD Plan Ready |
| I | Memory Intelligence | v3.2.0 | 11 | TDD Plan Ready |
| J | Advanced Memory Science | v3.3.0 | 7 | TDD Plan Ready |
| K | Ecosystem & Platform | v3.4.0 | 8 | TDD Plan Ready |

### Key Dependency Chain
```
A ✅ → B (Dual-path: DirectAPI primary + MCP Sampling stub)
E ✅ ┘     → C, D, F → G → H → I → J → K
Phase CR runs in parallel (no deps on B-K)
```

### Key v3 Features
- **Dual-path LLM**: DirectApiProvider (primary, Anthropic SDK) + SamplingProvider (future stub, auto-detected via MCP capabilities). MCP Sampling NOT yet supported in Claude Code (#1785).
- **PreCompact hook**: Captures context just before Claude compresses conversation (catches context that would otherwise be lost)
- **Triple-hook capture**: SessionStart (inject) + PreCompact (save) + SessionEnd (consolidate)
- **Write gates**: Prevent duplicate/low-quality memories from being stored
- **Bi-temporal memory**: Track both "when did we learn this" and "when was this true"
- **Confidence decay**: Memory reliability decreases over time unless reinforced
- **FTS5 full-text search**: Phase F adds SQLite FTS5 for keyword retrieval alongside vector search
- **Human-readable bridge**: Phase H adds Markdown-based topic files as a readable layer over JSONL
- **Spaced repetition**: Phase J integrates FSRS-6 algorithm for memory scheduling
- **Multi-instance mesh**: Phase K enables Cortex instances to sync across machines

### Research Behind v3
- 37 web searches across competitor projects
- 15+ memory/MCP projects analyzed
- 4 academic papers: Voyager (2023), CASCADE (2024), SEAgent (2025), MemoryBank
- Key competitors: mem0, Letta, cognee, mcp-memory-service
- Phase J adds: FSRS-6 (spaced repetition), RL-based memory routing
