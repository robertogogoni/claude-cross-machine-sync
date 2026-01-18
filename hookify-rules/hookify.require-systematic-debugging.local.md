---
name: require-systematic-debugging
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: (error|bug|fix|broken|crash|fail|exception|stack\s*trace|traceback|undefined|null\s*pointer|segfault|not\s*working|doesn.t\s*work|won.t\s*work|stopped\s*working)
---

🔍 **Debugging Scenario Detected**

Before diving into fixes, invoke the **systematic-debugging** skill:

```
/superpowers:systematic-debugging
```

**Why this matters:**
- Prevents symptom-chasing and iterative fix attempts
- Ensures root cause analysis before code changes
- Follows: reproduce → isolate → hypothesize → test → validate

**Don't skip this step** — your conversation history shows debugging without this skill leads to multiple fix iterations.
