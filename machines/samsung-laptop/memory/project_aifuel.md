---
name: aifuel public distribution
description: Public repo for AI usage monitoring waybar module, Go Charm installer, derived from personal ai-usage scripts
type: project
---

aifuel (v1.0.0, released 2026-03-29) is the public distribution of the personal ai-usage monitoring system.

**Repo:** github.com/robertogogoni/aifuel (public, MIT)

**Why:** User wanted to share the ai-usage monitoring suite publicly. The personal system at ~/.config/ai-usage/ and ~/.local/libexec/ai-usage/ was adapted with generalized paths, runtime tool detection, and a Go Charm CLI installer.

**How to apply:** The personal ai-usage system still runs independently at ~/.config/ai-usage/. The aifuel repo at ~/aifuel/ is the public distribution. Changes to the personal system should be mirrored to aifuel when ready. The repo uses GoReleaser for cross-platform binary releases triggered by git tags.

**Key transformations from personal to public:**
- ai-usage → aifuel (all names, paths, variables)
- AI_USAGE_ → AIFUEL_ env vars
- Hardcoded tool paths → runtime detection (_find_ccusage, _find_hbd, _detect_chrome_profile)
- Overlay/forwarder pattern eliminated (no upstream package to survive)
- Go Charm CLI wizard (bubbletea/lipgloss/huh) for plug-and-play installation
- .gitignore must use /aifuel (anchored) not aifuel (matches cmd/aifuel/ directory)
