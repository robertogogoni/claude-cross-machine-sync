# GitHub Profile Widgets Troubleshooting

**Date**: 2026-02-02
**Problem**: "Something went wrong" errors on GitHub profile widgets
**Root Causes**: Private repo in widget + Snake workflow permission failure

## Issues Diagnosed

### 1. Repo Pin Widget Showing "User Repository Not found"

**Symptom**: Widget displays "Something went wrong! User Repository Not found"

**Root Cause**: The `claude-cross-machine-sync` repository is PRIVATE. GitHub readme-stats widgets cannot display private repositories to public visitors, even with a PAT configured on Vercel.

**Why PAT Doesn't Help**: The PAT helps YOUR Vercel deployment access YOUR private data, but when a visitor views your profile, the widget makes a fresh API call that can't authenticate as you.

**Fix**: Only use PUBLIC repositories in profile widget cards.

```html
<!-- WRONG: Private repo -->
<img src="https://github-readme-stats.vercel.app/api/pin/?username=you&repo=private-repo"/>

<!-- RIGHT: Public repo -->
<img src="https://github-readme-stats.vercel.app/api/pin/?username=you&repo=public-repo"/>
```

### 2. Snake Animation Not Generating

**Symptom**: Snake animation shows broken image, workflow fails with 403 error

**Root Cause**: GitHub Actions workflow lacked `contents: write` permission

**Error Log**:
```
remote: Permission to user/repo.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/user/repo.git/': The requested URL returned error: 403
```

**Fix**: Add permissions block to workflow:

```yaml
name: Generate Snake

on:
  schedule:
    - cron: "0 0 * * *"
  workflow_dispatch:

permissions:
  contents: write  # <-- This was missing!

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: Platane/snk@v3
        # ... rest of workflow
```

## Widget Services & Their Quirks

| Service | Theme Parameter | Notes |
|---------|-----------------|-------|
| github-readme-stats | `tokyonight` | No hyphen |
| github-readme-activity-graph | `tokyo-night` | With hyphen |
| github-readme-streak-stats | `tokyonight` | Uses `user=` not `username=` |
| github-profile-summary-cards | `tokyonight` | No hyphen |
| github-trophies | `tokyonight` | No hyphen |

## Cache Busting

Vercel widgets cache GitHub API responses for 4-6 hours. To force refresh:

```html
<!-- Add cache buster parameter -->
<img src="https://your-stats.vercel.app/api?username=you&v=202602020830"/>
```

Format: `&v=YYYYMMDDHHMM`

## Debugging Widget URLs

Quick test all widgets:
```bash
for url in \
  "https://github-readme-stats.vercel.app/api?username=USER" \
  "https://github-readme-stats.vercel.app/api/top-langs/?username=USER" \
  "https://github-readme-stats.vercel.app/api/pin/?username=USER&repo=REPO"; do
  echo "Testing: $url"
  curl -s "$url" | grep -o 'Something went wrong\|error' | head -1 || echo "OK"
done
```

Check SVG content for errors:
```bash
curl -s "https://widget-url" | head -20
# Look for error messages in the SVG
```

## Workflow Permissions Reference

| Permission | Use Case |
|------------|----------|
| `contents: read` | Default, read-only access |
| `contents: write` | Push commits, create branches |
| `pages: write` | Deploy to GitHub Pages |
| `pull-requests: write` | Create/update PRs |
| `issues: write` | Create/update issues |

Example with multiple permissions:
```yaml
permissions:
  contents: write
  pages: write
  id-token: write
```

## Files Modified in This Fix

| File | Change |
|------|--------|
| `.github/workflows/snake.yml` | Added `permissions: contents: write` |
| `README.md` | Replaced private repo widget with public `awesome-beeper` |

## Verification Commands

```bash
# Check if workflow succeeded
gh run list --repo USER/REPO --workflow=snake.yml --limit 3

# Check if output branch exists
gh api repos/USER/REPO/branches --jq '.[].name'

# Check repo visibility
gh repo view USER/REPO --json visibility,isPrivate

# Test widget URL
curl -s "WIDGET_URL" | grep -o 'error\|Something went wrong' || echo "Working"
```

## Related Resources

- [github-readme-stats docs](https://github.com/anuraghazra/github-readme-stats)
- [Platane/snk (snake animation)](https://github.com/Platane/snk)
- [GitHub Actions permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
