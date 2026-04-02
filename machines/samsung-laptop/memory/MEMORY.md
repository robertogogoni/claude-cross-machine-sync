# Memory Index

## User
- [Samsung laptop hardware profile](user_machine_samsung.md) — Full specs: i7-4510U Haswell, 8GB RAM, Intel HD 4400, 1TB HDD, drivers & tuning applied
- [User profile — robertogogoni](user_profile.md) — Agilist, Scrum Master, technical power user, GitHub identity, repos, domains

## Feedback
- [Protect customized system configs](feedback_protect_system_configs.md) — hypridle.conf, monitors.conf, input.conf, Chrome policy protected from edits
- [User prefers action over discussion](feedback_action_oriented.md) — Execute immediately on clear tasks, don't ask for obvious confirmations
- [No em/en dashes in public text](feedback_no_dashes.md) — Use commas/colons/parentheses instead of dashes in prose and public content
- [Always annotate sync repo with versioning](feedback_changelog_sync_repo.md) — CHANGELOG.md entries required for every claude-cross-machine-sync update
- [Always use prebuilt electron binaries](feedback_electron_bin_only.md) — Never build electron from source; use -bin variants, IgnorePkg in pacman.conf
- [System updates must route through Claude Code](feedback_supervised_updates.md) — All upgrades intercepted via /system-update, shell wrappers, omarchy hook
- [Release workflow for aifuel](feedback_release_workflow.md) — Full test, changelog, tag, verify release binary after every version

## Project
- [AI usage monitoring overlay](project_ai_usage_overlay.md) — Permanent overlay fetcher with JSONL fallback, rate-limit backoff, survives package updates
- [System tuning applied 2026-03-28](project_system_tuning_2026_03_28.md) — zram VM tunables, 4GB disk swap, nvidia blacklist, mkinitcpio i915, 104GB cache cleaned
- [Sync daemon audit 2026-03-19](project_sync_daemon_audit.md) — Two daemons (omarchy + platform), neither running on Samsung, platform has hostname bug
- [Cortex Claude — user's own memory system](project_cortex_claude.md) — cortex-claude v3.0.0 installed as MCP server with 4 hooks, NOT related to michaelv2's fork
- [Chrome Canary configuration](project_chrome_canary.md) — Performance-tuned flags, Claude extension with native messaging, 46 extensions audited
- [Claude Desktop setup](project_claude_desktop.md) — AUR package with auto-updater, Wayland config, keyring unlock, memory-sync MCP
- [Claude custom instructions](project_custom_instructions.md) — Account-wide personal preferences for Desktop/web/mobile, needs manual paste
- [MCP server inventory](project_mcp_servers.md) — 13 CLI + 13 Desktop MCP servers, memory-sync bridge between them
- [Display scaling — DPI-based crisp rendering](project_display_scaling.md) — 1366x768 scaling fix: integer scales + DPI override, fractional blur eliminated
- [System packages installed](project_system_packages.md) — GPU drivers, power management, media codecs, utilities installed 2026-03-17
- [update-beeper project](project_update_beeper.md) — Self-healing Beeper updater at beeper-community/update-beeper, v1.8.1 API timeout fix, release workflow
- [beeper-community GitHub org](project_beeper_community_org.md) — User owns the org, 5 repos, can push directly to all
- [aifuel public distribution](project_aifuel.md) — Public repo for AI usage waybar module, Go Charm installer, v1.2.1 released
- [claude-sync distribution plan](project_claude_sync_distribution.md) — Research-backed plan to distribute cross-machine-sync publicly, 9 unique value props, resume from here

## Reference
- [GitHub repo map](reference_github_repos.md) — Key repos under robertogogoni and beeper-community with branches and badge info
