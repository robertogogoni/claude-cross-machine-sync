---
name: update-beeper project and fix
description: User's self-healing Beeper updater at beeper-community/update-beeper — v1.8.1 fix for API timeout, repo structure, release workflow
type: project
---

## Repo & Ownership

- **Repo:** `beeper-community/update-beeper` (user owns the org, can push directly to master)
- **Fork:** `robertogogoni/update-beeper` also exists
- **Local script:** `~/.local/bin/update-beeper` (synced to repo version)
- **Companion scripts:** `~/.local/bin/beeper-version`, `~/.local/bin/beeper-health`
- **Beeper installed:** v4.2.630 (AppImage at `/opt/beeper/`, AUR package `beeper-v4-bin` tracked)

## v1.8.1 Fix (2026-03-17)

**Problem:** Version check curl followed the API redirect and started downloading the ~200MB AppImage to `/dev/null`, always timing out (exit 28).

**Fix:** 3-strategy progressive URL resolution:
1. HEAD request — reads Location header (~0.7s)
2. Range 0-0 — follows redirects, requests 1 byte (~1s)
3. Full GET — last resort with --max-filesize 1MB cap (~10s)

**Also fixed:** `basename()` for version extraction, `|| true` for set -e safety, case-insensitive header parsing.

**Why:** The Beeper API at `api.beeper.com/desktop/download/linux/x64/stable/...` returns a 302 to CDN. With `-L` curl follows and gets 200 + starts streaming the AppImage.

## Release Workflow

- Bump `SCRIPT_VERSION` in `update-beeper`
- Update `CHANGELOG.md` (Keep a Changelog format)
- Update `PKGBUILD` pkgver
- Regenerate `checksums.sha256`
- Update `.github/badges/beeper-version.json` with latest Beeper version
- Push to master, create tag `v*.*.*`, create GitHub release
- Sync to `~/.local/bin/update-beeper`

**How to apply:** When making changes to update-beeper, follow this checklist. The README example output also has hardcoded version numbers that need updating. Use `gh release create` for releases.
