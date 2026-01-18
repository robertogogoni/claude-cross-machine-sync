---
name: require-subagent-development
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: (multiple\s+(files|components|modules)|across\s+(the\s+)?(codebase|project|repo)|full\s+(feature|system)|end.to.end|complete\s+(implementation|feature)|all\s+(the|of\s+the)|comprehensive|overhaul|entire)
---

🚀 **Large-Scope Work Detected**

Consider invoking **subagent-driven-development** or **dispatching-parallel-agents**:

```
/superpowers:subagent-driven-development
```
or
```
/superpowers:dispatching-parallel-agents
```

**Why this matters:**
- Prevents context exhaustion on large implementations
- Parallelizes independent work streams
- Your history shows "conversation continued from previous" — subagents prevent this

**When to use which:**
- `subagent-driven-development`: Sequential steps with review checkpoints
- `dispatching-parallel-agents`: 2+ truly independent tasks

If the work fits in a single focused session, proceed — but monitor context usage.
