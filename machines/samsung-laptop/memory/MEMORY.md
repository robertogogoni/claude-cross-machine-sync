# Memory Index

## User
- [Samsung laptop hardware profile](user_machine_samsung.md) — Full specs: i7-4510U Haswell, 8GB RAM, Intel HD 4400, 1TB HDD, drivers & tuning applied
- [User profile — robertogogoni](user_profile.md) — Agilist, Scrum Master, technical power user, GitHub identity, repos, domains

## Feedback
- [Protect customized system configs](feedback_protect_system_configs.md) — hypridle killed 3 ways (mask+pkill+config), monitors.conf, input.conf, Chrome policy
- [Never restart Hyprland mid-session](feedback_no_hyprland_restart.md) — SDDM autologin only fires at boot, use `systemctl reboot` instead
- [User prefers action over discussion](feedback_action_oriented.md) — Execute immediately on clear tasks, don't ask for obvious confirmations
- [No em/en dashes in public text](feedback_no_dashes.md) — Use commas/colons/parentheses instead of dashes in prose and public content
- [Always annotate sync repo with versioning](feedback_changelog_sync_repo.md) — CHANGELOG.md entries required for every claude-cross-machine-sync update
- [Always use prebuilt electron binaries](feedback_electron_bin_only.md) — Never build electron from source; use -bin variants, IgnorePkg in pacman.conf
- [System updates must route through Claude Code](feedback_supervised_updates.md) — All upgrades intercepted via /system-update, shell wrappers, omarchy hook
- [Release workflow for aifuel](feedback_release_workflow.md) — Full test, changelog, tag, verify release binary after every version
- [npm cache corruption kills npx MCP servers](feedback_npm_cache_mcp.md) — Bulk MCP failures = check npm cache first, fix with rm -rf ~/.npm/_npx

## Project
- [AI usage monitoring overlay](project_ai_usage_overlay.md) — Permanent overlay fetcher with JSONL fallback, rate-limit backoff, survives package updates
- [System tuning applied 2026-03-28](project_system_tuning_2026_03_28.md) — zram VM tunables, 4GB disk swap, nvidia blacklist, mkinitcpio i915, 104GB cache cleaned
- [Sync daemon audit](project_sync_daemon_audit.md) — Omarchy daemon running on Samsung, platform daemon has hostname bug, cortex bridge active
- [Cortex Claude — user's own memory system](project_cortex_claude.md) — cortex-claude v3.0.1 with 219 memories, warp-sqlite adapter, NOT michaelv2's fork
- [Chrome Canary configuration](project_chrome_canary.md) — Performance-tuned flags, Claude extension with native messaging, 46 extensions audited
- [Claude Desktop setup](project_claude_desktop.md) — AUR package, 14 MCP servers all healthy, Wayland config, auto-updater
- [Claude custom instructions](project_custom_instructions.md) — Account-wide personal preferences for Desktop/web/mobile, needs manual paste
- [MCP server inventory](project_mcp_servers.md) — 13 CLI + 14 Desktop MCP servers, npm cache fix, registry locations
- [Display scaling — DPI-based crisp rendering](project_display_scaling.md) — 1366x768 scaling fix: integer scales + DPI override, fractional blur eliminated
- [Crash fix and TV 1080p upgrade](project_crash_fix_2026_04_04.md) — Aquamarine rebuilt, hypridle killed, TV 1080p pending reboot with AQ_NO_ATOMIC
- [System packages installed](project_system_packages.md) — GPU drivers, power management, media codecs, utilities installed 2026-03-17
- [update-beeper project](project_update_beeper.md) — Self-healing Beeper updater at beeper-community/update-beeper, v1.8.1 API timeout fix, release workflow
- [beeper-community GitHub org](project_beeper_community_org.md) — User owns the org, 5 repos, can push directly to all
- [aifuel public distribution](project_aifuel.md) — Public repo for AI usage waybar module, Go Charm installer, v1.2.1 released
- [claude-sync distribution plan](project_claude_sync_distribution.md) — Research-backed plan to distribute cross-machine-sync publicly, 9 unique value props, resume from here

- [Hyprland workspace system](project_hyprland_workspace_system.md) — Split-monitor, smart daemons, dock, 13 productivity features, all keybindings
- [hyprland-dual-display repo](project_hyprland_dual_display_repo.md) — Public repo: 4-layer setup, installer, EDID, TV jailbreak, live at GitHub

## Feedback (additions)
- [No Nerd Font icons in waybar at 768p](feedback_768p_icons.md) — Icons render as broken squares, use text labels with color CSS instead
- [Full autonomy on creative/technical projects](feedback_sous_chef_autonomy.md) — Act as sous-chef, iterate freely, only check in at milestones

## Project (display/TV)
- [TV 1080p rendering tuning](project_tv_1080p_tuning.md) — Per-output waybar working, all fixed via TV jailbreak + custom EDID
- [EDID override research for LG TV](project_edid_research.md) — Full dump, community comparison, custom EDID deployed, TV jailbroken

## Reference
- [GitHub repo map](reference_github_repos.md) — Key repos under robertogogoni and beeper-community with branches and badge info
- [MCP diagnostic log locations](reference_mcp_diagnostics.md) — Desktop logs, CLI config paths, npm debug logs, cortex logs
