# Vercel & Cloud Service Integrations

Last updated: 2026-03-02

## Vercel Account

- **Team**: robertogogoni's projects
- **Team ID**: `team_eaZN30Nu5BQRA3BkqM5D6U60`
- **Email**: robertogogoni@outlook.com

## Vercel Projects (8 total)

### GitHub Profile Widgets (6 projects, all READY)

| Project | Vercel URL | PAT Env Var | Notes |
|---------|-----------|-------------|-------|
| `github-readme-stats` | `github-readme-stats-zeta-blush-29.vercel.app` | `PAT_1` | Main stats card |
| `github-readme-activity-graph` | `github-readme-activity-graph-sage.vercel.app` | `TOKEN` | Activity graph |
| `github-profile-summary-cards` | `github-profile-summary-cards-beige-alpha.vercel.app` | TBD | Summary cards |
| `github-readme-streak-stats` | `github-readme-streak-stats-chi-brown.vercel.app` | TBD | PHP project, limited Vercel compat |
| `github-trophies` | `github-trophies-sandy.vercel.app` | TBD | Duplicate? |
| `github-profile-trophy` | `github-profile-trophy-three-indol.vercel.app` | TBD | Duplicate? |

**Issue**: `github-trophies` and `github-profile-trophy` appear to be duplicates. Check which one the profile README uses and delete the other.

### Other Projects

| Project | Status | Notes |
|---------|--------|-------|
| `chatgptbot` | **ERROR** (production) | Probot GitHub App. Initial deploy failed. PR #1 from Vercel bot (analytics) is READY but not promoted. Probot needs persistent processes — serverless Vercel may not suit. |
| `memory` | **EMPTY** | Zero deployments, no domains, no framework. Ghost project — candidate for deletion. |

## Cloud MCP Servers — Authentication

### How Cloud MCP Auth Works
- Cloud MCP servers (managed by `claude.ai` or plugins) use browser-based OAuth
- Auth is triggered by Claude Code's **connection manager at session startup**
- There is NO `claude mcp authenticate` CLI command
- Tools from unauthenticated servers **don't appear in the tool registry** at all — ToolSearch can't find them
- **To authenticate**: exit session → restart Claude Code → it will open browser for OAuth
- Once authenticated, tokens persist across sessions (auto-refresh)

### Auth Status (2026-03-02)

| Server | URL | Status | Auth Type |
|--------|-----|--------|-----------|
| Gmail | `gmail.mcp.claude.com/mcp` | Needs auth | Google OAuth |
| Google Calendar | `gcal.mcp.claude.com/mcp` | Needs auth | Google OAuth (same consent) |
| Supabase | `mcp.supabase.com/mcp` | Needs auth | Supabase OAuth |
| Vercel | `mcp.vercel.com` | Connected | Already authed |
| Figma | `mcp.figma.com/mcp` | Connected | Already authed |
| Canva | `mcp.canva.com/mcp` | Connected | Already authed |
| Notion | `mcp.notion.com/mcp` | Connected | Already authed |
| HuggingFace | `huggingface.co/mcp` | Connected | Already authed |

### Connected MCP Servers (full list, 2026-03-02)

22 connected, 3 needs auth, 0 failed (after cleanup)

**Cloud**: Vercel, Figma, HuggingFace (x2), Canva, Notion
**Plugins**: episodic-memory, playwright, greptile, firebase, superpowers-chrome, context7, beeper-extended, cortex
**Local**: github, filesystem, memory, sequential-thinking, cortex (installed copy), beeper-kb

## Projects Using Supabase

| Repo | Usage | Status |
|------|-------|--------|
| `candle-craft-ux-vision` | `@supabase/supabase-js` client, instance at `hytdospixxjsncjrtzva.supabase.co` | Active — needs Supabase MCP auth to manage DB |

Other Supabase mentions (`cookbook`, `awesome-oss-alternatives`, `developer-roadmap`) are reference docs/forks, not active projects.

## Vercel Deployment Gotchas

- PHP projects (like `github-readme-streak-stats`) don't truly work on Vercel — Vercel is Node.js serverless only
- PAT needs `repo` + `user` scopes for private repo data in widgets
- Different widget projects use different env var names (`PAT_1` vs `TOKEN`)
- Vercel CLI device auth on Wayland: `vercel login` → copy URL manually (no auto-open)
- `live: false` on all projects = Vercel's collaboration "Live" feature (paid), NOT deployment status
