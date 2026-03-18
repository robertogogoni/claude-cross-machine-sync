# Custom Instructions Optimization for Claude

**Created**: 2026-03-18
**Sources**: Anthropic docs, community guides, empirical research

## Compliance rates by instruction type
- Specific rules ("use pnpm, not npm"): ~89% compliance
- Vague instructions ("write clean code"): ~35% compliance
- Instructions over 50 lines: compliance drops sharply

## Three-layer customization in Claude
1. **Personal Preferences** (Settings -> Profile): account-wide, all conversations, all machines
2. **Project Instructions**: per-project context in Claude Projects
3. **Styles**: communication format, switchable mid-conversation

## Best practices
- Lead with WHO you are (background changes Claude's assumptions and depth)
- "How I think" section is more impactful than "what I want" (changes solution structure)
- Anti-patterns (what NOT to do) are more effective than positive instructions
- Keep under 45 lines for optimal compliance
- Use markdown headers for structure (improves parsing)
- Iterate: start simple, refine based on real usage over a week
- Include behavioral rules, not just preferences

## Structure that works
```
Identity (1-2 lines: role, location, key context)
## What I do (3-5 bullets: domains, projects)
## How I think (3-4 bullets: mental model, approach)
## How I work (4-5 bullets: behavioral rules)
## Technical profile (3-4 bullets: languages, tools, OS)
## Never do (1-3 bullets: specific anti-patterns)
## Extended context (1 line: MCP reference or file reference)
```

## Cross-machine considerations
- Personal Preferences are stored server-side on Anthropic account
- They apply to Desktop, web, and mobile on ALL machines
- References to local tools/MCPs should be conditional ("if available")
- Keep machine-specific details out; use local memory systems for those

## What NOT to put in custom instructions
- Machine specs (belongs in memory/machine profile)
- Project details that change (belongs in project instructions)
- Code style rules that vary by project (belongs in CLAUDE.md)
- Temporary context ("I'm working on X this week")
