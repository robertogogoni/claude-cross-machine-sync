# Beeper Extended v2.0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite beeper-extended MCP plugin from 4 tools to 14, with modular architecture, robust auth, typed schemas, and full Beeper Desktop API coverage.

**Architecture:** Modular rewrite — shared API client (`client.ts`) with cascading auth chain (`auth.ts`), Zod response schemas (`types.ts`), per-domain tool files (`tools/*.ts`). Each tool module registers itself with the MCP server via an exported function.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk, Zod, esbuild (ESM bundle), vitest (unit tests), Node.js 18+ (native fetch/FormData)

**Plugin Root:** `/home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0`
**MCP Root:** `/home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp`

---

## Task 1: Add Test Infrastructure

**Files:**
- Modify: `mcp/package.json`
- Create: `mcp/vitest.config.ts`

**Step 1: Install vitest**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npm install -D vitest
```
Expected: vitest added to devDependencies

**Step 2: Add test script to package.json**

Update `mcp/package.json`:
```json
{
  "name": "beeper-extended-mcp",
  "version": "2.0.0",
  "description": "Full-featured Beeper API extension: message editing, file uploads, reactions, asset management",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "mkdir -p dist && esbuild src/index.ts --bundle --platform=node --format=esm --outfile=dist/index.js --external:fsevents",
    "clean": "rm -rf dist",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "esbuild": "^0.20.0",
    "typescript": "^5.0.0",
    "vitest": "^3.0.0"
  }
}
```

**Step 3: Create vitest config**

Create `mcp/vitest.config.ts`:
```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
```

**Step 4: Verify vitest runs (no tests yet)**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run
```
Expected: "No test files found" or similar (no error)

**Step 5: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git init 2>/dev/null
git add mcp/package.json mcp/vitest.config.ts
git commit -m "chore: add vitest test infrastructure for v2.0"
```

---

## Task 2: Create Auth Module

**Files:**
- Create: `mcp/src/auth.ts`
- Create: `mcp/src/auth.test.ts`

**Step 1: Write the failing test**

Create `mcp/src/auth.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { resolveToken, resolveBaseUrl } from "./auth.js";

describe("resolveBaseUrl", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("returns env var when BEEPER_BASE_URL is set", () => {
    process.env.BEEPER_BASE_URL = "http://custom:9999";
    expect(resolveBaseUrl()).toBe("http://custom:9999");
  });

  it("returns default localhost when env var not set", () => {
    delete process.env.BEEPER_BASE_URL;
    expect(resolveBaseUrl()).toBe("http://localhost:23373");
  });
});

describe("resolveToken", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("returns env var when BEEPER_TOKEN is set", async () => {
    process.env.BEEPER_TOKEN = "test-token-123";
    const token = await resolveToken();
    expect(token).toBe("test-token-123");
  });

  it("returns null when no token source available", async () => {
    delete process.env.BEEPER_TOKEN;
    // With no files present, should return null gracefully
    const token = await resolveToken();
    expect(token).toBeNull();
  });
});
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/auth.test.ts
```
Expected: FAIL — `resolveToken` and `resolveBaseUrl` not found

**Step 3: Write implementation**

Create `mcp/src/auth.ts`:
```typescript
import { readFile } from "fs/promises";
import { join } from "path";
import { homedir } from "os";

const DEFAULT_BASE_URL = "http://localhost:23373";

const TOKEN_FILE_PATHS = [
  ".config/Claude/Claude Extensions/local.dxt.beeper.beepermcp-remote/.mcp-auth/tokens.json",
  ".beeper-mcp-token",
];

export function resolveBaseUrl(): string {
  return process.env.BEEPER_BASE_URL || DEFAULT_BASE_URL;
}

export async function resolveToken(): Promise<string | null> {
  // Priority 1: Explicit env var
  if (process.env.BEEPER_TOKEN) {
    return process.env.BEEPER_TOKEN;
  }

  // Priority 2-3: File-based token sources
  const home = homedir();
  for (const relativePath of TOKEN_FILE_PATHS) {
    const fullPath = join(home, relativePath);
    try {
      const content = await readFile(fullPath, "utf-8");
      const data = JSON.parse(content);
      if (data.access_token) return data.access_token;
      if (data.token) return data.token;
      if (typeof data === "string") return data;
    } catch {
      // File doesn't exist or isn't readable — try next
    }
  }

  // Priority 4: No auth (localhost-only, unauthenticated)
  return null;
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/auth.test.ts
```
Expected: PASS (2 suites, 3 tests)

**Step 5: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/auth.ts mcp/src/auth.test.ts
git commit -m "feat: add auth module with cascading token resolution"
```

---

## Task 3: Create API Client

**Files:**
- Create: `mcp/src/client.ts`
- Create: `mcp/src/client.test.ts`

**Step 1: Write the failing test**

Create `mcp/src/client.test.ts`:
```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";
import { BeeperClient, BeeperApiError, formatApiError } from "./client.js";

describe("formatApiError", () => {
  it("formats 401 with auth guidance", () => {
    const msg = formatApiError(401, "Unauthorized");
    expect(msg).toContain("Auth failed");
    expect(msg).toContain("BEEPER_TOKEN");
  });

  it("formats 404 with version guidance", () => {
    const msg = formatApiError(404, "Not Found");
    expect(msg).toContain("not found");
    expect(msg).toContain("Beeper Desktop version");
  });

  it("formats 409 as conflict", () => {
    const msg = formatApiError(409, "Conflict");
    expect(msg).toContain("Conflict");
  });

  it("formats 429 as rate limit", () => {
    const msg = formatApiError(429, "Too Many Requests");
    expect(msg).toContain("Rate limited");
  });

  it("formats 500+ as server error", () => {
    const msg = formatApiError(502, "Bad Gateway");
    expect(msg).toContain("Beeper Desktop running");
  });

  it("formats unknown codes with raw details", () => {
    const msg = formatApiError(418, "I'm a teapot");
    expect(msg).toContain("418");
    expect(msg).toContain("I'm a teapot");
  });
});

describe("BeeperClient", () => {
  let client: BeeperClient;

  beforeEach(() => {
    client = new BeeperClient("http://test:1234", null);
  });

  it("constructs with base URL and token", () => {
    const authed = new BeeperClient("http://test:1234", "my-token");
    expect(authed).toBeDefined();
  });
});
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/client.test.ts
```
Expected: FAIL — module not found

**Step 3: Write implementation**

Create `mcp/src/client.ts`:
```typescript
export class BeeperApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly statusText: string,
    public readonly body: string,
  ) {
    super(formatApiError(status, body || statusText));
    this.name = "BeeperApiError";
  }
}

export function formatApiError(status: number, body: string): string {
  switch (status) {
    case 401:
      return `Auth failed (401): ${body}. Set BEEPER_TOKEN env var or check ~/.beeper-mcp-token`;
    case 404:
      return `Endpoint not found (404): ${body}. Check Beeper Desktop version (some features require v4.2.499+)`;
    case 409:
      return `Conflict (409): ${body}`;
    case 429:
      return `Rate limited (429): ${body}. Wait a moment and try again`;
    default:
      if (status >= 500) {
        return `Server error (${status}): ${body}. Is Beeper Desktop running?`;
      }
      return `Beeper API error (${status}): ${body}`;
  }
}

export class BeeperClient {
  private baseUrl: string;
  private token: string | null;
  private debug: boolean;

  constructor(baseUrl: string, token: string | null) {
    this.baseUrl = baseUrl.replace(/\/+$/, "");
    this.token = token;
    this.debug = process.env.BEEPER_DEBUG === "1";
  }

  private headers(contentType?: string): Record<string, string> {
    const h: Record<string, string> = {};
    if (contentType) {
      h["Content-Type"] = contentType;
    }
    if (this.token) {
      h["Authorization"] = `Bearer ${this.token}`;
    }
    return h;
  }

  private log(method: string, endpoint: string, status?: number) {
    if (this.debug) {
      console.error(`[beeper-extended] ${method} ${endpoint}${status ? ` → ${status}` : ""}`);
    }
  }

  private async request(
    method: string,
    endpoint: string,
    options: { body?: string; headers?: Record<string, string> } = {},
  ): Promise<unknown> {
    const url = `${this.baseUrl}${endpoint}`;
    this.log(method, endpoint);

    const response = await fetch(url, {
      method,
      headers: {
        ...this.headers("application/json"),
        ...options.headers,
      },
      body: options.body,
    });

    this.log(method, endpoint, response.status);

    if (!response.ok) {
      const errorBody = await response.text();
      throw new BeeperApiError(response.status, response.statusText, errorBody);
    }

    if (response.status === 204) {
      return { success: true };
    }

    return response.json();
  }

  async get(endpoint: string, params?: Record<string, string>): Promise<unknown> {
    let ep = endpoint;
    if (params && Object.keys(params).length > 0) {
      const qs = new URLSearchParams(params).toString();
      ep = `${endpoint}?${qs}`;
    }
    return this.request("GET", ep);
  }

  async post(endpoint: string, body?: unknown): Promise<unknown> {
    return this.request("POST", endpoint, {
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  }

  async put(endpoint: string, body?: unknown): Promise<unknown> {
    return this.request("PUT", endpoint, {
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  }

  async del(endpoint: string): Promise<unknown> {
    return this.request("DELETE", endpoint);
  }

  async postFormData(endpoint: string, formData: FormData): Promise<unknown> {
    const url = `${this.baseUrl}${endpoint}`;
    this.log("POST(multipart)", endpoint);

    const headers: Record<string, string> = {};
    if (this.token) {
      headers["Authorization"] = `Bearer ${this.token}`;
    }
    // Do NOT set Content-Type — fetch sets it with boundary for FormData

    const response = await fetch(url, {
      method: "POST",
      headers,
      body: formData,
    });

    this.log("POST(multipart)", endpoint, response.status);

    if (!response.ok) {
      const errorBody = await response.text();
      throw new BeeperApiError(response.status, response.statusText, errorBody);
    }

    if (response.status === 204) {
      return { success: true };
    }

    return response.json();
  }
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/client.test.ts
```
Expected: PASS (2 suites, 7 tests)

**Step 5: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/client.ts mcp/src/client.test.ts
git commit -m "feat: add BeeperClient with typed errors and debug logging"
```

---

## Task 4: Create Type Schemas

**Files:**
- Create: `mcp/src/types.ts`
- Create: `mcp/src/types.test.ts`

**Step 1: Write the failing test**

Create `mcp/src/types.test.ts`:
```typescript
import { describe, it, expect } from "vitest";
import { ContactSchema, ChatSchema, MessageSchema, AssetUploadResponseSchema, ServerInfoSchema } from "./types.js";

describe("ContactSchema", () => {
  it("validates a valid contact", () => {
    const result = ContactSchema.safeParse({
      id: "contact-123",
      name: "Alice",
      avatarURL: "mxc://beeper.local/abc",
    });
    expect(result.success).toBe(true);
  });

  it("allows missing optional fields", () => {
    const result = ContactSchema.safeParse({
      id: "contact-123",
    });
    expect(result.success).toBe(true);
  });

  it("rejects missing id", () => {
    const result = ContactSchema.safeParse({ name: "Alice" });
    expect(result.success).toBe(false);
  });
});

describe("AssetUploadResponseSchema", () => {
  it("validates upload response with uploadID", () => {
    const result = AssetUploadResponseSchema.safeParse({
      uploadID: "upload-abc-123",
      url: "mxc://beeper.local/xyz",
      mimeType: "image/png",
      size: 12345,
    });
    expect(result.success).toBe(true);
  });
});

describe("ServerInfoSchema", () => {
  it("validates server info", () => {
    const result = ServerInfoSchema.safeParse({
      version: "4.2.509",
    });
    expect(result.success).toBe(true);
  });
});
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/types.test.ts
```
Expected: FAIL — module not found

**Step 3: Write implementation**

Create `mcp/src/types.ts`:
```typescript
import { z } from "zod";

// --- Contacts ---

export const ContactSchema = z.object({
  id: z.string(),
  name: z.string().optional(),
  avatarURL: z.string().optional(),
  accountID: z.string().optional(),
}).passthrough();

export type Contact = z.infer<typeof ContactSchema>;

// --- Chats ---

export const ChatSchema = z.object({
  id: z.string(),
  title: z.string().optional(),
  type: z.string().optional(),
  accountID: z.string().optional(),
  lastMessage: z.unknown().optional(),
  participants: z.array(z.unknown()).optional(),
}).passthrough();

export type Chat = z.infer<typeof ChatSchema>;

// --- Messages ---

export const MessageSchema = z.object({
  id: z.string(),
  chatID: z.string().optional(),
  text: z.string().optional(),
  sender: z.unknown().optional(),
  timestamp: z.union([z.string(), z.number()]).optional(),
  attachments: z.array(z.unknown()).optional(),
  reactions: z.array(z.unknown()).optional(),
}).passthrough();

export type Message = z.infer<typeof MessageSchema>;

// --- Assets ---

export const AssetUploadResponseSchema = z.object({
  uploadID: z.string().optional(),
  url: z.string().optional(),
  mimeType: z.string().optional(),
  size: z.number().optional(),
  filename: z.string().optional(),
}).passthrough();

export type AssetUploadResponse = z.infer<typeof AssetUploadResponseSchema>;

export const AssetDownloadResponseSchema = z.object({
  url: z.string().optional(),
  localPath: z.string().optional(),
}).passthrough();

export type AssetDownloadResponse = z.infer<typeof AssetDownloadResponseSchema>;

// --- System ---

export const ServerInfoSchema = z.object({
  version: z.string().optional(),
}).passthrough();

export type ServerInfo = z.infer<typeof ServerInfoSchema>;

// --- Helpers ---

export function jsonResult(data: unknown): { content: Array<{ type: "text"; text: string }> } {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
  };
}

export function errorResult(prefix: string, error: unknown): { content: Array<{ type: "text"; text: string }>; isError: true } {
  const msg = error instanceof Error ? error.message : String(error);
  return {
    content: [{ type: "text" as const, text: `${prefix}: ${msg}` }],
    isError: true,
  };
}
```

**Step 4: Run test to verify it passes**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run src/types.test.ts
```
Expected: PASS (3 suites, 5 tests)

**Step 5: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/types.ts mcp/src/types.test.ts
git commit -m "feat: add Zod schemas and result helpers for all API types"
```

---

## Task 5: Create Contacts Tools

**Files:**
- Create: `mcp/src/tools/contacts.ts`

**Step 1: Create tools directory**

Run:
```bash
mkdir -p /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp/src/tools
```

**Step 2: Write contacts tools**

Create `mcp/src/tools/contacts.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerContactsTools(server: McpServer, client: BeeperClient) {
  // Tool: Search Contacts
  server.tool(
    "search_contacts",
    "Search for contacts on a specific account (WhatsApp, Instagram, etc.) using the network's search API. Use this to find users before creating new chats.",
    {
      accountID: z.string().describe("The account ID to search contacts on (e.g., 'gmessages', 'local-whatsapp_...')"),
      query: z.string().describe("Search query - name or phone number to find"),
      limit: z.number().int().min(1).max(50).default(20).optional()
        .describe("Maximum number of results to return (default: 20)"),
    },
    async ({ accountID, query, limit = 20 }) => {
      try {
        const result = await client.get(
          `/v1/accounts/${encodeURIComponent(accountID)}/contacts`,
          { query, limit: String(limit) },
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error searching contacts", error);
      }
    },
  );

  // Tool: List Contacts (cursor-based)
  server.tool(
    "list_contacts",
    "List all contacts on a specific account with cursor-based pagination. Unlike search_contacts, this returns all contacts without requiring a search query.",
    {
      accountID: z.string().describe("The account ID to list contacts from"),
      cursor: z.string().optional().describe("Pagination cursor from previous response"),
      limit: z.number().int().min(1).max(100).default(50).optional()
        .describe("Maximum number of contacts per page (default: 50)"),
    },
    async ({ accountID, cursor, limit = 50 }) => {
      try {
        const params: Record<string, string> = { limit: String(limit) };
        if (cursor) params.cursor = cursor;

        const result = await client.get(
          `/v1/accounts/${encodeURIComponent(accountID)}/contacts/list`,
          params,
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error listing contacts", error);
      }
    },
  );
}
```

**Step 3: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/contacts.ts
git commit -m "feat: add contacts tools (search + list with cursor pagination)"
```

---

## Task 6: Create Chats Tools

**Files:**
- Create: `mcp/src/tools/chats.ts`

**Step 1: Write chats tools**

Create `mcp/src/tools/chats.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerChatsTools(server: McpServer, client: BeeperClient) {
  // Tool: Create Chat
  server.tool(
    "create_chat",
    "Create a new single (1:1) or group chat on a specific account. Use search_contacts first to find participant IDs.",
    {
      accountID: z.string().describe("The account ID to create the chat on"),
      participantIDs: z.array(z.string()).min(1)
        .describe("Array of participant IDs to include in the chat"),
      type: z.enum(["single", "group"]).default("single").optional()
        .describe("Chat type: 'single' for 1:1, 'group' for group chats"),
      title: z.string().optional().describe("Optional title for group chats"),
      initialMessage: z.string().optional()
        .describe("Optional initial message to send when creating the chat"),
    },
    async ({ accountID, participantIDs, type = "single", title, initialMessage }) => {
      try {
        const body: Record<string, unknown> = {
          accountID,
          participantIDs,
          type,
        };

        if (title && type === "group") {
          body.title = title;
        }

        if (initialMessage) {
          body.initialMessage = { text: initialMessage };
        }

        const result = await client.post("/v1/chats", body);
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error creating chat", error);
      }
    },
  );

  // Tool: List Chats
  server.tool(
    "list_chats",
    "List chats with basic pagination. Unlike search_chats (official MCP), this does not require a search query — it returns all chats ordered by recent activity.",
    {
      limit: z.number().int().min(1).max(200).default(50).optional()
        .describe("Maximum number of chats to return (default: 50)"),
      cursor: z.string().optional().describe("Pagination cursor from previous response"),
      type: z.enum(["single", "group", "any"]).default("any").optional()
        .describe("Filter by chat type (default: any)"),
    },
    async ({ limit = 50, cursor, type = "any" }) => {
      try {
        const params: Record<string, string> = { limit: String(limit) };
        if (cursor) params.cursor = cursor;
        if (type !== "any") params.type = type;

        const result = await client.get("/v1/chats", params);
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error listing chats", error);
      }
    },
  );
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/chats.ts
git commit -m "feat: add chats tools (create + list with pagination)"
```

---

## Task 7: Create Messages Tools

**Files:**
- Create: `mcp/src/tools/messages.ts`

**Step 1: Write messages tools**

Create `mcp/src/tools/messages.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerMessagesTools(server: McpServer, client: BeeperClient) {
  // Tool: Edit Message
  server.tool(
    "edit_message",
    "Edit an existing message's text content. Requires Beeper Desktop v4.2.499+.",
    {
      chatID: z.string().describe("The chat ID containing the message"),
      messageID: z.string().describe("The ID of the message to edit"),
      text: z.string().describe("The new text content for the message"),
    },
    async ({ chatID, messageID, text }) => {
      try {
        const result = await client.put(
          `/v1/chats/${encodeURIComponent(chatID)}/messages/${encodeURIComponent(messageID)}`,
          { text },
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error editing message", error);
      }
    },
  );

  // Tool: Send Message with Attachment
  server.tool(
    "send_message_with_attachment",
    [
      "Send a message with a file attachment. This is a two-step process:",
      "1. First upload the file using upload_asset or upload_asset_base64 to get an uploadID",
      "2. Then call this tool with the uploadID to send the message",
      "",
      "The official send_message tool only supports text. Use this tool when you need to send images, documents, or other files.",
      "Requires Beeper Desktop v4.2.499+.",
    ].join("\n"),
    {
      chatID: z.string().describe("The chat ID to send the message to"),
      uploadID: z.string().describe("The uploadID from a previous upload_asset or upload_asset_base64 call"),
      text: z.string().optional().describe("Optional text caption to include with the attachment"),
      replyToMessageID: z.string().optional()
        .describe("Optional message ID to reply to"),
    },
    async ({ chatID, uploadID, text, replyToMessageID }) => {
      try {
        const body: Record<string, unknown> = { uploadID };
        if (text) body.text = text;
        if (replyToMessageID) body.replyToMessageID = replyToMessageID;

        const result = await client.post(
          `/v1/chats/${encodeURIComponent(chatID)}/messages`,
          body,
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error sending message with attachment", error);
      }
    },
  );
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/messages.ts
git commit -m "feat: add message tools (edit + send with attachment)"
```

---

## Task 8: Create Assets Tools

**Files:**
- Create: `mcp/src/tools/assets.ts`

**Step 1: Write assets tools**

Create `mcp/src/tools/assets.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerAssetsTools(server: McpServer, client: BeeperClient) {
  // Tool: Download Asset
  server.tool(
    "download_asset",
    "Download message attachments, images, avatars, or other media assets. Returns a local file URL that can be used to access the content.",
    {
      url: z.string().describe("The URL of the asset to download (found in message attachments). Accepts both mxc:// URIs and https:// URLs."),
      mxcURI: z.string().optional().describe("DEPRECATED: Use 'url' instead. Legacy Matrix mxc:// URI parameter kept for backward compatibility."),
      filename: z.string().optional().describe("Optional filename hint for the downloaded asset"),
    },
    async ({ url, mxcURI, filename }) => {
      try {
        const assetUrl = url || mxcURI;
        if (!assetUrl) {
          return errorResult("Error downloading asset", new Error("Either 'url' or 'mxcURI' parameter is required"));
        }

        const body: Record<string, unknown> = { url: assetUrl };
        if (filename) body.filename = filename;

        const result = await client.post("/v1/assets/download", body);
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error downloading asset", error);
      }
    },
  );

  // Tool: Upload Asset (URL-based)
  server.tool(
    "upload_asset",
    [
      "Upload a file to Beeper for sending as a message attachment.",
      "Pass a publicly accessible URL and Beeper will fetch and store the file.",
      "Returns an uploadID that can be used with send_message_with_attachment.",
      "Requires Beeper Desktop v4.2.499+.",
    ].join("\n"),
    {
      url: z.string().describe("Public URL of the file to upload"),
      filename: z.string().optional().describe("Filename for the uploaded asset"),
      mimeType: z.string().optional().describe("MIME type of the file (e.g., 'image/png', 'application/pdf')"),
    },
    async ({ url, filename, mimeType }) => {
      try {
        const body: Record<string, unknown> = { url };
        if (filename) body.filename = filename;
        if (mimeType) body.mimeType = mimeType;

        const result = await client.post("/v1/assets/upload", body);
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error uploading asset", error);
      }
    },
  );

  // Tool: Upload Asset Base64
  server.tool(
    "upload_asset_base64",
    [
      "Upload a file as base64-encoded data for sending as a message attachment.",
      "Useful when you have file content in memory rather than a URL.",
      "Returns an uploadID that can be used with send_message_with_attachment.",
      "Requires Beeper Desktop v4.2.499+.",
    ].join("\n"),
    {
      data: z.string().describe("Base64-encoded file content"),
      filename: z.string().describe("Filename for the uploaded asset (e.g., 'photo.png')"),
      mimeType: z.string().describe("MIME type of the file (e.g., 'image/png', 'application/pdf')"),
    },
    async ({ data, filename, mimeType }) => {
      try {
        const result = await client.post("/v1/assets/upload/base64", {
          data,
          filename,
          mimeType,
        });
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error uploading asset (base64)", error);
      }
    },
  );

  // Tool: Serve Asset (streaming URL)
  server.tool(
    "serve_asset",
    [
      "Get a streaming URL for a media asset (useful for large video/audio files).",
      "Returns a local URL that streams the content on demand.",
      "Requires Beeper Desktop v4.2.509+.",
    ].join("\n"),
    {
      url: z.string().describe("The asset URL to serve (from message attachments)"),
    },
    async ({ url }) => {
      try {
        const result = await client.get("/v1/assets/serve", { url });
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error serving asset", error);
      }
    },
  );
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/assets.ts
git commit -m "feat: add asset tools (download, upload, upload_base64, serve)"
```

---

## Task 9: Create Reactions Tools

**Files:**
- Create: `mcp/src/tools/reactions.ts`

**Step 1: Write reactions tools**

Create `mcp/src/tools/reactions.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerReactionsTools(server: McpServer, client: BeeperClient) {
  // Tool: Add Reaction
  server.tool(
    "add_reaction",
    "Add an emoji reaction to a message. Note: This feature may require a newer Beeper Desktop version.",
    {
      chatID: z.string().describe("The chat ID containing the message"),
      messageID: z.string().describe("The ID of the message to react to"),
      emoji: z.string().describe("The emoji to react with (e.g., '\ud83d\udc4d', '\u2764\ufe0f', '\ud83d\ude02')"),
    },
    async ({ chatID, messageID, emoji }) => {
      try {
        const result = await client.post(
          `/v1/chats/${encodeURIComponent(chatID)}/messages/${encodeURIComponent(messageID)}/reactions`,
          { emoji },
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error adding reaction", error);
      }
    },
  );

  // Tool: Remove Reaction
  server.tool(
    "remove_reaction",
    "Remove an emoji reaction from a message. Note: This feature may require a newer Beeper Desktop version.",
    {
      chatID: z.string().describe("The chat ID containing the message"),
      messageID: z.string().describe("The ID of the message to remove reaction from"),
      emoji: z.string().describe("The emoji reaction to remove"),
    },
    async ({ chatID, messageID, emoji }) => {
      try {
        const result = await client.del(
          `/v1/chats/${encodeURIComponent(chatID)}/messages/${encodeURIComponent(messageID)}/reactions?emoji=${encodeURIComponent(emoji)}`,
        );
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error removing reaction", error);
      }
    },
  );
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/reactions.ts
git commit -m "feat: add reaction tools (add + remove emoji reactions)"
```

---

## Task 10: Create System Tools

**Files:**
- Create: `mcp/src/tools/system.ts`

**Step 1: Write system tools**

Create `mcp/src/tools/system.ts`:
```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { BeeperClient } from "../client.js";
import { jsonResult, errorResult } from "../types.js";

export function registerSystemTools(server: McpServer, client: BeeperClient) {
  // Tool: Get Server Info
  server.tool(
    "get_server_info",
    "Get Beeper Desktop server version and capabilities. Useful for checking if specific features (message editing, asset upload) are available.",
    {},
    async () => {
      try {
        const result = await client.get("/v1/info");
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error getting server info", error);
      }
    },
  );

  // Tool: Introspect Token
  server.tool(
    "introspect_token",
    "Validate the current authentication token and get metadata (scopes, expiry, user info). Useful for debugging auth issues.",
    {},
    async () => {
      try {
        const result = await client.post("/oauth/introspect");
        return jsonResult(result);
      } catch (error) {
        return errorResult("Error introspecting token", error);
      }
    },
  );
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/tools/system.ts
git commit -m "feat: add system tools (server info + token introspection)"
```

---

## Task 11: Rewrite Entry Point (index.ts)

**Files:**
- Modify: `mcp/src/index.ts`

**Step 1: Rewrite index.ts with modular tool registration**

Replace entire `mcp/src/index.ts`:
```typescript
#!/usr/bin/env node
/**
 * Beeper Extended MCP Server v2.0
 *
 * Full-featured extension for the Beeper Desktop API.
 * Provides 14 tools covering: contacts, chats, messages, assets, reactions, system.
 *
 * Complements the official Beeper MCP (12 tools) with capabilities it doesn't expose:
 * - Message editing
 * - File uploads (URL + base64)
 * - Asset streaming
 * - Emoji reactions
 * - Chat/contact listing
 * - Server info & token introspection
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolveBaseUrl, resolveToken } from "./auth.js";
import { BeeperClient } from "./client.js";
import { registerContactsTools } from "./tools/contacts.js";
import { registerChatsTools } from "./tools/chats.js";
import { registerMessagesTools } from "./tools/messages.js";
import { registerAssetsTools } from "./tools/assets.js";
import { registerReactionsTools } from "./tools/reactions.js";
import { registerSystemTools } from "./tools/system.js";

async function main() {
  // Resolve auth
  const baseUrl = resolveBaseUrl();
  const token = await resolveToken();

  if (process.env.BEEPER_DEBUG === "1") {
    console.error(`[beeper-extended] Base URL: ${baseUrl}`);
    console.error(`[beeper-extended] Auth: ${token ? "token present" : "no token (unauthenticated)"}`);
  }

  // Create shared API client
  const client = new BeeperClient(baseUrl, token);

  // Initialize MCP server
  const server = new McpServer({
    name: "beeper-extended",
    version: "2.0.0",
  });

  // Register all tool modules
  registerContactsTools(server, client);
  registerChatsTools(server, client);
  registerMessagesTools(server, client);
  registerAssetsTools(server, client);
  registerReactionsTools(server, client);
  registerSystemTools(server, client);

  // Start server
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Beeper Extended MCP v2.0 running (14 tools)");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/src/index.ts
git commit -m "feat: rewrite index.ts with modular tool registration (v2.0)"
```

---

## Task 12: Update Plugin Manifest

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Step 1: Update version and description**

Replace `.claude-plugin/plugin.json`:
```json
{
  "name": "beeper-extended",
  "version": "2.0.0",
  "description": "Full-featured Beeper API extension: message editing, file uploads, reactions, asset management, and more (14 tools)",
  "author": {
    "name": "Rob",
    "email": "robertogogoni@outlook.com"
  },
  "homepage": "https://developers.beeper.com/desktop-api",
  "license": "MIT",
  "keywords": ["beeper", "chat", "messages", "contacts", "api", "attachments", "reactions"],
  "mcpServers": {
    "beeper-extended": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/dist/index.js"]
    }
  }
}
```

**Step 2: Commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add .claude-plugin/plugin.json
git commit -m "chore: update plugin manifest to v2.0.0"
```

---

## Task 13: Build and Verify

**Files:**
- Output: `mcp/dist/index.js`

**Step 1: Run all tests**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npx vitest run
```
Expected: All tests pass (auth: 3, client: 7, types: 5 = 15 total)

**Step 2: Build the bundle**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
npm run build
```
Expected: `dist/index.js` created without errors

**Step 3: Verify bundle loads**

Run:
```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp
node -e "import('./dist/index.js').then(() => console.log('OK')).catch(e => { console.error(e.message); process.exit(0); })"
```
Expected: Either "OK" (if Beeper is running) or a connection error (expected — Beeper not running is fine). Should NOT show import/syntax errors.

**Step 4: Check bundle size**

Run:
```bash
ls -lh /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0/mcp/dist/index.js
```
Expected: Reasonable size (should be ~700-900KB due to MCP SDK bundling)

**Step 5: Commit build output**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add mcp/dist/index.js
git commit -m "build: compile v2.0.0 bundle"
```

---

## Task 14: Integration Verification

> Note: This task requires Beeper Desktop to be running.

**Step 1: Check if Beeper Desktop is running**

Run:
```bash
curl -s http://localhost:23373/v1/info 2>/dev/null && echo "RUNNING" || echo "NOT RUNNING"
```

If NOT RUNNING: Skip to Step 5 (document limitation).

**Step 2: Test server info endpoint**

Run:
```bash
curl -s http://localhost:23373/v1/info | python3 -m json.tool
```
Expected: JSON with version info

**Step 3: Test accounts endpoint**

Run:
```bash
curl -s http://localhost:23373/v1/accounts | python3 -m json.tool
```
Expected: JSON array of connected accounts

**Step 4: Test chat listing**

Run:
```bash
curl -s "http://localhost:23373/v1/chats?limit=3" | python3 -m json.tool
```
Expected: JSON with up to 3 chats

**Step 5: Document results**

If Beeper was running, note which endpoints returned valid data.
If not running, note that integration testing is pending.

**Step 6: Final commit**

```bash
cd /home/rob/.claude/plugins/cache/beeper-extended-dev/beeper-extended/1.0.0
git add -A
git commit -m "v2.0.0: beeper-extended with 14 tools covering full Desktop API"
```

---

## Summary: File Inventory

| File | Action | Purpose |
|------|--------|---------|
| `mcp/package.json` | Modify | Add vitest, bump to v2.0.0 |
| `mcp/vitest.config.ts` | Create | Test configuration |
| `mcp/src/auth.ts` | Create | Auth chain (env → file → null) |
| `mcp/src/auth.test.ts` | Create | Auth unit tests |
| `mcp/src/client.ts` | Create | Shared API client |
| `mcp/src/client.test.ts` | Create | Client unit tests |
| `mcp/src/types.ts` | Create | Zod schemas + result helpers |
| `mcp/src/types.test.ts` | Create | Schema validation tests |
| `mcp/src/tools/contacts.ts` | Create | search_contacts, list_contacts |
| `mcp/src/tools/chats.ts` | Create | create_chat, list_chats |
| `mcp/src/tools/messages.ts` | Create | edit_message, send_message_with_attachment |
| `mcp/src/tools/assets.ts` | Create | download_asset, upload_asset, upload_asset_base64, serve_asset |
| `mcp/src/tools/reactions.ts` | Create | add_reaction, remove_reaction |
| `mcp/src/tools/system.ts` | Create | get_server_info, introspect_token |
| `mcp/src/index.ts` | Rewrite | Modular entry point |
| `.claude-plugin/plugin.json` | Modify | Version bump + description |
| `mcp/dist/index.js` | Rebuild | Compiled bundle |

**Total: 14 tasks, ~45 steps, 17 files (10 new, 3 modified, 1 rebuilt, 3 test files)**
