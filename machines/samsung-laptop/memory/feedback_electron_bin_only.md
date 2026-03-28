---
name: Always use prebuilt electron binaries
description: Never build electron/chromium from source on Samsung laptop; always install -bin variants from AUR
type: feedback
---

Always install `electron*-bin` (prebuilt) packages instead of `electron*` (source) from the AUR.

**Why:** The Samsung laptop (i7-4510U, 2C/4T, 8GB RAM, HDD) cannot build Chromium from source. The electron33 source build stalled the system on 2026-03-28: it tried to clone the ~40GB Chromium repo, exhausted zram swap (3.8GB/3.8GB), and caused system-wide memory pressure. Building would take 12+ hours even if memory weren't an issue. A stale electron25 build cache had also accumulated 101GB silently.

**How to apply:**
- When installing or updating any electron package via yay/paru, always use the `-bin` variant (e.g., `electron33-bin` not `electron33`)
- `pacman.conf` has `IgnorePkg = electron33 electron34 electron35` to block source variants
- If a new electron version (36+) appears, add it to the IgnorePkg list and install the `-bin` variant
- Periodically check `~/.cache/yay/` for bloated build caches from Chromium-based packages
