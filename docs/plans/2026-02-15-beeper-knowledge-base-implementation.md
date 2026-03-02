# Beeper Knowledge Base Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a semantic knowledge base MCP server that harvests, indexes, and searches all Beeper Developer Community technical information.

**Architecture:** Node.js TypeScript MCP server using SQLite (documents + FTS5) + FAISS (vector index) + Voyage API (embeddings). Harvests data from Beeper Matrix chat, developer docs, GitHub repos, and blog. Exposes 5 tools for search, ingestion, harvesting, stats, and browsing.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk, better-sqlite3, faiss-node, Voyage AI API, vitest, zod

**Design Doc:** `docs/plans/2026-02-15-beeper-knowledge-base-design.md`

---

## Task 1: Project Scaffolding

**Files:**
- Create: `~/repos/beeper-kb/package.json`
- Create: `~/repos/beeper-kb/tsconfig.json`
- Create: `~/repos/beeper-kb/vitest.config.ts`
- Create: `~/repos/beeper-kb/.gitignore`

**Step 1: Create project directory and initialize**

```bash
mkdir -p ~/repos/beeper-kb
cd ~/repos/beeper-kb
git init
```

**Step 2: Create package.json**

```json
{
  "name": "beeper-kb",
  "version": "1.0.0",
  "description": "Beeper Developer Community knowledge base — semantic search MCP server",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "clean": "rm -rf dist",
    "test": "vitest run",
    "test:watch": "vitest",
    "start": "node dist/index.js",
    "harvest": "node dist/cli-harvest.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "better-sqlite3": "^12.6.0",
    "faiss-node": "^0.5.1",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/better-sqlite3": "^7.6.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.7.0",
    "vitest": "^3.0.0"
  }
}
```

**Step 3: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

Note: Using `NodeNext` module resolution (not `Node`) because better-sqlite3 and faiss-node
are CJS packages imported from ESM — NodeNext handles this correctly with `.js` extensions.

**Step 4: Create vitest.config.ts**

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts"],
    testTimeout: 30_000,
  },
});
```

**Step 5: Create .gitignore**

```
node_modules/
dist/
*.sqlite
*.faiss
id_map.json
.env
```

**Step 6: Install dependencies**

```bash
cd ~/repos/beeper-kb
npm install
```

Expected: Clean install, no errors. Native modules (better-sqlite3, faiss-node) compile via prebuild-install.

**Step 7: Verify TypeScript compiles**

```bash
cd ~/repos/beeper-kb
mkdir -p src
echo 'console.log("ok");' > src/index.ts
npx tsc
node dist/index.js
```

Expected: Prints `ok`

**Step 8: Commit**

```bash
cd ~/repos/beeper-kb
git add -A
git commit -m "chore: scaffold beeper-kb project"
```

---

## Task 2: Types and Constants

**Files:**
- Create: `~/repos/beeper-kb/src/types.ts`
- Create: `~/repos/beeper-kb/src/config.ts`

**Step 1: Write types.ts**

Define the core data types matching the SQLite schema:

```typescript
// src/types.ts

export type Source = "matrix-chat" | "docs" | "github" | "blog" | "seed";

export interface Document {
  id: string;
  source: Source;
  sourceId: string | null;
  room: string | null;
  author: string | null;
  title: string | null;
  content: string;
  chunkIndex: number;
  parentId: string | null;
  createdAt: string;   // ISO 8601
  ingestedAt: string;  // ISO 8601
  metadata: Record<string, unknown>;
}

export interface DocumentChunk {
  content: string;
  chunkIndex: number;
  tokenEstimate: number;
}

export interface SearchResult {
  document: Document;
  score: number;
  matchType: "semantic" | "fts" | "hybrid";
}

export interface HarvestState {
  source: Source;
  lastCursor: string | null;
  lastRun: string | null;
  docCount: number;
}

export interface HarvestResult {
  source: Source;
  newDocs: number;
  updatedDocs: number;
  errors: string[];
}
```

**Step 2: Write config.ts**

```typescript
// src/config.ts
import { join } from "path";
import { homedir } from "os";

export const DATA_DIR = process.env.BEEPER_KB_DATA_DIR
  ? process.env.BEEPER_KB_DATA_DIR.replace(/^~/, homedir())
  : join(homedir(), ".beeper-kb");

export const DB_PATH = join(DATA_DIR, "beeper-kb.sqlite");
export const FAISS_PATH = join(DATA_DIR, "vectors.faiss");
export const ID_MAP_PATH = join(DATA_DIR, "id_map.json");

export const VOYAGE_API_KEY = process.env.VOYAGE_API_KEY || "";
export const VOYAGE_MODEL = process.env.VOYAGE_MODEL || "voyage-3";
export const VOYAGE_DIMENSIONS = 1024;

export const BEEPER_BASE_URL = process.env.BEEPER_BASE_URL || "http://localhost:23373";
export const BEEPER_TOKEN = process.env.BEEPER_TOKEN || null;

export const CHUNK_TARGET_TOKENS = 500;
export const CHUNK_OVERLAP_TOKENS = 50;
```

**Step 3: Commit**

```bash
cd ~/repos/beeper-kb
git add src/types.ts src/config.ts
git commit -m "feat: add core types and configuration"
```

---

## Task 3: Database Layer (SQLite + FAISS)

**Files:**
- Create: `~/repos/beeper-kb/src/db.ts`
- Create: `~/repos/beeper-kb/tests/db.test.ts`

**Step 1: Write the failing test for database initialization**

```typescript
// tests/db.test.ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { KnowledgeBase } from "../src/db.js";

describe("KnowledgeBase", () => {
  let tmpDir: string;
  let kb: KnowledgeBase;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "beeper-kb-test-"));
    kb = new KnowledgeBase(tmpDir);
  });

  afterEach(() => {
    kb.close();
    rmSync(tmpDir, { recursive: true, force: true });
  });

  it("initializes SQLite database with schema", () => {
    const tables = kb.listTables();
    expect(tables).toContain("documents");
    expect(tables).toContain("tags");
    expect(tables).toContain("harvest_state");
  });

  it("inserts and retrieves a document", () => {
    const doc = {
      id: "test-001",
      source: "seed" as const,
      sourceId: null,
      room: null,
      author: "rob",
      title: "Test Document",
      content: "This is a test document about Beeper bridges.",
      chunkIndex: 0,
      parentId: null,
      createdAt: new Date().toISOString(),
      ingestedAt: new Date().toISOString(),
      metadata: { test: true },
    };
    kb.insertDocument(doc);
    const retrieved = kb.getDocument("test-001");
    expect(retrieved).not.toBeNull();
    expect(retrieved!.content).toBe(doc.content);
    expect(retrieved!.author).toBe("rob");
  });

  it("performs FTS5 search", () => {
    kb.insertDocument({
      id: "fts-001",
      source: "seed",
      sourceId: null,
      room: null,
      author: "batuhan",
      title: "Webhooks Discussion",
      content: "Webhooks are the number one requested feature for the Beeper API.",
      chunkIndex: 0,
      parentId: null,
      createdAt: new Date().toISOString(),
      ingestedAt: new Date().toISOString(),
      metadata: {},
    });
    const results = kb.ftsSearch("webhooks", 10);
    expect(results.length).toBe(1);
    expect(results[0].id).toBe("fts-001");
  });

  it("tracks harvest state", () => {
    kb.updateHarvestState("matrix-chat", "cursor-123", 42);
    const state = kb.getHarvestState("matrix-chat");
    expect(state).not.toBeNull();
    expect(state!.lastCursor).toBe("cursor-123");
    expect(state!.docCount).toBe(42);
  });

  it("manages tags", () => {
    kb.insertDocument({
      id: "tag-001",
      source: "seed",
      sourceId: null,
      room: null,
      author: null,
      title: "Tagged",
      content: "content",
      chunkIndex: 0,
      parentId: null,
      createdAt: new Date().toISOString(),
      ingestedAt: new Date().toISOString(),
      metadata: {},
    });
    kb.addTags("tag-001", ["api", "webhooks", "bridges"]);
    const tags = kb.getTags("tag-001");
    expect(tags).toEqual(["api", "bridges", "webhooks"]);
  });

  it("returns stats", () => {
    kb.insertDocument({
      id: "s1", source: "seed", sourceId: null, room: null, author: null,
      title: null, content: "c1", chunkIndex: 0, parentId: null,
      createdAt: new Date().toISOString(), ingestedAt: new Date().toISOString(),
      metadata: {},
    });
    kb.insertDocument({
      id: "s2", source: "matrix-chat", sourceId: null, room: "sdk", author: null,
      title: null, content: "c2", chunkIndex: 0, parentId: null,
      createdAt: new Date().toISOString(), ingestedAt: new Date().toISOString(),
      metadata: {},
    });
    const stats = kb.getStats();
    expect(stats.totalDocs).toBe(2);
    expect(stats.bySource.seed).toBe(1);
    expect(stats.bySource["matrix-chat"]).toBe(1);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/db.test.ts
```

Expected: FAIL — `KnowledgeBase` not found.

**Step 3: Write db.ts implementation**

```typescript
// src/db.ts
import Database from "better-sqlite3";
import { mkdirSync, existsSync } from "fs";
import { join } from "path";
import type { Document, HarvestState, Source } from "./types.js";

const SCHEMA = `
CREATE TABLE IF NOT EXISTS documents (
  id          TEXT PRIMARY KEY,
  source      TEXT NOT NULL,
  source_id   TEXT,
  room        TEXT,
  author      TEXT,
  title       TEXT,
  content     TEXT NOT NULL,
  chunk_index INTEGER DEFAULT 0,
  parent_id   TEXT,
  created_at  TEXT NOT NULL,
  ingested_at TEXT NOT NULL,
  metadata    TEXT
);

CREATE TABLE IF NOT EXISTS tags (
  doc_id  TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  tag     TEXT NOT NULL,
  PRIMARY KEY (doc_id, tag)
);

CREATE TABLE IF NOT EXISTS harvest_state (
  source      TEXT PRIMARY KEY,
  last_cursor TEXT,
  last_run    TEXT,
  doc_count   INTEGER DEFAULT 0
);

CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
  content, title, author, source,
  content=documents, content_rowid=rowid
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS documents_ai AFTER INSERT ON documents BEGIN
  INSERT INTO documents_fts(rowid, content, title, author, source)
  VALUES (new.rowid, new.content, new.title, new.author, new.source);
END;

CREATE TRIGGER IF NOT EXISTS documents_ad AFTER DELETE ON documents BEGIN
  INSERT INTO documents_fts(documents_fts, rowid, content, title, author, source)
  VALUES ('delete', old.rowid, old.content, old.title, old.author, old.source);
END;

CREATE INDEX IF NOT EXISTS idx_documents_source ON documents(source);
CREATE INDEX IF NOT EXISTS idx_documents_room ON documents(room);
CREATE INDEX IF NOT EXISTS idx_documents_author ON documents(author);
CREATE INDEX IF NOT EXISTS idx_documents_created ON documents(created_at);
CREATE INDEX IF NOT EXISTS idx_documents_parent ON documents(parent_id);
`;

export class KnowledgeBase {
  private db: Database.Database;

  constructor(dataDir: string) {
    if (!existsSync(dataDir)) mkdirSync(dataDir, { recursive: true });
    const dbPath = join(dataDir, "beeper-kb.sqlite");
    this.db = new Database(dbPath);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");
    this.db.exec(SCHEMA);
  }

  close() {
    this.db.close();
  }

  listTables(): string[] {
    const rows = this.db.prepare(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'documents_fts%'"
    ).all() as { name: string }[];
    return rows.map((r) => r.name);
  }

  insertDocument(doc: Document): void {
    this.db.prepare(`
      INSERT OR REPLACE INTO documents (id, source, source_id, room, author, title, content, chunk_index, parent_id, created_at, ingested_at, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      doc.id, doc.source, doc.sourceId, doc.room, doc.author, doc.title,
      doc.content, doc.chunkIndex, doc.parentId, doc.createdAt, doc.ingestedAt,
      JSON.stringify(doc.metadata),
    );
  }

  insertDocuments(docs: Document[]): void {
    const insert = this.db.prepare(`
      INSERT OR REPLACE INTO documents (id, source, source_id, room, author, title, content, chunk_index, parent_id, created_at, ingested_at, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const tx = this.db.transaction((items: Document[]) => {
      for (const doc of items) {
        insert.run(
          doc.id, doc.source, doc.sourceId, doc.room, doc.author, doc.title,
          doc.content, doc.chunkIndex, doc.parentId, doc.createdAt, doc.ingestedAt,
          JSON.stringify(doc.metadata),
        );
      }
    });
    tx(docs);
  }

  getDocument(id: string): Document | null {
    const row = this.db.prepare("SELECT * FROM documents WHERE id = ?").get(id) as Record<string, unknown> | undefined;
    if (!row) return null;
    return this.rowToDocument(row);
  }

  ftsSearch(query: string, limit: number): Document[] {
    const rows = this.db.prepare(`
      SELECT d.* FROM documents d
      JOIN documents_fts fts ON d.rowid = fts.rowid
      WHERE documents_fts MATCH ?
      ORDER BY rank
      LIMIT ?
    `).all(query, limit) as Record<string, unknown>[];
    return rows.map((r) => this.rowToDocument(r));
  }

  browseDocuments(opts: {
    source?: Source;
    room?: string;
    author?: string;
    tag?: string;
    limit?: number;
    offset?: number;
  }): Document[] {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (opts.source) { conditions.push("d.source = ?"); params.push(opts.source); }
    if (opts.room) { conditions.push("d.room = ?"); params.push(opts.room); }
    if (opts.author) { conditions.push("d.author = ?"); params.push(opts.author); }
    if (opts.tag) {
      conditions.push("d.id IN (SELECT doc_id FROM tags WHERE tag = ?)");
      params.push(opts.tag);
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
    const limit = opts.limit || 20;
    const offset = opts.offset || 0;
    params.push(limit, offset);

    const rows = this.db.prepare(
      `SELECT d.* FROM documents d ${where} ORDER BY d.created_at DESC LIMIT ? OFFSET ?`
    ).all(...params) as Record<string, unknown>[];

    return rows.map((r) => this.rowToDocument(r));
  }

  addTags(docId: string, tags: string[]): void {
    const insert = this.db.prepare("INSERT OR IGNORE INTO tags (doc_id, tag) VALUES (?, ?)");
    const tx = this.db.transaction((items: string[]) => {
      for (const tag of items) insert.run(docId, tag);
    });
    tx(tags);
  }

  getTags(docId: string): string[] {
    const rows = this.db.prepare("SELECT tag FROM tags WHERE doc_id = ? ORDER BY tag").all(docId) as { tag: string }[];
    return rows.map((r) => r.tag);
  }

  updateHarvestState(source: string, cursor: string | null, docCount: number): void {
    this.db.prepare(`
      INSERT OR REPLACE INTO harvest_state (source, last_cursor, last_run, doc_count)
      VALUES (?, ?, ?, ?)
    `).run(source, cursor, new Date().toISOString(), docCount);
  }

  getHarvestState(source: string): HarvestState | null {
    const row = this.db.prepare("SELECT * FROM harvest_state WHERE source = ?").get(source) as Record<string, unknown> | undefined;
    if (!row) return null;
    return {
      source: row.source as Source,
      lastCursor: row.last_cursor as string | null,
      lastRun: row.last_run as string | null,
      docCount: row.doc_count as number,
    };
  }

  getStats(): { totalDocs: number; bySource: Record<string, number>; byRoom: Record<string, number> } {
    const total = (this.db.prepare("SELECT COUNT(*) as c FROM documents").get() as { c: number }).c;
    const sourceRows = this.db.prepare("SELECT source, COUNT(*) as c FROM documents GROUP BY source").all() as { source: string; c: number }[];
    const roomRows = this.db.prepare("SELECT room, COUNT(*) as c FROM documents WHERE room IS NOT NULL GROUP BY room").all() as { room: string; c: number }[];

    const bySource: Record<string, number> = {};
    for (const r of sourceRows) bySource[r.source] = r.c;
    const byRoom: Record<string, number> = {};
    for (const r of roomRows) byRoom[r.room] = r.c;

    return { totalDocs: total, bySource, byRoom };
  }

  getDocumentIds(): string[] {
    return (this.db.prepare("SELECT id FROM documents ORDER BY rowid").all() as { id: string }[]).map((r) => r.id);
  }

  private rowToDocument(row: Record<string, unknown>): Document {
    return {
      id: row.id as string,
      source: row.source as Source,
      sourceId: row.source_id as string | null,
      room: row.room as string | null,
      author: row.author as string | null,
      title: row.title as string | null,
      content: row.content as string,
      chunkIndex: row.chunk_index as number,
      parentId: row.parent_id as string | null,
      createdAt: row.created_at as string,
      ingestedAt: row.ingested_at as string,
      metadata: row.metadata ? JSON.parse(row.metadata as string) : {},
    };
  }
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/db.test.ts
```

Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/db.ts tests/db.test.ts
git commit -m "feat: add SQLite database layer with FTS5 search"
```

---

## Task 4: Text Chunker

**Files:**
- Create: `~/repos/beeper-kb/src/chunker.ts`
- Create: `~/repos/beeper-kb/tests/chunker.test.ts`

**Step 1: Write the failing test**

```typescript
// tests/chunker.test.ts
import { describe, it, expect } from "vitest";
import { chunkText, chunkMarkdown, estimateTokens } from "../src/chunker.js";

describe("estimateTokens", () => {
  it("estimates tokens from word count", () => {
    const text = "The quick brown fox jumps over the lazy dog";
    const tokens = estimateTokens(text);
    // ~9 words ≈ 12 tokens (1.3x multiplier)
    expect(tokens).toBeGreaterThan(8);
    expect(tokens).toBeLessThan(20);
  });
});

describe("chunkText", () => {
  it("returns single chunk for short text", () => {
    const chunks = chunkText("Hello world", 500, 50);
    expect(chunks).toHaveLength(1);
    expect(chunks[0].content).toBe("Hello world");
    expect(chunks[0].chunkIndex).toBe(0);
  });

  it("splits long text into overlapping chunks", () => {
    // Generate text ~1500 tokens (approx 1150 words)
    const words = Array.from({ length: 1150 }, (_, i) => `word${i}`);
    const text = words.join(" ");
    const chunks = chunkText(text, 500, 50);
    expect(chunks.length).toBeGreaterThan(2);

    // Verify overlap: last words of chunk N appear in chunk N+1
    for (let i = 0; i < chunks.length - 1; i++) {
      const endWords = chunks[i].content.split(" ").slice(-10);
      const nextContent = chunks[i + 1].content;
      const hasOverlap = endWords.some((w) => nextContent.startsWith(w) || nextContent.includes(w));
      expect(hasOverlap).toBe(true);
    }
  });

  it("preserves code blocks intact", () => {
    const text = "Before code.\n\n```javascript\nfunction hello() {\n  return 'world';\n}\n```\n\nAfter code.";
    const chunks = chunkText(text, 500, 50);
    // Code block should not be split across chunks
    const codeChunk = chunks.find((c) => c.content.includes("function hello"));
    expect(codeChunk).toBeDefined();
    expect(codeChunk!.content).toContain("return 'world'");
  });
});

describe("chunkMarkdown", () => {
  it("splits by headers", () => {
    const md = "# Title\n\nIntro paragraph.\n\n## Section 1\n\nContent one.\n\n## Section 2\n\nContent two.";
    const chunks = chunkMarkdown(md, 500, 50);
    expect(chunks.length).toBeGreaterThanOrEqual(2);
  });

  it("assigns sequential chunk indices", () => {
    const md = "## A\n\nText A.\n\n## B\n\nText B.\n\n## C\n\nText C.";
    const chunks = chunkMarkdown(md, 500, 50);
    for (let i = 0; i < chunks.length; i++) {
      expect(chunks[i].chunkIndex).toBe(i);
    }
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/chunker.test.ts
```

Expected: FAIL — module not found.

**Step 3: Write chunker.ts implementation**

```typescript
// src/chunker.ts
import type { DocumentChunk } from "./types.js";

/**
 * Rough token estimate: ~1.3 tokens per word for English text.
 * Good enough for chunking decisions; actual token count comes from the embedding model.
 */
export function estimateTokens(text: string): number {
  return Math.ceil(text.split(/\s+/).filter(Boolean).length * 1.3);
}

/**
 * Split plain text into overlapping chunks.
 * Respects code block boundaries (never splits mid-code-block).
 */
export function chunkText(
  text: string,
  targetTokens: number,
  overlapTokens: number,
): DocumentChunk[] {
  const est = estimateTokens(text);
  if (est <= targetTokens) {
    return [{ content: text, chunkIndex: 0, tokenEstimate: est }];
  }

  // Split into segments: paragraphs and code blocks
  const segments = splitIntoSegments(text);
  return assembleChunks(segments, targetTokens, overlapTokens);
}

/**
 * Split markdown by headers first, then by paragraph if sections are too large.
 */
export function chunkMarkdown(
  markdown: string,
  targetTokens: number,
  overlapTokens: number,
): DocumentChunk[] {
  const est = estimateTokens(markdown);
  if (est <= targetTokens) {
    return [{ content: markdown, chunkIndex: 0, tokenEstimate: est }];
  }

  // Split by ## headers
  const sections = markdown.split(/(?=^#{1,3}\s)/m).filter(Boolean);
  const segments: string[] = [];

  for (const section of sections) {
    const sectionTokens = estimateTokens(section);
    if (sectionTokens <= targetTokens) {
      segments.push(section.trim());
    } else {
      // Section too big — split into paragraphs
      segments.push(...splitIntoSegments(section));
    }
  }

  return assembleChunks(segments, targetTokens, overlapTokens);
}

function splitIntoSegments(text: string): string[] {
  const segments: string[] = [];
  // Match code blocks as atomic units, everything else splits on double newline
  const codeBlockRegex = /```[\s\S]*?```/g;
  let lastIndex = 0;

  for (const match of text.matchAll(codeBlockRegex)) {
    const before = text.slice(lastIndex, match.index);
    if (before.trim()) {
      segments.push(...before.split(/\n\n+/).filter((s) => s.trim()));
    }
    segments.push(match[0]); // Code block as atomic segment
    lastIndex = match.index! + match[0].length;
  }

  const remaining = text.slice(lastIndex);
  if (remaining.trim()) {
    segments.push(...remaining.split(/\n\n+/).filter((s) => s.trim()));
  }

  return segments;
}

function assembleChunks(
  segments: string[],
  targetTokens: number,
  overlapTokens: number,
): DocumentChunk[] {
  const chunks: DocumentChunk[] = [];
  let current: string[] = [];
  let currentTokens = 0;

  for (const segment of segments) {
    const segTokens = estimateTokens(segment);

    if (currentTokens + segTokens > targetTokens && current.length > 0) {
      // Emit current chunk
      const content = current.join("\n\n");
      chunks.push({
        content,
        chunkIndex: chunks.length,
        tokenEstimate: estimateTokens(content),
      });

      // Overlap: keep last segments worth ~overlapTokens
      const overlapSegments: string[] = [];
      let overlapCount = 0;
      for (let i = current.length - 1; i >= 0 && overlapCount < overlapTokens; i--) {
        overlapSegments.unshift(current[i]);
        overlapCount += estimateTokens(current[i]);
      }
      current = overlapSegments;
      currentTokens = overlapCount;
    }

    current.push(segment);
    currentTokens += segTokens;
  }

  // Emit final chunk
  if (current.length > 0) {
    const content = current.join("\n\n");
    chunks.push({
      content,
      chunkIndex: chunks.length,
      tokenEstimate: estimateTokens(content),
    });
  }

  return chunks;
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/chunker.test.ts
```

Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/chunker.ts tests/chunker.test.ts
git commit -m "feat: add text chunker with markdown support and code block preservation"
```

---

## Task 5: Voyage Embedding Client

**Files:**
- Create: `~/repos/beeper-kb/src/embeddings.ts`
- Create: `~/repos/beeper-kb/tests/embeddings.test.ts`

**Step 1: Write the failing test**

```typescript
// tests/embeddings.test.ts
import { describe, it, expect, vi } from "vitest";
import { VoyageClient, cosineSimilarity } from "../src/embeddings.js";

describe("cosineSimilarity", () => {
  it("returns 1.0 for identical vectors", () => {
    const v = [1, 0, 0, 1];
    expect(cosineSimilarity(v, v)).toBeCloseTo(1.0, 5);
  });

  it("returns 0.0 for orthogonal vectors", () => {
    expect(cosineSimilarity([1, 0], [0, 1])).toBeCloseTo(0.0, 5);
  });

  it("returns -1.0 for opposite vectors", () => {
    expect(cosineSimilarity([1, 0], [-1, 0])).toBeCloseTo(-1.0, 5);
  });
});

describe("VoyageClient", () => {
  it("throws if no API key provided", () => {
    expect(() => new VoyageClient("")).toThrow("VOYAGE_API_KEY");
  });

  it("batches large input arrays", async () => {
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        data: [{ embedding: new Array(1024).fill(0.1) }],
        usage: { total_tokens: 10 },
      }),
    });

    const client = new VoyageClient("test-key", fetchSpy as unknown as typeof fetch);
    const texts = Array.from({ length: 150 }, (_, i) => `text ${i}`);
    const result = await client.embed(texts);

    // Should batch into ceil(150/128) = 2 API calls
    expect(fetchSpy).toHaveBeenCalledTimes(2);
    expect(result.embeddings).toHaveLength(150);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/embeddings.test.ts
```

Expected: FAIL.

**Step 3: Write embeddings.ts**

```typescript
// src/embeddings.ts
import { VOYAGE_MODEL, VOYAGE_DIMENSIONS } from "./config.js";

const VOYAGE_API_URL = "https://api.voyageai.com/v1/embeddings";
const MAX_BATCH_SIZE = 128; // Voyage API limit

export function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  const denom = Math.sqrt(normA) * Math.sqrt(normB);
  return denom === 0 ? 0 : dot / denom;
}

export interface EmbedResult {
  embeddings: number[][];
  totalTokens: number;
}

export class VoyageClient {
  private apiKey: string;
  private fetchFn: typeof fetch;

  constructor(apiKey: string, fetchFn?: typeof fetch) {
    if (!apiKey) throw new Error("VOYAGE_API_KEY is required for embedding generation");
    this.apiKey = apiKey;
    this.fetchFn = fetchFn || globalThis.fetch;
  }

  async embed(texts: string[], model?: string): Promise<EmbedResult> {
    const embeddings: number[][] = [];
    let totalTokens = 0;

    // Batch in groups of MAX_BATCH_SIZE
    for (let i = 0; i < texts.length; i += MAX_BATCH_SIZE) {
      const batch = texts.slice(i, i + MAX_BATCH_SIZE);
      const result = await this.callApi(batch, model || VOYAGE_MODEL);
      embeddings.push(...result.embeddings);
      totalTokens += result.tokens;
    }

    return { embeddings, totalTokens };
  }

  async embedSingle(text: string, model?: string): Promise<number[]> {
    const result = await this.embed([text], model);
    return result.embeddings[0];
  }

  private async callApi(texts: string[], model: string): Promise<{ embeddings: number[][]; tokens: number }> {
    const response = await this.fetchFn(VOYAGE_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        input: texts,
        model,
        output_dimension: VOYAGE_DIMENSIONS,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Voyage API error (${response.status}): ${body}`);
    }

    const data = (await response.json()) as {
      data: { embedding: number[] }[];
      usage: { total_tokens: number };
    };

    return {
      embeddings: data.data.map((d) => d.embedding),
      tokens: data.usage.total_tokens,
    };
  }
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/embeddings.test.ts
```

Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/embeddings.ts tests/embeddings.test.ts
git commit -m "feat: add Voyage AI embedding client with batching"
```

---

## Task 6: FAISS Vector Index Wrapper

**Files:**
- Create: `~/repos/beeper-kb/src/vector-store.ts`
- Create: `~/repos/beeper-kb/tests/vector-store.test.ts`

**Step 1: Write the failing test**

```typescript
// tests/vector-store.test.ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { VectorStore } from "../src/vector-store.js";

describe("VectorStore", () => {
  let tmpDir: string;
  let store: VectorStore;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "beeper-kb-vec-"));
    store = new VectorStore(tmpDir, 4); // 4-dimension for tests
  });

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true });
  });

  it("adds vectors and searches them", () => {
    store.add("doc-1", [1, 0, 0, 0]);
    store.add("doc-2", [0, 1, 0, 0]);
    store.add("doc-3", [0.9, 0.1, 0, 0]);

    const results = store.search([1, 0, 0, 0], 2);
    expect(results).toHaveLength(2);
    expect(results[0].id).toBe("doc-1");
    expect(results[0].score).toBeGreaterThan(results[1].score);
  });

  it("persists and loads from disk", () => {
    store.add("doc-a", [1, 0, 0, 0]);
    store.add("doc-b", [0, 1, 0, 0]);
    store.save();

    // Create new store from same directory
    const store2 = new VectorStore(tmpDir, 4);
    const results = store2.search([1, 0, 0, 0], 1);
    expect(results).toHaveLength(1);
    expect(results[0].id).toBe("doc-a");
  });

  it("returns empty results when store is empty", () => {
    const results = store.search([1, 0, 0, 0], 5);
    expect(results).toHaveLength(0);
  });

  it("returns count", () => {
    store.add("doc-1", [1, 0, 0, 0]);
    store.add("doc-2", [0, 1, 0, 0]);
    expect(store.count()).toBe(2);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/vector-store.test.ts
```

**Step 3: Write vector-store.ts**

```typescript
// src/vector-store.ts
import { IndexFlatIP } from "faiss-node";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

interface SearchHit {
  id: string;
  score: number;
}

export class VectorStore {
  private index: IndexFlatIP;
  private idMap: string[];
  private faissPath: string;
  private idMapPath: string;

  constructor(dataDir: string, dimensions: number) {
    this.faissPath = join(dataDir, "vectors.faiss");
    this.idMapPath = join(dataDir, "id_map.json");

    if (existsSync(this.faissPath) && existsSync(this.idMapPath)) {
      this.index = IndexFlatIP.read(this.faissPath);
      this.idMap = JSON.parse(readFileSync(this.idMapPath, "utf-8"));
    } else {
      this.index = new IndexFlatIP(dimensions);
      this.idMap = [];
    }
  }

  add(id: string, vector: number[]): void {
    this.index.add(vector);
    this.idMap.push(id);
  }

  addBatch(ids: string[], vectors: number[][]): void {
    for (let i = 0; i < ids.length; i++) {
      this.index.add(vectors[i]);
      this.idMap.push(ids[i]);
    }
  }

  search(queryVector: number[], k: number): SearchHit[] {
    if (this.idMap.length === 0) return [];
    const actualK = Math.min(k, this.idMap.length);
    const result = this.index.search(queryVector, actualK);
    const hits: SearchHit[] = [];
    for (let i = 0; i < result.labels.length; i++) {
      const idx = result.labels[i];
      if (idx >= 0 && idx < this.idMap.length) {
        hits.push({ id: this.idMap[idx], score: result.distances[i] });
      }
    }
    return hits;
  }

  save(): void {
    this.index.write(this.faissPath);
    writeFileSync(this.idMapPath, JSON.stringify(this.idMap));
  }

  count(): number {
    return this.idMap.length;
  }
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/vector-store.test.ts
```

Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/vector-store.ts tests/vector-store.test.ts
git commit -m "feat: add FAISS vector store wrapper with persistence"
```

---

## Task 7: Hybrid Search Engine

**Files:**
- Create: `~/repos/beeper-kb/src/search.ts`
- Create: `~/repos/beeper-kb/tests/search.test.ts`

**Step 1: Write the failing test**

```typescript
// tests/search.test.ts
import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mkdtempSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { KnowledgeBase } from "../src/db.js";
import { VectorStore } from "../src/vector-store.js";
import { HybridSearch } from "../src/search.js";
import type { VoyageClient } from "../src/embeddings.js";

function mockVoyageClient(): VoyageClient {
  return {
    embedSingle: vi.fn().mockResolvedValue(new Array(4).fill(0.5)),
    embed: vi.fn().mockResolvedValue({ embeddings: [], totalTokens: 0 }),
  } as unknown as VoyageClient;
}

describe("HybridSearch", () => {
  let tmpDir: string;
  let kb: KnowledgeBase;
  let vectors: VectorStore;
  let search: HybridSearch;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "beeper-kb-search-"));
    kb = new KnowledgeBase(tmpDir);
    vectors = new VectorStore(tmpDir, 4);

    // Insert test documents
    const docs = [
      { id: "d1", source: "seed" as const, content: "Webhooks are the number one request for Beeper API", title: "Webhooks", author: "batuhan" },
      { id: "d2", source: "seed" as const, content: "Discord bridge can get you banned permanently", title: "Discord Warning", author: "keith" },
      { id: "d3", source: "seed" as const, content: "iMessage integration is part of Beeper Desktop app", title: "iMessage", author: "tulir" },
    ];

    for (const d of docs) {
      kb.insertDocument({
        ...d, sourceId: null, room: null, chunkIndex: 0, parentId: null,
        createdAt: new Date().toISOString(), ingestedAt: new Date().toISOString(), metadata: {},
      });
      // Mock vectors: d1 close to query, d2 far, d3 medium
      const vec = d.id === "d1" ? [0.9, 0.1, 0, 0]
        : d.id === "d2" ? [0, 0, 0.9, 0.1]
        : [0.5, 0.5, 0, 0];
      vectors.add(d.id, vec);
    }

    search = new HybridSearch(kb, vectors, mockVoyageClient());
  });

  afterEach(() => {
    kb.close();
    rmSync(tmpDir, { recursive: true, force: true });
  });

  it("returns semantic results ranked by score", async () => {
    const results = await search.search("webhooks API request", 3);
    expect(results.length).toBeGreaterThan(0);
    // d1 should rank highest (closest vector to query)
    expect(results[0].document.id).toBe("d1");
  });

  it("includes FTS results for exact matches", async () => {
    const results = await search.search("Discord bridge banned", 3);
    // FTS should find d2 via "Discord" + "bridge" + "banned"
    const d2 = results.find((r) => r.document.id === "d2");
    expect(d2).toBeDefined();
  });

  it("respects limit parameter", async () => {
    const results = await search.search("beeper", 1);
    expect(results).toHaveLength(1);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/search.test.ts
```

**Step 3: Write search.ts**

```typescript
// src/search.ts
import type { KnowledgeBase } from "./db.js";
import type { VectorStore } from "./vector-store.js";
import type { VoyageClient } from "./embeddings.js";
import type { SearchResult, Source } from "./types.js";

export class HybridSearch {
  constructor(
    private kb: KnowledgeBase,
    private vectors: VectorStore,
    private voyage: VoyageClient,
  ) {}

  async search(
    query: string,
    limit: number,
    opts?: { source?: Source; dateFrom?: string; dateTo?: string },
  ): Promise<SearchResult[]> {
    const resultMap = new Map<string, SearchResult>();

    // 1. Semantic search via FAISS
    if (this.vectors.count() > 0) {
      const queryVec = await this.voyage.embedSingle(query);
      const semanticHits = this.vectors.search(queryVec, limit * 2);

      for (const hit of semanticHits) {
        const doc = this.kb.getDocument(hit.id);
        if (!doc) continue;
        if (opts?.source && doc.source !== opts.source) continue;
        if (opts?.dateFrom && doc.createdAt < opts.dateFrom) continue;
        if (opts?.dateTo && doc.createdAt > opts.dateTo) continue;

        resultMap.set(hit.id, {
          document: doc,
          score: hit.score,
          matchType: "semantic",
        });
      }
    }

    // 2. Full-text search via FTS5
    try {
      const ftsResults = this.kb.ftsSearch(query, limit * 2);
      for (const doc of ftsResults) {
        if (opts?.source && doc.source !== opts.source) continue;
        if (opts?.dateFrom && doc.createdAt < opts.dateFrom) continue;
        if (opts?.dateTo && doc.createdAt > opts.dateTo) continue;

        if (resultMap.has(doc.id)) {
          // Boost hybrid matches
          const existing = resultMap.get(doc.id)!;
          existing.score += 0.2;
          existing.matchType = "hybrid";
        } else {
          resultMap.set(doc.id, {
            document: doc,
            score: 0.5, // Base FTS score
            matchType: "fts",
          });
        }
      }
    } catch {
      // FTS5 can throw on malformed queries — fall through to semantic only
    }

    // 3. Sort by score descending and limit
    const results = Array.from(resultMap.values())
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    return results;
  }
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/search.test.ts
```

Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/search.ts tests/search.test.ts
git commit -m "feat: add hybrid search engine (FAISS semantic + FTS5)"
```

---

## Task 8: Seed Harvester

**Files:**
- Create: `~/repos/beeper-kb/src/harvester/seed.ts`
- Create: `~/repos/beeper-kb/tests/harvester/seed.test.ts`

This harvester imports existing markdown files (the community analysis and learnings).

**Step 1: Write the failing test**

```typescript
// tests/harvester/seed.test.ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { seedFromFile } from "../../src/harvester/seed.js";

describe("seedFromFile", () => {
  let tmpDir: string;

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), "beeper-kb-seed-"));
  });

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true });
  });

  it("parses a markdown file into chunked documents", () => {
    const content = [
      "# Beeper Knowledge",
      "",
      "## Section 1: API Tips",
      "",
      "The API endpoint is localhost:23373. Use Bearer token authentication.",
      "",
      "## Section 2: Bridge Notes",
      "",
      "Discord bridge can get you banned. WhatsApp cloud bridge is more stable.",
    ].join("\n");

    const filePath = join(tmpDir, "test.md");
    writeFileSync(filePath, content);

    const docs = seedFromFile(filePath, "seed");
    expect(docs.length).toBeGreaterThanOrEqual(1);
    expect(docs[0].source).toBe("seed");
    expect(docs[0].title).toContain("test.md");
    // All content should be represented across chunks
    const allContent = docs.map((d) => d.content).join(" ");
    expect(allContent).toContain("localhost:23373");
    expect(allContent).toContain("Discord bridge");
  });

  it("assigns sequential chunk indices", () => {
    // Create a large file that will produce multiple chunks
    const sections = Array.from({ length: 20 }, (_, i) =>
      `## Section ${i}\n\n${"Lorem ipsum dolor sit amet. ".repeat(50)}`
    );
    const filePath = join(tmpDir, "large.md");
    writeFileSync(filePath, sections.join("\n\n"));

    const docs = seedFromFile(filePath, "seed");
    expect(docs.length).toBeGreaterThan(1);
    for (let i = 0; i < docs.length; i++) {
      expect(docs[i].chunkIndex).toBe(i);
    }
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/harvester/seed.test.ts
```

**Step 3: Write seed.ts**

```typescript
// src/harvester/seed.ts
import { readFileSync } from "fs";
import { basename } from "path";
import { randomUUID } from "crypto";
import { chunkMarkdown } from "../chunker.js";
import { CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS } from "../config.js";
import type { Document, Source } from "../types.js";

export function seedFromFile(filePath: string, source: Source): Document[] {
  const content = readFileSync(filePath, "utf-8");
  const fileName = basename(filePath);
  const parentId = randomUUID();
  const now = new Date().toISOString();

  const chunks = chunkMarkdown(content, CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS);

  return chunks.map((chunk) => ({
    id: chunks.length === 1 ? parentId : randomUUID(),
    source,
    sourceId: filePath,
    room: null,
    author: null,
    title: `${fileName} (chunk ${chunk.chunkIndex + 1}/${chunks.length})`,
    content: chunk.content,
    chunkIndex: chunk.chunkIndex,
    parentId: chunks.length === 1 ? null : parentId,
    createdAt: now,
    ingestedAt: now,
    metadata: { filePath, fileName, totalChunks: chunks.length },
  }));
}

export function seedFromFiles(filePaths: string[], source: Source): Document[] {
  return filePaths.flatMap((fp) => seedFromFile(fp, source));
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/harvester/seed.test.ts
```

Expected: All 2 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/harvester/seed.ts tests/harvester/seed.test.ts
git commit -m "feat: add seed harvester for importing existing markdown files"
```

---

## Task 9: Matrix Chat Harvester

**Files:**
- Create: `~/repos/beeper-kb/src/harvester/matrix-chat.ts`
- Create: `~/repos/beeper-kb/tests/harvester/matrix-chat.test.ts`

This is the biggest harvester. It calls the Beeper Desktop API directly (same approach as
beeper-extended's BeeperClient) to paginate through Matrix room messages.

**Step 1: Write the failing test**

```typescript
// tests/harvester/matrix-chat.test.ts
import { describe, it, expect, vi } from "vitest";
import { groupIntoConversations, type RawMessage } from "../../src/harvester/matrix-chat.js";

describe("groupIntoConversations", () => {
  const baseTime = new Date("2025-10-01T12:00:00Z").getTime();

  function msg(id: string, sender: string, text: string, minutesOffset: number): RawMessage {
    return {
      id,
      senderID: sender,
      text,
      timestamp: new Date(baseTime + minutesOffset * 60_000).toISOString(),
      type: "message",
    };
  }

  it("groups consecutive messages by same author", () => {
    const messages: RawMessage[] = [
      msg("1", "alice", "Hello", 0),
      msg("2", "alice", "How are you?", 1),
      msg("3", "bob", "I'm fine!", 2),
    ];

    const groups = groupIntoConversations(messages, 5);
    expect(groups).toHaveLength(2);
    expect(groups[0].author).toBe("alice");
    expect(groups[0].messages).toHaveLength(2);
    expect(groups[1].author).toBe("bob");
  });

  it("splits on time gap even for same author", () => {
    const messages: RawMessage[] = [
      msg("1", "alice", "First message", 0),
      msg("2", "alice", "Much later message", 30), // 30 min gap
    ];

    const groups = groupIntoConversations(messages, 5);
    expect(groups).toHaveLength(2);
  });

  it("filters out non-message events", () => {
    const messages: RawMessage[] = [
      { id: "1", senderID: "alice", text: "Hello", timestamp: new Date(baseTime).toISOString(), type: "message" },
      { id: "2", senderID: "system", text: null, timestamp: new Date(baseTime + 60_000).toISOString(), type: "reaction" },
    ];

    const groups = groupIntoConversations(messages, 5);
    expect(groups).toHaveLength(1);
    expect(groups[0].messages).toHaveLength(1);
  });
});
```

**Step 2: Run test to verify it fails**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/harvester/matrix-chat.test.ts
```

**Step 3: Write matrix-chat.ts**

```typescript
// src/harvester/matrix-chat.ts
import { randomUUID } from "crypto";
import { chunkText } from "../chunker.js";
import { CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS, BEEPER_BASE_URL, BEEPER_TOKEN } from "../config.js";
import type { Document, HarvestResult } from "../types.js";

export interface RawMessage {
  id: string;
  senderID: string;
  text: string | null;
  timestamp: string;
  type: string;
}

export interface ConversationGroup {
  author: string;
  messages: RawMessage[];
  startTime: string;
  endTime: string;
}

/**
 * Group raw messages into conversation turns.
 * A new group starts when:
 * 1. The sender changes
 * 2. The time gap exceeds `gapMinutes`
 */
export function groupIntoConversations(
  messages: RawMessage[],
  gapMinutes: number,
): ConversationGroup[] {
  // Filter to actual text messages
  const textMessages = messages.filter(
    (m) => m.type === "message" && m.text && m.text.trim().length > 0,
  );

  if (textMessages.length === 0) return [];

  const groups: ConversationGroup[] = [];
  let current: ConversationGroup = {
    author: textMessages[0].senderID,
    messages: [textMessages[0]],
    startTime: textMessages[0].timestamp,
    endTime: textMessages[0].timestamp,
  };

  for (let i = 1; i < textMessages.length; i++) {
    const msg = textMessages[i];
    const prevTime = new Date(current.endTime).getTime();
    const currTime = new Date(msg.timestamp).getTime();
    const gapMs = currTime - prevTime;
    const gapMins = gapMs / 60_000;

    if (msg.senderID !== current.author || gapMins > gapMinutes) {
      groups.push(current);
      current = {
        author: msg.senderID,
        messages: [msg],
        startTime: msg.timestamp,
        endTime: msg.timestamp,
      };
    } else {
      current.messages.push(msg);
      current.endTime = msg.timestamp;
    }
  }
  groups.push(current);

  return groups;
}

/**
 * Convert conversation groups into chunked documents.
 */
export function conversationsToDocuments(
  groups: ConversationGroup[],
  room: string,
): Document[] {
  const docs: Document[] = [];

  for (const group of groups) {
    const text = group.messages.map((m) => m.text!).join("\n");
    const parentId = randomUUID();
    const now = new Date().toISOString();

    const chunks = chunkText(text, CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS);

    for (const chunk of chunks) {
      docs.push({
        id: chunks.length === 1 ? parentId : randomUUID(),
        source: "matrix-chat",
        sourceId: group.messages[0].id,
        room,
        author: group.author,
        title: null,
        content: chunk.content,
        chunkIndex: chunk.chunkIndex,
        parentId: chunks.length === 1 ? null : parentId,
        createdAt: group.startTime,
        ingestedAt: now,
        metadata: {
          messageCount: group.messages.length,
          startTime: group.startTime,
          endTime: group.endTime,
        },
      });
    }
  }

  return docs;
}

/**
 * Fetch messages from a Beeper chat via the Desktop API.
 * Paginates backward from newest to oldest.
 */
export async function fetchChatMessages(
  chatId: string,
  afterCursor?: string | null,
): Promise<{ messages: RawMessage[]; nextCursor: string | null }> {
  const baseUrl = BEEPER_BASE_URL.replace(/\/+$/, "");
  const params = new URLSearchParams({ limit: "100" });
  if (afterCursor) params.set("before", afterCursor);

  const url = `${baseUrl}/v1/chats/${encodeURIComponent(chatId)}/messages?${params}`;
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (BEEPER_TOKEN) headers["Authorization"] = `Bearer ${BEEPER_TOKEN}`;

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Beeper API error (${response.status}): ${await response.text()}`);
  }

  const data = (await response.json()) as {
    items?: RawMessage[];
    cursor?: string;
  };

  return {
    messages: data.items || [],
    nextCursor: data.cursor || null,
  };
}

/**
 * Harvest all messages from a chat, paginating through history.
 */
export async function harvestChat(
  chatId: string,
  room: string,
  startCursor?: string | null,
): Promise<{ documents: Document[]; lastCursor: string | null; totalMessages: number }> {
  const allMessages: RawMessage[] = [];
  let cursor = startCursor || null;
  let hasMore = true;

  while (hasMore) {
    const { messages, nextCursor } = await fetchChatMessages(chatId, cursor);
    if (messages.length === 0) break;
    allMessages.push(...messages);
    cursor = nextCursor;
    hasMore = !!nextCursor;

    // Rate limit: small delay between pages
    await new Promise((resolve) => setTimeout(resolve, 200));
  }

  // Sort oldest first
  allMessages.sort(
    (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
  );

  const groups = groupIntoConversations(allMessages, 5);
  const documents = conversationsToDocuments(groups, room);

  return { documents, lastCursor: cursor, totalMessages: allMessages.length };
}
```

**Step 4: Run test to verify it passes**

```bash
cd ~/repos/beeper-kb
npx vitest run tests/harvester/matrix-chat.test.ts
```

Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd ~/repos/beeper-kb
git add src/harvester/matrix-chat.ts tests/harvester/matrix-chat.test.ts
git commit -m "feat: add Matrix chat harvester with conversation grouping"
```

---

## Task 10: Harvester Orchestrator

**Files:**
- Create: `~/repos/beeper-kb/src/harvester/index.ts`

This orchestrator coordinates all harvester modules and manages the ingest pipeline
(chunk → embed → store).

**Step 1: Write harvester/index.ts**

```typescript
// src/harvester/index.ts
import type { KnowledgeBase } from "../db.js";
import type { VectorStore } from "../vector-store.js";
import type { VoyageClient } from "../embeddings.js";
import type { Document, HarvestResult, Source } from "../types.js";
import { seedFromFiles } from "./seed.js";
import { harvestChat } from "./matrix-chat.js";

export class Harvester {
  constructor(
    private kb: KnowledgeBase,
    private vectors: VectorStore,
    private voyage: VoyageClient,
  ) {}

  /**
   * Ingest documents: store in SQLite, generate embeddings, add to FAISS.
   */
  async ingest(documents: Document[], tags?: string[]): Promise<number> {
    if (documents.length === 0) return 0;

    // Store in SQLite
    this.kb.insertDocuments(documents);

    // Generate embeddings in batches
    const texts = documents.map((d) => d.content);
    const { embeddings } = await this.voyage.embed(texts);

    // Add to FAISS
    const ids = documents.map((d) => d.id);
    this.vectors.addBatch(ids, embeddings);

    // Add tags if provided
    if (tags) {
      for (const doc of documents) {
        this.kb.addTags(doc.id, tags);
      }
    }

    // Persist FAISS index
    this.vectors.save();

    return documents.length;
  }

  /**
   * Seed from existing markdown files.
   */
  async harvestSeed(filePaths: string[]): Promise<HarvestResult> {
    const documents = seedFromFiles(filePaths, "seed");
    const count = await this.ingest(documents, ["seed"]);

    this.kb.updateHarvestState("seed", null, count);

    return {
      source: "seed",
      newDocs: count,
      updatedDocs: 0,
      errors: [],
    };
  }

  /**
   * Harvest Matrix chat messages from a Beeper chat room.
   */
  async harvestMatrixChat(
    chatId: string,
    room: string,
    full?: boolean,
  ): Promise<HarvestResult> {
    const errors: string[] = [];

    try {
      const state = full ? null : this.kb.getHarvestState(`matrix-chat:${room}`);
      const { documents, lastCursor, totalMessages } = await harvestChat(
        chatId,
        room,
        state?.lastCursor,
      );

      const count = await this.ingest(documents, ["matrix-chat", room]);
      this.kb.updateHarvestState(
        `matrix-chat:${room}`,
        lastCursor,
        (state?.docCount || 0) + count,
      );

      return { source: "matrix-chat", newDocs: count, updatedDocs: 0, errors };
    } catch (error) {
      errors.push(String(error));
      return { source: "matrix-chat", newDocs: 0, updatedDocs: 0, errors };
    }
  }
}
```

**Step 2: Build and verify compilation**

```bash
cd ~/repos/beeper-kb
npx tsc --noEmit
```

Expected: No errors.

**Step 3: Commit**

```bash
cd ~/repos/beeper-kb
git add src/harvester/index.ts
git commit -m "feat: add harvester orchestrator with ingest pipeline"
```

---

## Task 11: MCP Server Entry Point and Tools

**Files:**
- Create: `~/repos/beeper-kb/src/tools/kb-search.ts`
- Create: `~/repos/beeper-kb/src/tools/kb-ingest.ts`
- Create: `~/repos/beeper-kb/src/tools/kb-harvest.ts`
- Create: `~/repos/beeper-kb/src/tools/kb-stats.ts`
- Create: `~/repos/beeper-kb/src/tools/kb-browse.ts`
- Modify: `~/repos/beeper-kb/src/index.ts`

**Step 1: Write tool modules**

Each tool follows the same pattern as beeper-extended: register on an McpServer instance
with zod schemas.

**kb-search.ts:**

```typescript
// src/tools/kb-search.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { HybridSearch } from "../search.js";
import type { Source } from "../types.js";

export function registerSearchTool(server: McpServer, search: HybridSearch) {
  server.tool(
    "kb_search",
    "Semantic search across the Beeper Developer Community knowledge base. Returns relevant documents, code snippets, API tips, bug reports, and community discussions.",
    {
      query: z.string().describe("Search query — natural language or keywords"),
      limit: z.number().int().min(1).max(50).default(10).optional()
        .describe("Maximum results (default: 10)"),
      source: z.enum(["matrix-chat", "docs", "github", "blog", "seed"]).optional()
        .describe("Filter to a specific data source"),
      dateFrom: z.string().optional().describe("ISO date — only results after this date"),
      dateTo: z.string().optional().describe("ISO date — only results before this date"),
    },
    async ({ query, limit = 10, source, dateFrom, dateTo }) => {
      try {
        const results = await search.search(query, limit, {
          source: source as Source | undefined,
          dateFrom,
          dateTo,
        });

        const formatted = results.map((r) => ({
          score: Math.round(r.score * 100) / 100,
          matchType: r.matchType,
          source: r.document.source,
          room: r.document.room,
          author: r.document.author,
          title: r.document.title,
          createdAt: r.document.createdAt,
          content: r.document.content.slice(0, 2000),
        }));

        return {
          content: [{
            type: "text" as const,
            text: JSON.stringify({ results: formatted, total: results.length }, null, 2),
          }],
        };
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: `Error searching: ${error}` }],
          isError: true,
        };
      }
    },
  );
}
```

**kb-ingest.ts:**

```typescript
// src/tools/kb-ingest.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { randomUUID } from "crypto";
import type { Harvester } from "../harvester/index.js";
import { chunkMarkdown } from "../chunker.js";
import { CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS } from "../config.js";
import type { Document, Source } from "../types.js";

export function registerIngestTool(server: McpServer, harvester: Harvester) {
  server.tool(
    "kb_ingest",
    "Add a document to the Beeper knowledge base. Content is chunked, embedded, and indexed for semantic search.",
    {
      content: z.string().describe("Document content (markdown supported)"),
      source: z.enum(["docs", "github", "blog", "seed"]).default("seed")
        .describe("Data source category"),
      title: z.string().optional().describe("Document title"),
      tags: z.array(z.string()).optional().describe("Tags for categorization"),
      author: z.string().optional().describe("Document author"),
    },
    async ({ content, source, title, tags, author }) => {
      try {
        const parentId = randomUUID();
        const now = new Date().toISOString();
        const chunks = chunkMarkdown(content, CHUNK_TARGET_TOKENS, CHUNK_OVERLAP_TOKENS);

        const documents: Document[] = chunks.map((chunk) => ({
          id: chunks.length === 1 ? parentId : randomUUID(),
          source: source as Source,
          sourceId: null,
          room: null,
          author: author || null,
          title: title || null,
          content: chunk.content,
          chunkIndex: chunk.chunkIndex,
          parentId: chunks.length === 1 ? null : parentId,
          createdAt: now,
          ingestedAt: now,
          metadata: { manualIngest: true },
        }));

        const count = await harvester.ingest(documents, tags);

        return {
          content: [{
            type: "text" as const,
            text: JSON.stringify({ id: parentId, chunks: count, source, title }),
          }],
        };
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: `Error ingesting: ${error}` }],
          isError: true,
        };
      }
    },
  );
}
```

**kb-harvest.ts:**

```typescript
// src/tools/kb-harvest.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { Harvester } from "../harvester/index.js";

export function registerHarvestTool(server: McpServer, harvester: Harvester) {
  server.tool(
    "kb_harvest",
    "Trigger a fresh data collection run. Harvests new messages from Beeper community chats and/or seed files.",
    {
      sources: z.array(z.string()).optional()
        .describe("Sources to harvest (default: all). Options: 'seed', 'matrix-chat'"),
      full: z.boolean().default(false).optional()
        .describe("If true, re-harvest from the beginning instead of incremental"),
    },
    async ({ sources, full = false }) => {
      try {
        const results = [];
        const targetSources = sources || ["seed", "matrix-chat"];

        if (targetSources.includes("seed")) {
          // Seed files are hardcoded for now — these are the known existing files
          const seedFiles = [
            `${process.env.HOME}/.claude/beeper-developer-community-analysis.md`,
            `${process.env.HOME}/claude-cross-machine-sync/learnings/beeper.md`,
          ].filter((f) => {
            try { require("fs").accessSync(f); return true; } catch { return false; }
          });

          if (seedFiles.length > 0) {
            const result = await harvester.harvestSeed(seedFiles);
            results.push(result);
          }
        }

        // Matrix chat harvesting requires chat IDs — these will be discovered
        // via Beeper MCP search_chats. For now, report what we can do.
        if (targetSources.includes("matrix-chat")) {
          results.push({
            source: "matrix-chat",
            newDocs: 0,
            updatedDocs: 0,
            errors: ["Matrix chat harvesting requires chat IDs. Use search_chats to find community room IDs first."],
          });
        }

        return {
          content: [{
            type: "text" as const,
            text: JSON.stringify({ results, timestamp: new Date().toISOString() }, null, 2),
          }],
        };
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: `Error harvesting: ${error}` }],
          isError: true,
        };
      }
    },
  );
}
```

**kb-stats.ts:**

```typescript
// src/tools/kb-stats.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { KnowledgeBase } from "../db.js";
import type { VectorStore } from "../vector-store.js";

export function registerStatsTool(server: McpServer, kb: KnowledgeBase, vectors: VectorStore) {
  server.tool(
    "kb_stats",
    "Get statistics about the Beeper knowledge base: document counts, source breakdown, vector index size.",
    {},
    async () => {
      const stats = kb.getStats();
      return {
        content: [{
          type: "text" as const,
          text: JSON.stringify({
            ...stats,
            vectorCount: vectors.count(),
            lastUpdated: new Date().toISOString(),
          }, null, 2),
        }],
      };
    },
  );
}
```

**kb-browse.ts:**

```typescript
// src/tools/kb-browse.ts
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { KnowledgeBase } from "../db.js";
import type { Source } from "../types.js";

export function registerBrowseTool(server: McpServer, kb: KnowledgeBase) {
  server.tool(
    "kb_browse",
    "Browse the Beeper knowledge base by source, tag, author, or room. Returns document previews.",
    {
      source: z.enum(["matrix-chat", "docs", "github", "blog", "seed"]).optional(),
      tag: z.string().optional().describe("Filter by tag"),
      author: z.string().optional().describe("Filter by author"),
      room: z.string().optional().describe("Filter by Matrix room"),
      limit: z.number().int().min(1).max(100).default(20).optional(),
      offset: z.number().int().min(0).default(0).optional(),
    },
    async ({ source, tag, author, room, limit = 20, offset = 0 }) => {
      try {
        const docs = kb.browseDocuments({
          source: source as Source | undefined,
          tag,
          author,
          room,
          limit,
          offset,
        });

        const formatted = docs.map((d) => ({
          id: d.id,
          source: d.source,
          room: d.room,
          author: d.author,
          title: d.title,
          createdAt: d.createdAt,
          preview: d.content.slice(0, 300),
        }));

        return {
          content: [{
            type: "text" as const,
            text: JSON.stringify({ documents: formatted, count: formatted.length, offset }, null, 2),
          }],
        };
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: `Error browsing: ${error}` }],
          isError: true,
        };
      }
    },
  );
}
```

**Step 2: Write the MCP server entry point (index.ts)**

```typescript
// src/index.ts
#!/usr/bin/env node
/**
 * Beeper Knowledge Base MCP Server
 *
 * Semantic search across Beeper Developer Community knowledge:
 * - Matrix community chat history
 * - Developer documentation
 * - GitHub repositories
 * - Blog articles
 * - Existing knowledge files
 */
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { DATA_DIR, VOYAGE_API_KEY, VOYAGE_DIMENSIONS } from "./config.js";
import { KnowledgeBase } from "./db.js";
import { VectorStore } from "./vector-store.js";
import { VoyageClient } from "./embeddings.js";
import { HybridSearch } from "./search.js";
import { Harvester } from "./harvester/index.js";
import { registerSearchTool } from "./tools/kb-search.js";
import { registerIngestTool } from "./tools/kb-ingest.js";
import { registerHarvestTool } from "./tools/kb-harvest.js";
import { registerStatsTool } from "./tools/kb-stats.js";
import { registerBrowseTool } from "./tools/kb-browse.js";

async function main() {
  // Initialize storage
  const kb = new KnowledgeBase(DATA_DIR);
  const vectors = new VectorStore(DATA_DIR, VOYAGE_DIMENSIONS);

  // Initialize embedding client
  let voyage: VoyageClient;
  try {
    voyage = new VoyageClient(VOYAGE_API_KEY);
  } catch {
    console.error("[beeper-kb] WARNING: No VOYAGE_API_KEY — semantic search disabled, FTS only");
    // Create a dummy client that returns zero vectors
    voyage = {
      embed: async (texts: string[]) => ({
        embeddings: texts.map(() => new Array(VOYAGE_DIMENSIONS).fill(0)),
        totalTokens: 0,
      }),
      embedSingle: async () => new Array(VOYAGE_DIMENSIONS).fill(0),
    } as unknown as VoyageClient;
  }

  // Wire up components
  const search = new HybridSearch(kb, vectors, voyage);
  const harvester = new Harvester(kb, vectors, voyage);

  // Create MCP server
  const server = new McpServer({
    name: "beeper-kb",
    version: "1.0.0",
  });

  // Register tools
  registerSearchTool(server, search);
  registerIngestTool(server, harvester);
  registerHarvestTool(server, harvester);
  registerStatsTool(server, kb, vectors);
  registerBrowseTool(server, kb);

  // Start server
  const transport = new StdioServerTransport();
  await server.connect(transport);

  const stats = kb.getStats();
  console.error(`[beeper-kb] MCP server running (5 tools, ${stats.totalDocs} documents, ${vectors.count()} vectors)`);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
```

**Step 3: Build**

```bash
cd ~/repos/beeper-kb
npx tsc
```

Expected: Clean compilation, no errors.

**Step 4: Commit**

```bash
cd ~/repos/beeper-kb
git add src/tools/ src/index.ts
git commit -m "feat: add MCP server with 5 tools (search, ingest, harvest, stats, browse)"
```

---

## Task 12: Run All Tests

**Step 1: Run the full test suite**

```bash
cd ~/repos/beeper-kb
npx vitest run
```

Expected: All tests pass (db: 6, chunker: 6, embeddings: 3, vector-store: 4, search: 3, seed: 2, matrix-chat: 3 = ~27 tests).

**Step 2: Fix any failures**

Address any test failures before proceeding.

**Step 3: Verify the MCP server starts**

```bash
cd ~/repos/beeper-kb
echo '{}' | timeout 3 node dist/index.js 2>&1 || true
```

Expected: Starts and prints `[beeper-kb] MCP server running (5 tools, 0 documents, 0 vectors)`.

**Step 4: Commit if any fixes needed**

```bash
cd ~/repos/beeper-kb
git add -A
git commit -m "fix: resolve test failures and verify MCP server startup"
```

---

## Task 13: Deploy — Register MCP Server

**Files:**
- Modify: `~/.claude.json` — add `beeper-kb` MCP server entry

**Step 1: Get a Voyage API key**

Go to https://dash.voyageai.com/ and create an API key.
The free tier includes 200M tokens — more than enough for our knowledge base.

Save the key:
```bash
# Store in a secure location
echo "YOUR_VOYAGE_API_KEY" > ~/.beeper-kb-voyage-key
chmod 600 ~/.beeper-kb-voyage-key
```

**Step 2: Add beeper-kb to ~/.claude.json**

Add this entry to the `mcpServers` object in `~/.claude.json`:

```json
"beeper-kb": {
  "command": "node",
  "args": ["/home/rob/repos/beeper-kb/dist/index.js"],
  "env": {
    "VOYAGE_API_KEY": "YOUR_KEY_HERE",
    "BEEPER_KB_DATA_DIR": "/home/rob/.beeper-kb"
  }
}
```

**Step 3: Restart Claude Code to load the new MCP server**

**Step 4: Verify the server loads**

In a new Claude Code session, run:
```
/tool beeper-kb
```
Or ask: "What tools does beeper-kb provide?"

Expected: 5 tools listed (kb_search, kb_ingest, kb_harvest, kb_stats, kb_browse).

**Step 5: Commit the project**

```bash
cd ~/repos/beeper-kb
git add -A
git commit -m "chore: finalize beeper-kb v1.0.0 for deployment"
```

---

## Task 14: Initial Harvest — Seed Existing Knowledge

**Step 1: Run seed harvest via MCP**

Use the `kb_harvest` tool:
```
kb_harvest sources=["seed"]
```

Expected: Seeds `~/.claude/beeper-developer-community-analysis.md` (539 lines) and
`~/claude-cross-machine-sync/learnings/beeper.md` (710+ lines) into the knowledge base.

**Step 2: Verify with stats**

```
kb_stats
```

Expected: Shows documents > 0, vectors > 0.

**Step 3: Test search**

```
kb_search query="webhooks API feature request"
```

Expected: Returns relevant results about webhooks being the #1 feature request from batuhan.

```
kb_search query="Discord bridge ban"
```

Expected: Returns results about Discord bridge getting users banned.

**Step 4: Commit harvest state**

The SQLite DB and FAISS index are in `~/.beeper-kb/` (gitignored — data only).
No commit needed for the data, but verify it persists across restarts.

---

## Task 15: Matrix Chat Harvest (Live Data)

This task requires Beeper Desktop running with the MCP API active.

**Step 1: Find community room chat IDs**

Use the Beeper MCP `search_chats` tool to find the SDK room:
```
search_chats query="Beeper Developer" type="group"
```

Note the `chatID` for the developer community room.

**Step 2: Harvest chat history**

Use `kb_harvest` or call the harvester directly:
```
kb_harvest sources=["matrix-chat"] full=true
```

Or via the harvester code, provide the chat ID discovered in Step 1.

**Step 3: Verify results**

```
kb_stats
```

Expected: Significantly more documents (hundreds or thousands) from the chat harvest.

**Step 4: Test search with community-specific queries**

```
kb_search query="how to create a new chat with WhatsApp contact"
kb_search query="Rishi polling daemon"
kb_search query="batuhan headless desktop API"
```

Expected: Relevant results from community chat history.

---

## Summary

| Task | What it builds | Tests |
|------|----------------|-------|
| 1 | Project scaffolding | — |
| 2 | Types and config | — |
| 3 | SQLite database layer | 6 |
| 4 | Text chunker | 6 |
| 5 | Voyage embedding client | 3 |
| 6 | FAISS vector store | 4 |
| 7 | Hybrid search engine | 3 |
| 8 | Seed harvester | 2 |
| 9 | Matrix chat harvester | 3 |
| 10 | Harvester orchestrator | — |
| 11 | MCP server + 5 tools | — |
| 12 | Full test run | all ~27 |
| 13 | Deploy MCP server | — |
| 14 | Initial seed harvest | — |
| 15 | Live chat harvest | — |

**Total:** 15 tasks, ~27 tests, ~15 commits
