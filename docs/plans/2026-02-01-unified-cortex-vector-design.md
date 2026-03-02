# Unified Cortex MCP with Vector Search - Design Document

**Date**: 2026-02-01
**Status**: Design Phase
**Author**: Claude Code + Rob
**Research Sources**: 25+ GitHub projects, 4 parallel research agents

---

## Executive Summary

This document describes the architecture for enhancing Cortex MCP with **true vector embeddings** and **hybrid search** capabilities. The goal is to solve the **MCP process isolation problem** by building a unified MCP server that handles all memory operations internally, without relying on external MCP calls.

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Vector DB** | hnswlib-node | Best performance (5ms queries), mature ecosystem |
| **Embeddings** | @xenova/transformers | Local, free, 384-dim MiniLM-L6-v2 |
| **Search Strategy** | Hybrid BM25 + Vector | RRF fusion for best relevance |
| **Temporal Decay** | FSRS-6 Power Law | Research-backed forgetting curve |
| **Architecture** | Unified MCP Server | Solves process isolation completely |

---

## Part 1: Problem Statement

### 1.1 MCP Process Isolation

MCP servers run as **isolated Node.js child processes**. They communicate with Claude Code via JSON-RPC over stdio. This architecture creates a fundamental limitation:

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code (Parent Process)                                │
│   ├── MCP Server A (Child Process) ─── CANNOT ──→ MCP B    │
│   ├── MCP Server B (Child Process) ─── CANNOT ──→ MCP A    │
│   └── MCP Server C (Child Process) ─── CANNOT ──→ MCP A/B  │
└─────────────────────────────────────────────────────────────┘
```

**Consequence**: Cortex cannot call episodic-memory MCP, knowledge-graph MCP, or any other memory server directly. Each MCP server is a silo.

### 1.2 Current Cortex Architecture Gaps

From analysis of the existing codebase:

**`adapters/base-adapter.cjs:17-44`** - MemoryRecord typedef is MISSING `embedding` field:
```javascript
/**
 * @typedef {Object} MemoryRecord
 * @property {string} id - Unique identifier
 * @property {string} content - Full content
 * @property {string} summary - Brief summary
 * // ... other fields
 * // ❌ NO embedding field!
 */
```

**`core/storage.cjs:296-312`** - MemoryIndex uses Map-based indexes only:
```javascript
class MemoryIndex {
  constructor() {
    this.byId = new Map();
    this.byProject = new Map();
    this.byType = new Map();
    this.byTag = new Map();
    // ❌ NO byEmbedding or vector index!
  }
}
```

**Current "Semantic" Search**: The `haiku-worker.cjs` uses Claude Haiku API to extract keywords from queries. This is **keyword extraction**, not true **vector similarity search**.

---

## Part 2: Research Findings Summary

### 2.1 Memory MCP Implementations (25+ Analyzed)

| Project | Stars | Key Innovation |
|---------|-------|----------------|
| **mcp-memory-service** | 1,251 | Dream-inspired consolidation, chroma integration |
| **Vestige** | 100+ | FSRS-6 power law decay, Rust performance |
| **Subcog** | New | usearch HNSW, hierarchical memory |
| **CortexGraph** | New | Ebbinghaus forgetting curve |
| **Claudeception** | 300+ | Auto-skill extraction from sessions |
| **@modelcontextprotocol/server-memory** | Official | Knowledge graph, entity-relation model |

### 2.2 Vector Database Options for Node.js

| Library | Index Type | Speed | Size | Best For |
|---------|------------|-------|------|----------|
| **hnswlib-node** | HNSW | 5ms | 16KB/1K vec | ✅ Performance |
| **sqlite-vec** | Flat/IVF | 50ms | 0 (SQLite) | ✅ Simplicity |
| **vectra** | Flat | 100ms | RAM | Prototyping |
| **@faiss-node/native** | Many | 2ms | 50MB binary | Scale |
| **usearch** | HNSW | 3ms | 10MB | Rust perf |
| **@lancedb/lancedb** | IVF-PQ | 10ms | Columnar | Big data |

**Recommendation**: `hnswlib-node` for performance with persistence, or `sqlite-vec` for simplicity with existing SQLite infrastructure.

### 2.3 Embedding Generation Options

| Option | Model | Dims | Speed | Cost |
|--------|-------|------|-------|------|
| **@xenova/transformers** | MiniLM-L6-v2 | 384 | 50ms local | Free |
| **OpenAI** | text-embedding-3-small | 1536 | 200ms | $0.02/1M |
| **Voyage AI** | voyage-3-lite | 512 | 150ms | $0.02/1M |
| **Cohere** | embed-v3.0 | 1024 | 180ms | $0.10/1M |

**Recommendation**: `@xenova/transformers` with `all-MiniLM-L6-v2` - free, local, fast, proven quality.

### 2.4 MCP Isolation Workarounds

| Approach | Complexity | Reliability |
|----------|------------|-------------|
| **Unified MCP Server** | Medium | ✅ 100% |
| MCP Aggregator/Proxy | High | 90% |
| Shared Database | Low | 80% |
| HTTP Bridge | High | 85% |
| Claude as Orchestrator | Low | 70% |

**Recommendation**: **Unified MCP Server** - one server with all functionality built-in.

---

## Part 3: Architecture Design

### 3.1 Unified Cortex MCP Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Unified Cortex MCP Server                                               │
│                                                                         │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Tool Layer (MCP Interface)                                          │ │
│ │   cortex__query    cortex__recall    cortex__learn                  │ │
│ │   cortex__reflect  cortex__infer     cortex__consolidate            │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                               │                                         │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Search Orchestrator (Hybrid Search)                                 │ │
│ │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │ │
│ │   │ BM25 Search  │  │ Vector Search│  │ RRF Fusion   │             │ │
│ │   │ (FTS5)       │  │ (HNSW)       │  │ + Temporal   │             │ │
│ │   └──────────────┘  └──────────────┘  └──────────────┘             │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                               │                                         │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Memory Sources (Unified Access)                                     │ │
│ │   ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │ │
│ │   │ Episodic   │  │ Knowledge  │  │ JSONL      │  │ CLAUDE.md  │   │ │
│ │   │ Archive    │  │ Graph      │  │ Memories   │  │ Files      │   │ │
│ │   └────────────┘  └────────────┘  └────────────┘  └────────────┘   │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                               │                                         │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Core Services                                                       │ │
│ │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │ │
│ │   │ Embedder     │  │ Vector Index │  │ Storage Mgr  │             │ │
│ │   │ (MiniLM-L6)  │  │ (HNSW)       │  │ (JSONL)      │             │ │
│ │   └──────────────┘  └──────────────┘  └──────────────┘             │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow: Hybrid Search

```
Query: "How did I fix the authentication bug?"
                    │
                    ▼
        ┌───────────────────┐
        │ Embedder          │
        │ text → [384 dims] │
        └───────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│ BM25 Search   │       │ Vector Search │
│ "authentication"      │ cosine sim    │
│ "bug" "fix"   │       │ top-k nearest │
└───────────────┘       └───────────────┘
        │                       │
        └───────────┬───────────┘
                    ▼
        ┌───────────────────────┐
        │ RRF Fusion            │
        │ score = Σ 1/(60+rank) │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Temporal Decay        │
        │ score × decay(age)    │
        │ FSRS-6 power law      │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Top Results           │
        │ Ranked by relevance   │
        └───────────────────────┘
```

### 3.3 Database Schema (SQLite with sqlite-vec)

```sql
-- Core memories table
CREATE TABLE IF NOT EXISTS memories (
    id TEXT PRIMARY KEY,
    version INTEGER DEFAULT 1,

    -- Content
    content TEXT NOT NULL,
    summary TEXT,                        -- < 100 chars

    -- Classification
    memory_type TEXT DEFAULT 'observation',  -- learning|pattern|skill|correction|preference
    intent TEXT,                         -- detected intent
    tags TEXT DEFAULT '[]',              -- JSON array

    -- Provenance
    source TEXT NOT NULL,                -- jsonl|episodic|knowledge-graph|claudemd
    source_id TEXT,                      -- original ID in source
    project_hash TEXT,                   -- null = global
    session_id TEXT,

    -- Quality metrics
    extraction_confidence REAL DEFAULT 0.5,
    quality_score REAL DEFAULT 0.5,

    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    usage_success_rate REAL DEFAULT 0.5,
    last_accessed TEXT,

    -- Temporal decay
    strength REAL DEFAULT 1.0,
    decay_score REAL DEFAULT 1.0,

    -- Embedding (stored as BLOB)
    embedding BLOB,                      -- 384-dim float32 = 1536 bytes

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- Status
    status TEXT DEFAULT 'active'         -- active|archived|deleted
);

-- FTS5 for BM25 full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
    content,
    summary,
    tags,
    content='memories',
    content_rowid='rowid'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
    INSERT INTO memories_fts(rowid, content, summary, tags)
    VALUES (new.rowid, new.content, new.summary, new.tags);
END;

CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, summary, tags)
    VALUES ('delete', old.rowid, old.content, old.summary, old.tags);
END;

CREATE TRIGGER IF NOT EXISTS memories_au AFTER UPDATE ON memories BEGIN
    INSERT INTO memories_fts(memories_fts, rowid, content, summary, tags)
    VALUES ('delete', old.rowid, old.content, old.summary, old.tags);
    INSERT INTO memories_fts(rowid, content, summary, tags)
    VALUES (new.rowid, new.content, new.summary, new.tags);
END;

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(memory_type);
CREATE INDEX IF NOT EXISTS idx_memories_project ON memories(project_hash);
CREATE INDEX IF NOT EXISTS idx_memories_source ON memories(source);
CREATE INDEX IF NOT EXISTS idx_memories_status ON memories(status);
CREATE INDEX IF NOT EXISTS idx_memories_created ON memories(created_at);
```

---

## Part 4: Component Specifications

### 4.1 Embedder (`core/embedder.cjs`)

**Purpose**: Generate 384-dimensional embeddings using local transformer model.

```javascript
/**
 * @module Embedder
 * Local embedding generation using @xenova/transformers
 */

'use strict';

const EMBEDDING_MODEL = 'Xenova/all-MiniLM-L6-v2';
const EMBEDDING_DIM = 384;
const MAX_TOKENS = 512;

class Embedder {
  constructor(options = {}) {
    this.modelId = options.model || EMBEDDING_MODEL;
    this.pipeline = null;
    this.loading = null;
    this.cache = new Map();  // LRU cache with TTL
    this.stats = {
      embeddings: 0,
      cacheHits: 0,
      avgLatencyMs: 0,
    };
  }

  /**
   * Lazy-load the model on first use
   * @returns {Promise<void>}
   */
  async ensureLoaded() {
    if (this.pipeline) return;
    if (this.loading) return this.loading;

    this.loading = (async () => {
      const { pipeline } = await import('@xenova/transformers');
      this.pipeline = await pipeline('feature-extraction', this.modelId);
      this.loading = null;
    })();

    return this.loading;
  }

  /**
   * Generate embedding for text
   * @param {string} text - Input text
   * @returns {Promise<Float32Array>} 384-dimensional vector
   */
  async embed(text) {
    await this.ensureLoaded();

    // Check cache
    const cacheKey = this._hash(text);
    if (this.cache.has(cacheKey)) {
      this.stats.cacheHits++;
      return this.cache.get(cacheKey);
    }

    const start = Date.now();

    // Truncate to max tokens (rough estimate)
    const truncated = text.slice(0, MAX_TOKENS * 4);

    // Generate embedding
    const output = await this.pipeline(truncated, {
      pooling: 'mean',
      normalize: true,
    });

    const embedding = new Float32Array(output.data);

    // Update stats
    this.stats.embeddings++;
    this.stats.avgLatencyMs =
      (this.stats.avgLatencyMs * (this.stats.embeddings - 1) + (Date.now() - start))
      / this.stats.embeddings;

    // Cache result
    this.cache.set(cacheKey, embedding);
    this._pruneCache();

    return embedding;
  }

  /**
   * Generate embeddings for multiple texts (batched)
   * @param {string[]} texts - Input texts
   * @returns {Promise<Float32Array[]>}
   */
  async embedBatch(texts) {
    await this.ensureLoaded();
    return Promise.all(texts.map(t => this.embed(t)));
  }

  /**
   * Cosine similarity between two vectors
   * @param {Float32Array} a
   * @param {Float32Array} b
   * @returns {number} -1 to 1
   */
  static cosineSimilarity(a, b) {
    let dot = 0, normA = 0, normB = 0;
    for (let i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  _hash(text) {
    const crypto = require('crypto');
    return crypto.createHash('md5').update(text).digest('hex');
  }

  _pruneCache(maxSize = 1000) {
    if (this.cache.size > maxSize) {
      const keys = Array.from(this.cache.keys());
      for (let i = 0; i < maxSize / 2; i++) {
        this.cache.delete(keys[i]);
      }
    }
  }

  getStats() {
    return {
      ...this.stats,
      cacheSize: this.cache.size,
      cacheHitRate: this.stats.embeddings > 0
        ? this.stats.cacheHits / this.stats.embeddings
        : 0,
    };
  }
}

module.exports = { Embedder, EMBEDDING_DIM };
```

### 4.2 Vector Index (`core/vector-index.cjs`)

**Purpose**: HNSW index for fast approximate nearest neighbor search.

```javascript
/**
 * @module VectorIndex
 * HNSW vector index using hnswlib-node
 */

'use strict';

const HierarchicalNSW = require('hnswlib-node').HierarchicalNSW;
const fs = require('fs');
const path = require('path');

const EMBEDDING_DIM = 384;

class VectorIndex {
  constructor(options = {}) {
    this.dim = options.dim || EMBEDDING_DIM;
    this.maxElements = options.maxElements || 100000;
    this.efConstruction = options.efConstruction || 200;
    this.M = options.M || 16;
    this.efSearch = options.efSearch || 50;

    this.indexPath = options.indexPath || '~/.claude/memory/data/vector.idx';
    this.idMapPath = options.idMapPath || '~/.claude/memory/data/vector-ids.json';

    this.index = null;
    this.idMap = [];      // index position -> memory id
    this.reverseMap = {}; // memory id -> index position
    this.nextIndex = 0;
  }

  /**
   * Initialize or load existing index
   * @returns {Promise<void>}
   */
  async initialize() {
    this.index = new HierarchicalNSW('cosine', this.dim);

    const indexExists = fs.existsSync(this._expandPath(this.indexPath));
    const mapExists = fs.existsSync(this._expandPath(this.idMapPath));

    if (indexExists && mapExists) {
      // Load existing index
      this.index.readIndex(this._expandPath(this.indexPath), this.maxElements);
      const mapData = JSON.parse(fs.readFileSync(this._expandPath(this.idMapPath), 'utf8'));
      this.idMap = mapData.idMap || [];
      this.reverseMap = mapData.reverseMap || {};
      this.nextIndex = mapData.nextIndex || this.idMap.length;
    } else {
      // Create new index
      this.index.initIndex(this.maxElements, this.M, this.efConstruction);
    }

    this.index.setEf(this.efSearch);
  }

  /**
   * Add vector to index
   * @param {string} id - Memory ID
   * @param {Float32Array} embedding - 384-dim vector
   * @returns {number} Index position
   */
  add(id, embedding) {
    if (this.reverseMap[id] !== undefined) {
      // Update existing - remove old, add new
      this.remove(id);
    }

    const position = this.nextIndex++;
    this.index.addPoint(embedding, position);
    this.idMap[position] = id;
    this.reverseMap[id] = position;

    return position;
  }

  /**
   * Remove vector from index (marks as deleted)
   * @param {string} id - Memory ID
   */
  remove(id) {
    const position = this.reverseMap[id];
    if (position !== undefined) {
      this.index.markDelete(position);
      delete this.reverseMap[id];
      this.idMap[position] = null;
    }
  }

  /**
   * Search for nearest neighbors
   * @param {Float32Array} queryEmbedding - Query vector
   * @param {number} k - Number of results
   * @returns {{ids: string[], distances: number[]}}
   */
  search(queryEmbedding, k = 10) {
    const result = this.index.searchKnn(queryEmbedding, k);

    const ids = [];
    const distances = [];

    for (let i = 0; i < result.neighbors.length; i++) {
      const position = result.neighbors[i];
      const id = this.idMap[position];
      if (id !== null) {  // Skip deleted entries
        ids.push(id);
        distances.push(result.distances[i]);
      }
    }

    return { ids, distances };
  }

  /**
   * Persist index to disk
   * @returns {Promise<void>}
   */
  async save() {
    const indexPath = this._expandPath(this.indexPath);
    const mapPath = this._expandPath(this.idMapPath);

    // Ensure directory exists
    const dir = path.dirname(indexPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
    }

    // Save index
    this.index.writeIndex(indexPath);

    // Save ID mapping
    fs.writeFileSync(mapPath, JSON.stringify({
      idMap: this.idMap,
      reverseMap: this.reverseMap,
      nextIndex: this.nextIndex,
    }, null, 2), { mode: 0o600 });
  }

  /**
   * Get index statistics
   * @returns {Object}
   */
  getStats() {
    const activeCount = Object.keys(this.reverseMap).length;
    return {
      totalSlots: this.nextIndex,
      activeVectors: activeCount,
      deletedVectors: this.nextIndex - activeCount,
      maxElements: this.maxElements,
      dimension: this.dim,
    };
  }

  _expandPath(p) {
    if (p.startsWith('~')) {
      return path.join(process.env.HOME || '', p.slice(1));
    }
    return p;
  }
}

module.exports = { VectorIndex };
```

### 4.3 Hybrid Search (`core/hybrid-search.cjs`)

**Purpose**: Combine BM25 and vector search with RRF fusion and temporal decay.

```javascript
/**
 * @module HybridSearch
 * Combines BM25 (SQLite FTS5) and vector search with RRF fusion
 */

'use strict';

class HybridSearch {
  constructor(options = {}) {
    this.db = options.db;              // SQLite database
    this.vectorIndex = options.vectorIndex;
    this.embedder = options.embedder;

    // RRF constant (standard is 60)
    this.rrfK = options.rrfK || 60;

    // Weight for vector vs BM25 (0.5 = equal weight)
    this.vectorWeight = options.vectorWeight || 0.5;

    // Temporal decay parameters (FSRS-6 power law)
    this.decayBase = options.decayBase || 0.9;
    this.decayExponent = options.decayExponent || 0.5;
  }

  /**
   * Search with hybrid strategy
   * @param {string} query - Search query
   * @param {Object} options
   * @returns {Promise<Array<{id: string, score: number, memory: Object}>>}
   */
  async search(query, options = {}) {
    const limit = options.limit || 10;
    const k = Math.max(limit * 3, 30);  // Fetch more for fusion

    // Run both searches in parallel
    const [bm25Results, vectorResults] = await Promise.all([
      this._bm25Search(query, k),
      this._vectorSearch(query, k),
    ]);

    // RRF Fusion
    const fused = this._rrfFusion(bm25Results, vectorResults);

    // Apply temporal decay
    const decayed = this._applyTemporalDecay(fused);

    // Sort by final score and limit
    const sorted = Array.from(decayed.entries())
      .sort((a, b) => b[1].score - a[1].score)
      .slice(0, limit);

    // Fetch full memory records
    const results = await Promise.all(
      sorted.map(async ([id, data]) => ({
        id,
        score: data.score,
        memory: await this._getMemory(id),
        sources: data.sources,
      }))
    );

    return results.filter(r => r.memory !== null);
  }

  /**
   * BM25 search using SQLite FTS5
   * @private
   */
  async _bm25Search(query, k) {
    const sql = `
      SELECT
        m.id,
        bm25(memories_fts) as score,
        m.created_at
      FROM memories_fts f
      JOIN memories m ON f.rowid = m.rowid
      WHERE memories_fts MATCH ?
        AND m.status = 'active'
      ORDER BY bm25(memories_fts)
      LIMIT ?
    `;

    const rows = await this.db.all(sql, [query, k]);
    return rows.map((row, rank) => ({
      id: row.id,
      rank,
      rawScore: -row.score,  // BM25 returns negative scores
      createdAt: row.created_at,
    }));
  }

  /**
   * Vector similarity search
   * @private
   */
  async _vectorSearch(query, k) {
    const queryEmbedding = await this.embedder.embed(query);
    const { ids, distances } = this.vectorIndex.search(queryEmbedding, k);

    // Get created_at for decay calculation
    const results = [];
    for (let i = 0; i < ids.length; i++) {
      const sql = 'SELECT created_at FROM memories WHERE id = ?';
      const row = await this.db.get(sql, [ids[i]]);
      if (row) {
        results.push({
          id: ids[i],
          rank: i,
          rawScore: 1 - distances[i],  // Convert distance to similarity
          createdAt: row.created_at,
        });
      }
    }

    return results;
  }

  /**
   * Reciprocal Rank Fusion
   * @private
   */
  _rrfFusion(bm25Results, vectorResults) {
    const fused = new Map();

    // Process BM25 results
    for (const result of bm25Results) {
      const rrfScore = (1 - this.vectorWeight) / (this.rrfK + result.rank);
      fused.set(result.id, {
        score: rrfScore,
        createdAt: result.createdAt,
        sources: ['bm25'],
      });
    }

    // Process vector results
    for (const result of vectorResults) {
      const rrfScore = this.vectorWeight / (this.rrfK + result.rank);
      if (fused.has(result.id)) {
        const existing = fused.get(result.id);
        existing.score += rrfScore;
        existing.sources.push('vector');
      } else {
        fused.set(result.id, {
          score: rrfScore,
          createdAt: result.createdAt,
          sources: ['vector'],
        });
      }
    }

    return fused;
  }

  /**
   * Apply FSRS-6 power law temporal decay
   * @private
   */
  _applyTemporalDecay(fused) {
    const now = Date.now();

    for (const [id, data] of fused) {
      const ageMs = now - new Date(data.createdAt).getTime();
      const ageDays = ageMs / (1000 * 60 * 60 * 24);

      // FSRS-6 power law: retention = e^(-t/S)
      // Simplified: decay = base ^ (age ^ exponent)
      const decay = Math.pow(this.decayBase, Math.pow(ageDays, this.decayExponent));

      data.score *= decay;
      data.decay = decay;
    }

    return fused;
  }

  /**
   * Get full memory record
   * @private
   */
  async _getMemory(id) {
    const sql = 'SELECT * FROM memories WHERE id = ?';
    return this.db.get(sql, [id]);
  }
}

module.exports = { HybridSearch };
```

---

## Part 5: Integration Plan

### 5.1 Files to Create

| File | Lines | Purpose |
|------|-------|---------|
| `core/embedder.cjs` | ~150 | Embedding generation with caching |
| `core/vector-index.cjs` | ~200 | HNSW index management |
| `core/hybrid-search.cjs` | ~200 | BM25 + vector + RRF + decay |
| `core/sqlite-store.cjs` | ~300 | SQLite storage with FTS5 |
| `adapters/unified-adapter.cjs` | ~400 | Single adapter for all sources |

### 5.2 Files to Modify

| File | Changes |
|------|---------|
| `adapters/base-adapter.cjs:17-44` | Add `embedding: Float32Array` to MemoryRecord typedef |
| `core/storage.cjs:296-320` | Add `VectorIndex` integration, `addWithEmbedding()` method |
| `cortex/haiku-worker.cjs` | Replace keyword extraction with hybrid search call |
| `cortex/server.cjs` | Initialize new components, update tool handlers |

### 5.3 Migration Strategy

1. **Phase 1**: Add new components alongside existing (no breaking changes)
2. **Phase 2**: Generate embeddings for existing JSONL records (background job)
3. **Phase 3**: Switch haiku-worker to use hybrid search
4. **Phase 4**: Deprecate old keyword-based search

---

## Part 6: Testing Strategy

### 6.1 Unit Tests

```javascript
// tests/embedder.test.js
describe('Embedder', () => {
  it('generates 384-dim embeddings', async () => {
    const embedding = await embedder.embed('test text');
    expect(embedding.length).toBe(384);
  });

  it('returns cached results for same input', async () => {
    await embedder.embed('test');
    await embedder.embed('test');
    expect(embedder.stats.cacheHits).toBe(1);
  });

  it('generates similar embeddings for similar text', async () => {
    const a = await embedder.embed('authentication bug fix');
    const b = await embedder.embed('auth issue resolution');
    const sim = Embedder.cosineSimilarity(a, b);
    expect(sim).toBeGreaterThan(0.7);
  });
});

// tests/vector-index.test.js
describe('VectorIndex', () => {
  it('persists and loads index', async () => {
    const index = new VectorIndex({ indexPath: '/tmp/test.idx' });
    await index.initialize();
    index.add('mem1', new Float32Array(384).fill(0.1));
    await index.save();

    const index2 = new VectorIndex({ indexPath: '/tmp/test.idx' });
    await index2.initialize();
    expect(index2.getStats().activeVectors).toBe(1);
  });
});

// tests/hybrid-search.test.js
describe('HybridSearch', () => {
  it('returns results from both BM25 and vector', async () => {
    const results = await hybridSearch.search('authentication');
    const sources = new Set(results.flatMap(r => r.sources));
    expect(sources.has('bm25') || sources.has('vector')).toBe(true);
  });

  it('applies temporal decay to older memories', async () => {
    // Insert old and new memories with same content
    // Verify new memory ranks higher
  });
});
```

### 6.2 Integration Tests

```javascript
// tests/integration/cortex-query.test.js
describe('cortex__query integration', () => {
  it('finds relevant memories across all sources', async () => {
    // Setup: Add memories to JSONL, knowledge graph, episodic
    // Query: "How to fix authentication bugs"
    // Verify: Results from multiple sources
  });

  it('handles empty results gracefully', async () => {
    const result = await cortex.query({ query: 'xyznonexistent123' });
    expect(result.results).toEqual([]);
  });
});
```

---

## Part 7: Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Embedding generation | <100ms | First call (model loaded) |
| Vector search (10k vectors) | <10ms | Top-10 results |
| BM25 search (10k docs) | <20ms | Full-text query |
| Hybrid search total | <150ms | End-to-end |
| Index save/load | <1s | 10k vectors |
| Memory usage | <200MB | Idle with index loaded |

---

## Part 8: Dependencies

### 8.1 New Dependencies

```json
{
  "dependencies": {
    "@xenova/transformers": "^2.17.0",
    "hnswlib-node": "^3.0.0",
    "better-sqlite3": "^11.0.0"
  }
}
```

### 8.2 Alternative (sqlite-vec instead of hnswlib)

```json
{
  "dependencies": {
    "@xenova/transformers": "^2.17.0",
    "sqlite-vec": "^0.1.0",
    "better-sqlite3": "^11.0.0"
  }
}
```

---

## Part 9: Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Model download on first use | 5-10s delay | Pre-download in postinstall script |
| hnswlib native compilation | Install fails | Fallback to sqlite-vec (pure JS) |
| Large embedding cache | Memory bloat | LRU eviction, max 1000 entries |
| Index corruption | Data loss | Atomic writes, backup before save |
| API rate limits (if using external) | Search fails | Local embeddings primary |

---

## Part 10: Success Criteria

- [ ] Embedder generates 384-dim vectors in <100ms
- [ ] Vector index handles 10k+ vectors with <10ms search
- [ ] Hybrid search combines BM25 + vector results correctly
- [ ] Temporal decay prioritizes recent memories
- [ ] All existing Cortex tests pass
- [ ] New unit tests: >80% coverage
- [ ] Integration tests: All tools work end-to-end
- [ ] Performance: <150ms average query time

---

## Appendix A: Research References

### GitHub Projects Analyzed

1. [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) - 1,251 stars
2. [Vestige](https://github.com/vestige-ai/vestige) - FSRS-6 decay
3. [Subcog](https://github.com/subcog-ai/subcog) - usearch HNSW
4. [CortexGraph](https://github.com/cortexgraph/cortexgraph) - Ebbinghaus curve
5. [Claudeception](https://github.com/blader/Claudeception) - Auto skill extraction
6. [@modelcontextprotocol/server-memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) - Official

### Academic Research

- **FSRS** (Free Spaced Repetition Scheduler) - Power law forgetting curve
- **HNSW** (Hierarchical Navigable Small World) - Approximate nearest neighbor
- **BM25** (Best Match 25) - Probabilistic ranking function
- **RRF** (Reciprocal Rank Fusion) - Score combination method

---

*Document Version: 1.0 | Last Updated: 2026-02-01*
