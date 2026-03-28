---
name: Always annotate claude-sync repo changes with versioning
description: When updating claude-cross-machine-sync repo, always add changelog entries and follow semantic versioning
type: feedback
---

When pushing changes to claude-cross-machine-sync, always add a CHANGELOG.md entry with proper annotations.

**Why:** User explicitly requested versioning and changelog annotations so there's a history of what we're doing across sessions. The repo already follows Keep a Changelog format with semantic versioning (11 releases, v1.0.0 current).

**How to apply:** Every commit to the repo must be accompanied by an `[Unreleased]` section update in CHANGELOG.md (or a new version bump). Tag changes with `[machine:hostname]`, `[universal]`, `[linux]`, `[windows]` per existing convention. When enough changes accumulate, bump the version number following semver.
