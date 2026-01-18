# Skill Enforcement Hooks

## Overview

Automatic hooks that remind Claude to invoke appropriate superpowers skills based on the type of work being requested. Created 2026-01-18 after analyzing conversation history to identify patterns where skills were underutilized.

## Problem Statement

Analysis of past conversations revealed systematic skill underutilization:
- Debugging done exploratorily instead of methodically → multiple fix iterations
- Implementations started without planning → rework cycles, edge cases found late
- Large projects hit context limits → conversation restarts, lost context
- Tests written after implementation → issues caught late
- Creative work jumped straight to code → built wrong thing efficiently

## Solution: Prompt-Event Hooks

These hooks use the `hookify` plugin to intercept prompts matching certain patterns and inject skill reminders *before* Claude starts working.

## Active Hooks

### 1. `require-systematic-debugging`
**Triggers on:** error, bug, fix, broken, crash, fail, exception, stack trace, not working

**Enforces:** `/superpowers:systematic-debugging`

**Why:** Prevents symptom-chasing. Follows: reproduce → isolate → hypothesize → test → validate

---

### 2. `require-writing-plans`
**Triggers on:** implement, add feature, build, create, refactor, migrate, upgrade

**Enforces:** `/superpowers:writing-plans`

**Why:** Maps affected files upfront, identifies edge cases before they become bugs

---

### 3. `require-subagent-development`
**Triggers on:** multiple files/components, across codebase, comprehensive, overhaul, entire

**Enforces:** `/superpowers:subagent-driven-development` or `/superpowers:dispatching-parallel-agents`

**Why:** Prevents context exhaustion on large implementations by parallelizing work

---

### 4. `require-tdd`
**Triggers on:** add function, implement method/class/module/api, create component/service

**Enforces:** `/superpowers:test-driven-development`

**Why:** Tests define contract before implementation, catches edge cases upfront

---

### 5. `require-brainstorming`
**Triggers on:** design, create a, build a, ideas for, what's the best way, new feature/tool

**Enforces:** `/superpowers:brainstorming`

**Why:** Explores intent and requirements before coding, considers multiple approaches

## Installation

Copy hook files to `~/.claude/`:

```bash
cp hookify-rules/hookify.*.local.md ~/.claude/
```

Rules are active immediately - no restart needed.

## Customization

### Disable a Hook
Edit the file and set `enabled: false` in frontmatter.

### Adjust Patterns
Modify the `pattern:` regex to be more/less inclusive.

### Change from Warn to Block
Add `action: block` to frontmatter to prevent execution instead of just warning.

## File Locations

- **Source (synced):** `~/claude-cross-machine-sync/hookify-rules/`
- **Active location:** `~/.claude/hookify.*.local.md`

## Pattern Reference

| Work Type | Pattern Keywords | Skill |
|-----------|-----------------|-------|
| Debugging | error, bug, fix, crash | systematic-debugging |
| Implementation | implement, build, refactor | writing-plans |
| Large Scope | multiple, across, comprehensive | subagent-driven-development |
| New Functions | add function, create component | test-driven-development |
| Creative | design, create, ideas | brainstorming |

## Evidence Base

These patterns were identified by searching conversation history with episodic-memory:
- Multiple "conversation continued from previous" entries indicating context exhaustion
- Iterative fix cycles visible in debug sessions
- Features built without upfront planning leading to rework
- Tests run *after* implementation rather than driving it
