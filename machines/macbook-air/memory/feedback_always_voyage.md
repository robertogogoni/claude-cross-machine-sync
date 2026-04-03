---
name: Always use Voyage embeddings for beeper-kb
description: When harvesting or ingesting into beeper-kb, always use the Voyage API key for vector embeddings — never FTS-only mode
type: feedback
---

Always use the Voyage API key when running beeper-kb harvests or ingesting documents. Never run in FTS-only mode.

**Why:** The user wants full semantic search capability on every document, not just keyword matching. Zero-vector stubs degrade search quality.

**How to apply:** Set `VOYAGE_API_KEY` env var when running harvest scripts. The key is stored in `~/.claude.json` under the beeper-kb MCP server config. The MCP server itself already has it, but standalone scripts need it passed explicitly.
