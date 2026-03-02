# Beeper Extended v2.0 — Design Document

**Date**: 2026-02-15
**Author**: Rob + Claude
**Status**: Pending Approval
**Plugin Location**: `~/.claude/plugins/cache/beeper-extended-dev/beeper-extended/`

---

## 1. Problem Statement

The beeper-extended v1.0 plugin has 4 tools (`search_contacts`, `create_chat`, `download_asset`, `unified_search`) that complement the official Beeper MCP's 12 tools. However:

- **`unified_search` is redundant** with the official MCP `search` tool
- **`download_asset` uses stale parameter** (`mxcURI` instead of `url`)
- **`create_chat` lacks** the `mode: 'start'` parameter and async status handling
- **Auth is fragile** — hardcoded filesystem paths that break across machines
- **11+ API endpoints are uncovered**, including message editing, file uploads, reactions, and asset streaming

The Beeper Desktop API has shipped significant features since v4.1.294 (Oct 2023) — message editing (v4.2.499), asset upload (v4.2.499), and asset streaming (v4.2.509) — none of which are exposed through either MCP.

## 2. Approach

**Modular Rewrite with Shared Infrastructure** (Approach 2 of 3 evaluated).

Why not incremental patching (Approach 1): Going from 4 to 14 tools in a single file doesn't scale.
Why not SDK-based (Approach 3): The `@beeper/desktop-api` npm package returned 403 — likely private/internal.

The modular rewrite gives us:
- Per-domain tool files (messages, assets, chats, contacts)
- Shared API client with robust auth chain
- Typed Zod schemas for all API responses
- Shared error handling and pagination helpers

## 3. Architecture

### 3.1 File Structure

```
mcp/
├── src/
│   ├── index.ts              # Server init + tool registration
│   ├── client.ts             # Shared API client (auth, fetch, errors)
│   ├── auth.ts               # Auth chain (env → file → fallback)
│   ├── types.ts              # Shared Zod schemas & TypeScript types
│   ├── tools/
│   │   ├── contacts.ts       # search_contacts, list_contacts
│   │   ├── chats.ts          # create_chat, list_chats
│   │   ├── messages.ts       # edit_message, send_message_with_attachment
│   │   ├── assets.ts         # download_asset, upload_asset, upload_asset_base64, serve_asset
│   │   ├── reactions.ts      # add_reaction, remove_reaction
│   │   └── system.ts         # get_server_info, introspect_token
│   └── utils/
│       └── pagination.ts     # Cursor-based pagination helper
├── package.json
├── tsconfig.json
└── dist/                     # Built output (esbuild bundle)
```

### 3.2 Auth Chain (`auth.ts`)

Priority order (first match wins):

| Priority | Source | How |
|----------|--------|-----|
| 1 | `BEEPER_TOKEN` env var | Explicit, works everywhere |
| 2 | `BEEPER_BASE_URL` env var | Custom server URL (default: `http://localhost:23373`) |
| 3 | Claude plugin auth dir | `~/.config/Claude/Claude Extensions/.../tokens.json` |
| 4 | Manual token file | `~/.beeper-mcp-token` |
| 5 | No auth | Unauthenticated localhost requests |

### 3.3 API Client (`client.ts`)

Single `BeeperClient` class:

```typescript
class BeeperClient {
  get(endpoint: string, params?: Record<string, string>): Promise<T>
  post(endpoint: string, body?: unknown): Promise<T>
  put(endpoint: string, body?: unknown): Promise<T>
  delete(endpoint: string): Promise<T>
  postMultipart(endpoint: string, formData: FormData): Promise<T>
}
```

Features:
- Automatic auth token injection
- Structured error handling with actionable messages
- Debug logging via `BEEPER_DEBUG=1`
- Response validation against Zod schemas

### 3.4 Error Strategy

| Status | Message | Action |
|--------|---------|--------|
| 401 | Auth failed | "Set BEEPER_TOKEN env var or check token file" |
| 404 | Endpoint not found | "Check Beeper Desktop version (requires v4.2.499+)" |
| 409 | Conflict | "Chat already exists" + existing chat info |
| 429 | Rate limited | "Retry after {seconds}" |
| 500+ | Server error | "Is Beeper Desktop running?" |

All errors return `isError: true` with actionable messages.

## 4. Tool Inventory (14 tools)

### 4.1 Existing Tools (Fixed)

| # | Tool | Changes |
|---|------|---------|
| 1 | `search_contacts` | Add `accountID` validation, proper query encoding |
| 2 | `create_chat` | Add `mode: 'start'` parameter, handle async creation `status` |
| 3 | `download_asset` | Rename `mxcURI` → `url`, keep `mxcURI` as deprecated alias |

### 4.2 Removed Tools

| Tool | Reason |
|------|--------|
| `unified_search` | Redundant with official MCP `search` tool |

### 4.3 New Tools

| # | Tool | Method | Endpoint | Min Version |
|---|------|--------|----------|-------------|
| 4 | `list_contacts` | GET | `/v1/accounts/{id}/contacts/list` | Unreleased |
| 5 | `list_chats` | GET | `/v1/chats` | v4.1.294 |
| 6 | `edit_message` | PUT | `/v1/chats/{id}/messages/{id}` | v4.2.499 |
| 7 | `send_message_with_attachment` | POST | `/v1/chats/{id}/messages` | v4.2.499 |
| 8 | `add_reaction` | POST | `/v1/chats/{id}/messages/{id}/reactions` | Unreleased |
| 9 | `remove_reaction` | DELETE | `/v1/chats/{id}/messages/{id}/reactions` | Unreleased |
| 10 | `upload_asset` | POST | `/v1/assets/upload` | v4.2.499 |
| 11 | `upload_asset_base64` | POST | `/v1/assets/upload/base64` | v4.2.499 |
| 12 | `serve_asset` | GET | `/v1/assets/serve` | v4.2.509 |
| 13 | `get_server_info` | GET | `/v1/info` | Unreleased |
| 14 | `introspect_token` | POST | `/oauth/introspect` | Unreleased |

### 4.4 Tool Descriptions

**`list_contacts`** — Cursor-based contact listing with pagination. Unlike `search_contacts` which requires a query, this returns all contacts for an account.

**`list_chats`** — Basic chat pagination (limit, cursor) without search. Complements the official MCP's `search_chats` which requires a query string.

**`edit_message`** — Update message text via PUT. Takes chatID, messageID, and new text. Returns updated message.

**`send_message_with_attachment`** — Two-step workflow: first upload via `upload_asset` or `upload_asset_base64` to get an `uploadID`, then send message referencing that uploadID. The tool description guides this workflow. This fills the critical gap where the official MCP's `send_message` only supports text + replyToMessageID.

**`add_reaction` / `remove_reaction`** — Emoji reaction management. Takes chatID, messageID, and emoji string.

**`upload_asset`** — Accepts a file URL, sends as multipart form data. Returns `uploadID` for use with `send_message_with_attachment`.

**`upload_asset_base64`** — Accepts base64-encoded data + mimeType + filename. Returns `uploadID`. Useful for programmatic uploads without file system access.

**`serve_asset`** — Returns a streaming URL for large media (video, audio). Takes an asset URL and returns a local streaming endpoint.

**`get_server_info`** — Returns Beeper Desktop version and capabilities. Useful for checking feature availability before calling version-gated tools.

**`introspect_token`** — Validate the current auth token. Returns token metadata (scopes, expiry, user info).

## 5. Zod Schemas (`types.ts`)

Key schemas:

```typescript
ContactSchema     // id, name, avatarURL, accountID
ChatSchema        // id, title, type, participants, lastMessage
MessageSchema     // id, text, sender, timestamp, attachments, reactions
AssetSchema       // url, mimeType, size, filename, uploadID
ServerInfoSchema  // version, capabilities
PaginatedResponse<T>  // items, cursor, hasMore
```

## 6. Version Requirements

| Feature | Minimum Beeper Version |
|---------|----------------------|
| Basic chat/contacts | v4.1.294 |
| Message editing | v4.2.499 |
| Asset upload | v4.2.499 |
| Asset streaming | v4.2.509 |
| Reactions | Unreleased (graceful 404 → helpful message) |
| Server info | Unreleased (graceful 404 → helpful message) |

Tools targeting unreleased endpoints will catch 404 specifically and return: "This feature requires a newer Beeper Desktop version" rather than generic errors.

## 7. Build & Plugin Config

### Build system (unchanged)
```json
{
  "build": "mkdir -p dist && esbuild src/index.ts --bundle --platform=node --format=esm --outfile=dist/index.js --external:fsevents"
}
```

### Plugin manifest (updated)
```json
{
  "name": "beeper-extended",
  "version": "2.0.0",
  "description": "Full-featured Beeper API extension: message editing, file uploads, reactions, asset management, and more"
}
```

### Dependencies (unchanged)
- `@modelcontextprotocol/sdk` ^1.0.0
- `zod` ^3.22.0

No new runtime dependencies needed. Native `fetch()` and `FormData` (Node 18+) handle all HTTP needs.

## 8. Explicitly NOT Included

| Feature | Reason |
|---------|--------|
| WebSocket events (`GET /v1/ws`) | MCP has no streaming support; too complex for tool-based interaction |
| `unified_search` | Redundant with official MCP `search` tool |
| Any official MCP duplicates | We complement, not compete |
| Token refresh/OAuth flow | Out of scope — Beeper Desktop handles auth |

## 9. Cross-Machine Considerations

- Auth chain with `BEEPER_TOKEN` env var solves the hardcoded-path problem
- Plugin deployed via Claude Code plugin system (same on all machines)
- No machine-specific config needed
- `BEEPER_BASE_URL` env var supports non-default ports

## 10. Implementation Phases

### Phase 1: Foundation (client, auth, types, error handling)
- `auth.ts`, `client.ts`, `types.ts`, `utils/pagination.ts`
- Updated `index.ts` with modular tool registration

### Phase 2: Fix & Migrate Existing Tools
- Fix `search_contacts`, `create_chat`, `download_asset`
- Remove `unified_search`

### Phase 3: New Chat & Message Tools
- `list_chats`, `edit_message`, `send_message_with_attachment`

### Phase 4: Asset Management
- `upload_asset`, `upload_asset_base64`, `serve_asset`

### Phase 5: Reactions & System
- `add_reaction`, `remove_reaction`, `get_server_info`, `introspect_token`

### Phase 6: Testing & Documentation
- Integration tests against running Beeper Desktop
- Updated plugin description and tool help text
- Build and verify bundle

## 11. Gap Analysis Summary

### Official Beeper MCP (12 tools)
`focus_app`, `search`, `get_accounts`, `get_chat`, `archive_chat`, `search_chats`, `set_chat_reminder`, `clear_chat_reminder`, `list_messages`, `search_messages`, `send_message`, `search_docs`

### beeper-extended v2.0 (14 tools)
`search_contacts`, `list_contacts`, `create_chat`, `list_chats`, `edit_message`, `send_message_with_attachment`, `add_reaction`, `remove_reaction`, `upload_asset`, `upload_asset_base64`, `download_asset`, `serve_asset`, `get_server_info`, `introspect_token`

### Combined Coverage: 26 tools covering the full Beeper Desktop API

---

*Design document for brainstorming phase. Implementation plan to follow after approval.*
