# Vercel GitHub Profile Widgets

> Created: 2026-01-21
> Purpose: Self-hosted GitHub profile widgets with private repo access

---

## Overview

GitHub profile README widgets (stats, activity graphs) use public APIs by default. Self-hosting on Vercel with your own PAT enables:
- Private repository statistics
- Higher API rate limits
- Custom domains
- No shared token throttling

---

## Deployed Widgets

| Widget | Vercel URL | Env Var | Works |
|--------|-----------|---------|-------|
| **github-readme-stats** | `github-readme-stats-zeta-blush-29.vercel.app` | `PAT_1` | ✅ |
| **github-readme-activity-graph** | `github-readme-activity-graph-sage.vercel.app` | `TOKEN` | ✅ |
| **github-readme-streak-stats** | N/A - PHP project | - | ❌ |

### Why Streak Stats Doesn't Work on Vercel

`github-readme-streak-stats` is a **PHP project** designed for Heroku:
```json
"buildpacks": [
  {"url": "heroku/php"}
]
```

Vercel only supports Node.js/Python/Go/Ruby serverless functions, not PHP.

**Solution**: Use the public instance `streak-stats.demolab.com` - streak data is public anyway (counts contribution days, no private data).

---

## Deployment Steps

### 1. Clone and Deploy

```bash
cd /tmp
git clone --depth 1 https://github.com/anuraghazra/github-readme-stats.git
cd github-readme-stats
vercel --yes
```

### 2. Add PAT Environment Variable

```bash
# github-readme-stats uses PAT_1
printf "ghp_YOUR_TOKEN" | vercel env add PAT_1 production

# github-readme-activity-graph uses TOKEN
printf "ghp_YOUR_TOKEN" | vercel env add TOKEN production
```

### 3. Redeploy with Environment Variable

```bash
vercel --prod --yes
```

### 4. Update README

```markdown
![Stats](https://YOUR-INSTANCE.vercel.app/api?username=USERNAME&count_private=true)
```

---

## GitHub PAT Requirements

For private repo stats, the PAT needs:
- `repo` scope (full repository access)
- `user` scope (read user profile data)

Create at: https://github.com/settings/tokens/new

---

## Vercel CLI Authentication (Wayland/Linux)

On Wayland/Linux, Vercel CLI may not auto-open browser. Use device code flow:

```bash
vercel login
# Shows: Visit https://vercel.com/oauth/device?user_code=XXXX-XXXX
# Open URL manually, authenticate, CLI receives credentials
```

---

## README Widget URLs

### Stats (Self-hosted)
```markdown
![GitHub Stats](https://github-readme-stats-zeta-blush-29.vercel.app/api?username=robertogogoni&show_icons=true&theme=tokyonight&hide_border=true&count_private=true)
```

### Top Languages (Self-hosted)
```markdown
![Top Languages](https://github-readme-stats-zeta-blush-29.vercel.app/api/top-langs/?username=robertogogoni&layout=compact&theme=tokyonight&hide_border=true)
```

### Activity Graph (Self-hosted)
```markdown
![Activity Graph](https://github-readme-activity-graph-sage.vercel.app/graph?username=robertogogoni&theme=tokyo-night&hide_border=true&area=true)
```

### Streak Stats (Public - PHP limitation)
```markdown
![GitHub Streak](https://streak-stats.demolab.com/?user=robertogogoni&theme=tokyonight&hide_border=true)
```

---

## Maintenance

### Update PAT
```bash
cd /tmp/github-readme-stats
vercel env rm PAT_1 production -y
printf "NEW_TOKEN" | vercel env add PAT_1 production
vercel --prod --yes
```

### Check Logs
```bash
vercel logs github-readme-stats-zeta-blush-29.vercel.app
```

### List Environment Variables
```bash
vercel env ls
```

---

## Troubleshooting

### "No existing credentials found"
```bash
vercel login
# Complete browser auth flow
vercel whoami  # Should show username
```

### Widget Shows Error/Placeholder
- Check PAT hasn't expired
- Verify PAT has correct scopes
- Check Vercel logs for API errors

### Rate Limiting
Self-hosted instances get 5,000 requests/hour per PAT vs shared instances which throttle heavily.

---

## Related Files

- Personal README: `~/repos/robertogogoni/README.md`
- Vercel projects: https://vercel.com/robertogogonis-projects

