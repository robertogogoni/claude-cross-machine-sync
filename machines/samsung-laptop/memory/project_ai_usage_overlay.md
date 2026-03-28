---
name: AI usage monitoring overlay architecture
description: Claude fetcher uses permanent overlay with multi-source fetch, circuit breaker, cookie-based fallback, JSONL+ccusage local data
type: project
---

The ai-usage waybar module uses a robust multi-source overlay architecture (v2, 2026-03-28):

**Architecture (5-phase cascade):**
1. Cache check (fast path, TTL from config)
2. Circuit breaker check (skip API after 3 consecutive failures, 15min cooldown)
3. Cookie-based fetch via `claude-usage` (NihilDigit/waybar-ai-usage, installed via `uv tool`)
4. OAuth API with token rotation (per-token rate limits, refresh on 429)
5. JSONL + ccusage local data (always available, never fails)

**Files:**
- `~/.config/ai-usage/ai-usage-claude-overlay.sh` is the permanent fetcher (never overwritten)
- `~/.local/libexec/ai-usage/ai-usage-claude.sh` is a thin forwarder (`exec overlay.sh`)
- `~/.config/ai-usage/apply-patches.sh` re-deploys forwarder + patches after package updates
- `~/.config/ai-usage/patches/` has unified diffs for lib.sh and ai-usage.sh

**Resilience features:**
- Circuit breaker: 3 failures then 15min cooldown (prevents API hammering)
- Multi-instance lock: `.claude-updating` marker prevents concurrent fetches (multi-monitor)
- Jitter: 0-2s random delay before API calls (desync multi-instance)
- Stale cache enrichment: old API data + fresh JSONL token data
- Cost tracking always available via ccusage (local JSONL parsing)

**Known issue:** The `/api/oauth/usage` endpoint has a known Cloudflare rate-limit bug (anthropics/claude-code#31637). Rate limits are per-access-token (~5 requests). Cookie-based approach (via claude-usage) bypasses this but requires Chrome Canary cookie decryption which currently fails due to missing keyring integration.

**Display modes:**
- API available: `󰧑 ▰▰▰▱▱▱` (real utilization % progress bar)
- API offline: `󰧑 $19.40 486msg` (today's cost + session message count)
- Tooltip always shows real data: session stats + daily cost breakdown by model

**Dependencies:** `waybar-ai-usage` installed via `uv tool install git+https://github.com/NihilDigit/waybar-ai-usage.git` (provides claude-usage, codex-usage commands)

**How to apply:** If module shows "?", check `~/.cache/ai-usage/ai-usage.log` and `head -3 ~/.local/libexec/ai-usage/ai-usage-claude.sh` for the forwarder.
