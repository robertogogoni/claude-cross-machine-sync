# Beeper Knowledge Base (beeper-kb) Design

**Date**: 2026-02-15
**Status**: Approved
**Approach**: B — Custom RAG Pipeline + MCP Wrapper (with Approach C migration path)

---

## Overview

Build a comprehensive, searchable knowledge base containing every piece of technical
information from the Beeper Developer Community (Aug 2025 → present). Exposed as an
MCP server for use in any Claude Code session.

**User Choices**:
- Storage: RAG with FAISS/Embeddings
- Scope: Full harvest (community chat, docs, GitHub repos, blog)
- Embeddings: Anthropic/Voyage API
- Future: Leave room for rag-anything-mcp (Approach C) migration

---

## Architecture

```
DATA SOURCES → HARVESTER (Node.js) → EMBEDDING (Voyage) → STORAGE (SQLite + FAISS) → MCP SERVER
```

### Data Sources

| Source | Method | Volume | Frequency |
|--------|--------|--------|-----------|
| Matrix Community Chat | Beeper MCP `list_messages` + pagination | ~5K-10K msgs | Initial full + incremental |
| developers.beeper.com | WebFetch → markdown | ~20-30 pages | Weekly |
| GitHub Repos | GitHub MCP → READMEs, changelogs, issues | ~15 repos | Weekly |
| blog.beeper.com | WebFetch → article extraction | ~20-40 articles | Monthly |
| Existing Knowledge | Import `.md` files | 2 files (~1,250 lines) | One-time seed |

### Key Matrix Rooms

| Room | Members | Content |
|------|---------|---------|
| `#beeper-sdk:beeper.com` | 512 | Developer API discussion, bug reports, feature requests |
| `#self-hosting:beeper.com` | 1,348 | Bridge setup, self-hosting guides |
| `#beepserv:beeper.com` | 373 | Infrastructure, server-side topics |

---

## Storage Schema

### SQLite (`~/.beeper-kb/beeper-kb.sqlite`)

```sql
CREATE TABLE documents (
  id          TEXT PRIMARY KEY,
  source      TEXT NOT NULL,        -- 'matrix-chat' | 'docs' | 'github' | 'blog' | 'seed'
  source_id   TEXT,
  room        TEXT,
  author      TEXT,
  title       TEXT,
  content     TEXT NOT NULL,
  chunk_index INTEGER DEFAULT 0,
  parent_id   TEXT,
  created_at  TEXT NOT NULL,
  ingested_at TEXT NOT NULL,
  metadata    TEXT                  -- JSON blob
);

CREATE TABLE tags (
  doc_id  TEXT REFERENCES documents(id),
  tag     TEXT NOT NULL,
  PRIMARY KEY (doc_id, tag)
);

CREATE TABLE harvest_state (
  source      TEXT PRIMARY KEY,
  last_cursor TEXT,
  last_run    TEXT,
  doc_count   INTEGER DEFAULT 0
);

CREATE VIRTUAL TABLE documents_fts USING fts5(
  content, title, author, source,
  content=documents, content_rowid=rowid
);
```

### FAISS Index (`~/.beeper-kb/vectors.faiss`)

- Dimension: 1024 (Voyage `voyage-3`)
- Index: `IndexFlatIP` (exact inner product search)
- Mapping: `~/.beeper-kb/id_map.json` (FAISS row → document UUID)

---

## Chunking Strategy

- Target: ~500 tokens per chunk with 50-token overlap
- Chat messages: Group consecutive messages by author + time proximity into conversation turns
- Web pages: Split by headers (h2/h3), then by paragraph if section exceeds target
- Code blocks: Keep intact (never split mid-code)

---

## MCP Server Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `kb_search` | Semantic + FTS5 hybrid search | `query`, `limit?`, `source?`, `dateRange?` |
| `kb_ingest` | Add document manually | `content`, `source`, `title?`, `tags?` |
| `kb_harvest` | Trigger fresh data collection | `sources?`, `full?` |
| `kb_stats` | Collection statistics | — |
| `kb_browse` | Browse by category/date/source | `source?`, `tag?`, `author?`, `limit?`, `offset?` |

### MCP Resources

| URI | Description |
|-----|-------------|
| `beeper-kb://stats` | Current KB statistics |
| `beeper-kb://sources` | Available data sources |
| `beeper-kb://recent` | Recently added documents |

---

## Project Structure

```
~/repos/beeper-kb/
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── src/
│   ├── index.ts              # MCP server entry point
│   ├── db.ts                 # SQLite + FAISS initialization
│   ├── embeddings.ts         # Voyage API client
│   ├── chunker.ts            # Text chunking logic
│   ├── harvester/
│   │   ├── index.ts          # Harvester orchestrator
│   │   ├── matrix-chat.ts    # Beeper MCP chat extractor
│   │   ├── dev-docs.ts       # developers.beeper.com crawler
│   │   ├── github-repos.ts   # GitHub repo scanner
│   │   ├── blog.ts           # Blog article fetcher
│   │   └── seed.ts           # Import existing .md files
│   ├── search.ts             # Hybrid FAISS + FTS5 search
│   ├── tools/
│   │   ├── kb-search.ts
│   │   ├── kb-ingest.ts
│   │   ├── kb-harvest.ts
│   │   ├── kb-stats.ts
│   │   └── kb-browse.ts
│   └── types.ts
├── tests/
│   ├── chunker.test.ts
│   ├── search.test.ts
│   ├── harvester/
│   │   ├── matrix-chat.test.ts
│   │   └── seed.test.ts
│   └── tools/
│       ├── kb-search.test.ts
│       └── kb-ingest.test.ts
└── data/
    └── seed/
```

### Dependencies

| Package | Purpose |
|---------|---------|
| `@modelcontextprotocol/sdk` | MCP framework |
| `better-sqlite3` | SQLite with FTS5 |
| `faiss-node` | FAISS vector index |
| `zod` | Input validation |
| Voyage API (raw fetch) | Embedding generation |

---

## Implementation Phases

| Phase | Description | Key Deliverable |
|-------|-------------|-----------------|
| 1. Core | SQLite schema, chunker, Voyage client, FAISS init | Working storage layer |
| 2. Seed | Import existing community analysis + learnings | First searchable content |
| 3. Chat Harvester | Beeper MCP integration, pagination, grouping | Community chat indexed |
| 4. Web Harvesters | Dev docs, GitHub, blog crawlers | External sources indexed |
| 5. MCP Server | 5 tools + 3 resources registered | Queryable from Claude Code |
| 6. Testing | Unit + integration tests | Quality gate |
| 7. Deploy | Register in ~/.claude.json, full initial harvest | Production ready |

---

## Approach C Migration Path

When ready to upgrade to `rag-anything-mcp` (hybrid vector-graph):
1. Export SQLite documents → rag-anything-mcp document format
2. Port FAISS vectors (same format, rag-anything-mcp supports FAISS)
3. Convert tags → graph edges (tag → relates_to → document)
4. Keep same MCP tool interface (kb_search, kb_ingest, etc.)
5. Add graph-specific queries (relationship traversal, concept clusters)

The SQLite schema and metadata JSON column are intentionally designed for this portability.

---

## Configuration

Add to `~/.claude.json`:
```json
{
  "mcpServers": {
    "beeper-kb": {
      "command": "node",
      "args": ["~/repos/beeper-kb/dist/index.js"],
      "env": {
        "VOYAGE_API_KEY": "...",
        "BEEPER_KB_DATA_DIR": "~/.beeper-kb"
      }
    }
  }
}
```

---

## Existing Knowledge to Seed

| File | Lines | Content |
|------|-------|---------|
| `~/.claude/beeper-developer-community-analysis.md` | 539 | Community analysis (Sep 2025 → Jan 2026) |
| `~/claude-cross-machine-sync/learnings/beeper.md` | 710+ | Technical knowledge base |
| `~/claude-cross-machine-sync/docs/plans/2026-02-15-beeper-extended-v2-design.md` | 260 | Plugin design doc |
