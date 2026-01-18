---
name: require-brainstorming
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: (design|create\s+(a|an|the)|build\s+(a|an|the)|make\s+(a|an|the)|develop|come\s+up\s+with|think\s+of|ideas?\s+for|how\s+(should|could|would)\s+(we|i)|what.s\s+the\s+best\s+way|suggest|propose|architect|plan\s+out|brainstorm|concept|prototype|draft|sketch\s+out|mock\s+up|new\s+(feature|design|approach|solution|system|tool|app|project))
---

💡 **Creative Work Detected**

Before implementation, invoke the **brainstorming** skill:

```
/superpowers:brainstorming
```

**Why this matters:**
- Explores user intent and requirements before coding
- Surfaces failure modes and edge cases upfront
- Considers multiple approaches before committing to one
- Prevents building the wrong thing efficiently

**The brainstorming process:**
1. Clarify what you're actually trying to achieve
2. Explore constraints and requirements
3. Generate multiple solution approaches
4. Evaluate trade-offs
5. Converge on a direction

**Skip if:** You have a crystal-clear spec with no ambiguity, or you're iterating on an existing design with explicit feedback.
