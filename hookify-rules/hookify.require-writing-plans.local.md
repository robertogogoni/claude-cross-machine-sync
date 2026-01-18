---
name: require-writing-plans
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: (implement|add\s+(a\s+)?(new\s+)?feature|build|create|refactor|migrate|upgrade|redesign|architect|set\s*up|integrate|add\s+support\s+for)
---

📋 **Multi-Step Implementation Detected**

Before writing code, invoke the **writing-plans** skill:

```
/superpowers:writing-plans
```

**Why this matters:**
- Maps out all affected files and dependencies upfront
- Identifies edge cases before they become bugs
- Prevents rework cycles from discovering issues mid-implementation

**Your history shows** implementations without plans lead to iterative fixes and context exhaustion.

If this is truly a single-file, trivial change, you may proceed — but consider: is it really that simple?
