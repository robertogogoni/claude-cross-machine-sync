---
name: require-tdd
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: (add\s+(a\s+)?(new\s+)?function|implement\s+(a\s+)?(new\s+)?(method|class|module|api|endpoint)|write\s+(a\s+)?(new\s+)?(function|method|class)|create\s+(a\s+)?(new\s+)?(component|service|handler))
---

🧪 **Feature Implementation Detected**

Consider invoking **test-driven-development**:

```
/superpowers:test-driven-development
```

**The TDD cycle:**
1. Write a failing test that defines expected behavior
2. Write minimal code to pass the test
3. Refactor while keeping tests green

**Why this matters:**
- Tests define the contract before implementation
- Catches edge cases upfront, not in production
- Your history shows tests run *after* code — TDD inverts this

**Skip if:** You're doing pure exploration, prototyping, or the function is genuinely trivial (< 5 lines).
