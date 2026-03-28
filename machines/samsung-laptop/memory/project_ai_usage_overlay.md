---
name: AI usage monitoring overlay architecture
description: Claude fetcher uses permanent overlay in ~/.config/ai-usage/ that survives package updates, with JSONL fallback and rate-limit backoff
type: project
---

The ai-usage waybar module's Claude fetcher uses a permanent overlay architecture (fixed 2026-03-28):

**Architecture:**
- `~/.config/ai-usage/ai-usage-claude-overlay.sh` is the permanent custom fetcher (never overwritten by packages)
- `~/.local/libexec/ai-usage/ai-usage-claude.sh` is a thin forwarder (`exec overlay.sh`)
- `~/.config/ai-usage/apply-patches.sh` re-deploys the forwarder after every package update
- Other scripts (lib.sh, ai-usage.sh) still use unified diff patches from `~/.config/ai-usage/patches/`

**Key improvements over stock:**
1. JSONL-only fallback: returns session token data (messages, output tokens, cache stats) even when API is completely unavailable
2. Rate-limit backoff: `.claude-rate-limited` marker prevents API hammering for 5 minutes after 429
3. Resilient to all failure modes: always returns something useful to waybar

**Config:** `~/.config/ai-usage/config.json` has codex/gemini/antigravity providers disabled (no credentials). Only Claude is active.

**Why:** The stock fetcher had a fatal flaw: if API returned 429 AND no stale cache existed, the module showed "No data available" permanently. This happened 2026-03-28 and couldn't self-recover. The overlay ensures local JSONL data is always available as fallback.

**How to apply:** If the module shows "?" again, check `~/.cache/ai-usage/ai-usage.log` and verify the forwarder is in place with `head -3 ~/.local/libexec/ai-usage/ai-usage-claude.sh`.
