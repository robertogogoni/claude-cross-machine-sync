# Skill Activator v4.0 Design Document

**Date**: 2026-01-25
**Author**: Rob + Claude
**Status**: Design Complete, Ready for Implementation
**Repository**: To be created after implementation

---

## Executive Summary

This document describes the design for **Skill Activator v4.0**, a complete rewrite of the Claude Code skill auto-activation system. The new system replaces the existing v3.0 JavaScript implementation with a TypeScript codebase that actually injects skill content (not just notifications), supports dependency resolution, guardrail skills, and context-aware slot limits.

### Key Improvements Over v3.0

| Feature | v3.0 | v4.0 |
|---------|------|------|
| Skill content injection | ❌ Banner only | ✅ Full `<skill>` XML tags |
| Dependency resolution | ❌ None | ✅ Topological sort |
| Guardrail skills | ❌ None | ✅ Always-on enforcement |
| Context-aware slots | ❌ Fixed 2 slots | ✅ 2-4 based on complexity |
| Overflow threshold | ❌ None | ✅ 0.90+ bypasses limits |
| TypeScript | ❌ Plain JS | ✅ Full type safety |
| Test coverage | ❌ None | ✅ 120+ tests |
| Cross-platform | ⚠️ Hardcoded paths | ✅ `os.homedir()` |

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [7-Stage Pipeline](#2-7-stage-pipeline)
3. [Module Specifications](#3-module-specifications)
4. [Skill Schema](#4-skill-schema)
5. [Build System](#5-build-system)
6. [Testing Strategy](#6-testing-strategy)
7. [Cross-Platform Support](#7-cross-platform-support)
8. [Implementation Plan](#8-implementation-plan)
9. [Open Source Publication](#9-open-source-publication)

---

## 1. Architecture Overview

### 1.1 High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Prompt Submitted                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   UserPromptSubmit Hook                          │
│                 (skill-activator-unified.cjs)                    │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│  Check Cache  │──hit──│ Return Cached │       │   Session     │
│   (MD5 hash)  │       │    Result     │       │   Tracking    │
└───────────────┘       └───────────────┘       └───────────────┘
        │ miss                                          │
        ▼                                               ▼
┌───────────────────────────────────────────────────────────────┐
│                      Haiku API Call                            │
│         (intent detection + complexity assessment)             │
└───────────────────────────────────────────────────────────────┘
        │                                       │
        ▼ success                               ▼ failure
┌───────────────┐                       ┌───────────────┐
│ Parse Response│                       │   Keyword     │
│ + Complexity  │                       │   Fallback    │
└───────────────┘                       └───────────────┘
        │                                       │
        └───────────────┬───────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Skill Filtration                              │
│  • Apply slot limits (2-4 based on complexity)                   │
│  • Promote overflow skills (score >= 0.90)                       │
│  • Separate inject vs suggest                                    │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Skill Resolution                               │
│  • Add affinity skills (FREE, no slot cost)                      │
│  • Add guardrail skills (always-on)                              │
│  • Resolve dependencies (topological sort)                       │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Skill Loading                                 │
│  • Find SKILL.md files (local → plugins → supercharged)          │
│  • Read content                                                  │
│  • Track source for attribution                                  │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Output Formatting                              │
│  • Wrap each skill in <skill name="..." source="..."> tags       │
│  • Generate summary banner                                       │
│  • Update session state                                          │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│              Injected into Claude's Context                      │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Module Architecture

```
src/
├── intent-analyzer.ts      # Main orchestrator (7 stages)
├── paths.ts                # Cross-platform path resolution
├── types.ts                # TypeScript interfaces
├── constants.ts            # Configurable thresholds
├── anthropic-client.ts     # Haiku API with complexity
├── cache-manager.ts        # MD5 caching with TTL
├── keyword-matcher.ts      # Fallback matching
├── intent-scorer.ts        # Confidence categorization
├── skill-filtration.ts     # Slot limits, promotion
├── skill-resolution.ts     # Dependencies, guardrails
├── skill-loader.ts         # Load SKILL.md content
├── skill-state-manager.ts  # Session tracking
├── output-formatter.ts     # XML tags + banner
├── debug-logger.ts         # File-based logging
└── schema-validator.ts     # Registry validation
```

---

## 2. 7-Stage Pipeline

### Stage 1: Input Validation
- Validate prompt is non-empty string
- Extract session ID from environment
- Initialize debug logging

### Stage 2: Intent Analysis (Haiku)
- Call Claude Haiku API with skill list
- Receive matches with confidence scores
- Receive complexity assessment: `simple | moderate | complex`
- Receive recommended slot count: 2-4

### Stage 3: Confidence Scoring
- Categorize matches by confidence level
- Apply keyword fallback if Haiku fails
- Merge and deduplicate results

### Stage 4: Slot Filtration
- Apply slot limits based on complexity
- Promote skills with score >= 0.90 (overflow)
- Separate into: `toInject`, `promoted`, `suggested`

### Stage 5: Affinity & Guardrail Injection
- Add affinity skills for injected skills (FREE)
- Add guardrail skills based on context
- These don't count against slot limits

### Stage 6: Dependency Resolution
- Topological sort to determine load order
- Ensure required skills load before dependents
- Detect and error on circular dependencies

### Stage 7: Skill Loading & Output
- Load SKILL.md content for each skill
- Wrap in `<skill>` XML tags
- Generate summary banner
- Update session state to prevent re-injection

---

## 3. Module Specifications

### 3.1 paths.ts

```typescript
import os from 'os';
import path from 'path';

export const HOME = os.homedir();

export const PATHS = {
  claudeDir: path.join(HOME, '.claude'),
  skillRules: path.join(HOME, '.claude', 'skills', 'skill-rules.json'),
  cache: path.join(HOME, '.claude', 'data', 'intent-cache.json'),
  sessionState: path.join(HOME, '.claude', 'data', 'session-skills.json'),
  debugLog: path.join(HOME, '.claude', 'logs', 'skill-activator.log'),

  skillContent: (skillName: string) =>
    path.join(HOME, '.claude', 'skills', skillName, 'SKILL.md'),

  pluginSkills: (plugin: string) =>
    path.join(HOME, '.claude', 'plugins', plugin, 'skills'),
} as const;
```

### 3.2 types.ts

```typescript
export interface SkillMatch {
  skill: string;
  score: number;
  reason: string;
}

export interface HaikuResponse {
  matches: SkillMatch[];
  complexity: 'simple' | 'moderate' | 'complex';
  recommendedSlots: number;
}

export interface SkillRule {
  name: string;
  type: 'domain' | 'guardrail';
  aliases: string[];
  triggers: {
    keywords: string[];
    patterns: string[];
    intent_phrases: string[];
  };
  confidence_boost: number;
  affinity: string[];
  requiredSkills: string[];
  injectionOrder: number;
  source: {
    type: 'local' | 'plugin';
    path?: string;
    plugin?: string;
  };
}

export interface LoadedSkill {
  name: string;
  content: string;
  source: string;
  path: string;
}

export interface AnalysisResult {
  prompt: string;
  toInject: string[];
  promoted: string[];
  affinity: string[];
  guardrails: string[];
  dependencies: string[];
  suggested: string[];
  skipped: string[];
  complexity: 'simple' | 'moderate' | 'complex';
  recommendedSlots: number;
  source: 'haiku' | 'keyword-fallback' | 'cache';
  cached: boolean;
  loadedSkills: LoadedSkill[];
  output: string;
}
```

### 3.3 constants.ts

```typescript
export const CONFIG = {
  // Thresholds
  autoInjectThreshold: 0.65,
  suggestThreshold: 0.50,
  overflowThreshold: 0.90,

  // Slot management
  baseSlots: 2,
  maxSlots: 4,
  maxOverflow: 2,

  // Haiku API
  haikuModel: 'claude-3-5-haiku-20241022',
  haikuMaxTokens: 500,
  haikuTimeoutMs: 10000,

  // Caching
  cacheTTLMinutes: 60,

  // Keyword matching caps
  maxKeywordScore: 0.60,
  maxPatternScore: 0.40,
  maxIntentScore: 0.50,
} as const;
```

### 3.4 anthropic-client.ts

System prompt for Haiku:

```
You are a skill matcher for Claude Code. Given a user prompt, identify relevant skills.

Available skills:
${skillList}

Respond with JSON:
{
  "matches": [
    {"skill": "skill-name", "score": 0.0-1.0, "reason": "brief reason"}
  ],
  "complexity": "simple|moderate|complex",
  "recommendedSlots": 2-4
}

Scoring:
- 0.90-1.0: Directly requested or obvious match
- 0.70-0.89: Strongly implied
- 0.50-0.69: Possibly relevant

Complexity guidelines:
- simple: Single focused task, quick question → 2 slots
- moderate: Multi-step task, debugging, refactoring → 3 slots
- complex: Multiple concerns, architecture, large feature → 4 slots
```

### 3.5 skill-loader.ts

Search order for skill files:

1. Local skills: `~/.claude/skills/{name}/SKILL.md`
2. Superpowers plugin: `~/.claude/plugins/superpowers/skills/{name}/SKILL.md`
3. Supercharged plugin: `~/.claude/plugins/claude-skills-supercharged/skills/{name}/SKILL.md`
4. Sync repo: `~/claude-cross-machine-sync/skills/{name}/SKILL.md`

### 3.6 output-formatter.ts

Output format:

```xml
<skill name="systematic-debugging" source="superpowers">
[Full SKILL.md content here]
</skill>

<skill name="test-driven-development" source="local">
[Full SKILL.md content here]
</skill>
```

Summary banner:

```
═══════════════════════════════════════════════════════════════
 🎯 Skills Auto-Activated (complexity: moderate, slots: 3)
───────────────────────────────────────────────────────────────
 ✓ systematic-debugging (0.92) - Error keyword detected
 ✓ test-driven-development (0.78) - Testing context
 + python-basics (dependency)

 💡 Suggested: code-review (0.55)
═══════════════════════════════════════════════════════════════
```

---

## 4. Skill Schema

### 4.1 skill-rules.json (v2.0)

```json
{
  "$schema": "./skill-rules.schema.json",
  "version": "2.0.0",
  "config": {
    "autoInjectThreshold": 0.65,
    "suggestThreshold": 0.50,
    "overflowThreshold": 0.90,
    "baseSlots": 2,
    "maxSlots": 4,
    "maxOverflow": 2
  },
  "skills": [
    {
      "name": "systematic-debugging",
      "type": "domain",
      "layer": "app",
      "category": "quality",
      "aliases": ["debug", "fix bug", "troubleshoot"],
      "triggers": {
        "keywords": ["bug", "error", "broken", "crash", "fail"],
        "patterns": ["not working", "doesn't work", "getting.*error"],
        "intent_phrases": ["help me debug", "something is broken"]
      },
      "confidence_boost": 0.25,
      "affinity": ["test-driven-development"],
      "requiredSkills": [],
      "injectionOrder": 10,
      "source": {
        "type": "plugin",
        "plugin": "superpowers"
      }
    },
    {
      "name": "guardrail-security",
      "type": "guardrail",
      "triggers": {
        "keywords": ["api", "auth", "password", "token", "secret"],
        "patterns": [],
        "intent_phrases": []
      },
      "confidence_boost": 0,
      "affinity": [],
      "requiredSkills": [],
      "injectionOrder": 1,
      "source": {
        "type": "local"
      }
    }
  ]
}
```

### 4.2 Migration Script

Location: `scripts/migrate-registry.ts`

Converts old `skill-registry.json` to new `skill-rules.json` format:
- Adds `type: "domain"` (default)
- Adds empty `affinity`, `requiredSkills` arrays
- Adds `injectionOrder: 50` (default)
- Infers `source` from skill location

---

## 5. Build System

### 5.1 Package Configuration

```json
{
  "name": "skill-activator",
  "version": "4.0.0",
  "scripts": {
    "build": "esbuild src/intent-analyzer.ts --bundle --platform=node --target=node18 --outfile=dist/skill-activator.cjs --format=cjs",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "validate": "npm run typecheck && npm run lint && npm run test",
    "deploy": "npm run build && node scripts/deploy.js"
  }
}
```

### 5.2 Output

Single file: `dist/skill-activator.cjs` (~50KB)
- No runtime dependencies
- Platform-agnostic
- Works on Node.js 18+

---

## 6. Testing Strategy

### 6.1 Test Distribution

| Category | Tests | Coverage Target |
|----------|-------|-----------------|
| Unit tests | 100 | 80% |
| Integration tests | 20 | 75% |
| **Total** | **120** | **80%** |

### 6.2 Test-Driven Development

Each module follows:
1. Write tests first
2. Implement module
3. Verify tests pass
4. Move to next module

### 6.3 CI/CD

GitHub Actions workflow:
- Runs on `ubuntu-latest` and `windows-latest`
- Tests Node.js 18 and 20
- Uploads coverage to Codecov
- Builds artifact on success

---

## 7. Cross-Platform Support

### 7.1 Target Machines

| Machine | OS | User | Home |
|---------|----|----- |------|
| MacBook Air | Arch Linux | rob | `/home/rob` |
| Dell G15 | Windows 11 | rober | `C:\Users\rober` |

### 7.2 Platform Handling

- `os.homedir()` for home directory
- `path.join()` for path separators
- Machine-specific `settings.json` in sync repo
- Symlinks (Linux) vs Copy (Windows) for deployment

### 7.3 Settings Location

```
machines/
├── macbook-air/claude/settings.json  # Linux paths
└── dell-g15/claude/settings.json     # Windows paths
```

---

## 8. Implementation Plan

### Phase 1: Foundation (Day 1)
- Initialize project
- Implement `paths.ts`, `types.ts`, `constants.ts`
- 5 tests

### Phase 2: Caching & Matching (Day 1-2)
- Implement `cache-manager.ts`, `keyword-matcher.ts`
- 27 tests

### Phase 3: Haiku Integration (Day 2)
- Implement `anthropic-client.ts`, `intent-scorer.ts`
- 16 tests

### Phase 4: Filtration & Resolution (Day 2-3)
- Implement `skill-filtration.ts`, `skill-resolution.ts`
- 32 tests

### Phase 5: Loading & Output (Day 3)
- Implement `skill-loader.ts`, `output-formatter.ts`, `skill-state-manager.ts`
- 30 tests

### Phase 6: Supporting Modules (Day 3-4)
- Implement `debug-logger.ts`, `schema-validator.ts`
- 14 tests

### Phase 7: Orchestrator & Integration (Day 4)
- Implement `intent-analyzer.ts`
- Integration tests
- 20 tests

### Phase 8: Migration & Deployment (Day 4-5)
- Run migration script
- Deploy to both machines
- Manual testing

### Phase 9: Documentation (Day 5)
- Complete this design doc
- Update CLAUDE.md
- Create usage guide

### Phase 10: Open Source Publication (Day 6+)
- Create GitHub repository
- Write comprehensive README
- Add LICENSE, CONTRIBUTING.md
- Set up CI/CD
- Create one-command installer
- Publish and announce

---

## 9. Open Source Publication

### 9.1 Repository Structure

```
claude-skill-activator/
├── README.md              # Badges, GIFs, installation
├── LICENSE                # MIT
├── CONTRIBUTING.md        # How to contribute
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── .github/
│   ├── workflows/test.yml
│   └── ISSUE_TEMPLATE/
├── src/                   # TypeScript source
├── dist/                  # Compiled output
├── tests/                 # Test suite
├── scripts/
│   ├── install.sh         # Linux/macOS installer
│   ├── install.ps1        # Windows installer
│   └── migrate-registry.ts
├── examples/
│   ├── skill-rules.json   # Example configuration
│   └── custom-skill/      # Example custom skill
└── docs/
    ├── ARCHITECTURE.md
    ├── CONFIGURATION.md
    └── TROUBLESHOOTING.md
```

### 9.2 README Preview

- Hero banner with logo
- Feature list with emojis
- Animated GIF demo
- One-command installation
- Quick start guide
- Configuration reference
- Badges: build status, coverage, license

### 9.3 Installation Scripts

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/.../install.ps1 | iex
```

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **Affinity skill** | Related skill that loads for free (no slot cost) |
| **Guardrail skill** | Always-on enforcement skill |
| **Overflow** | Skill with score >= 0.90 bypasses slot limit |
| **Slot** | Budget for how many skills can be injected |
| **Complexity** | Haiku's assessment: simple/moderate/complex |

## Appendix B: References

- [claude-skills-supercharged](https://github.com/jefflester/claude-skills-supercharged)
- [Superpowers Plugin](https://github.com/obra/superpowers)
- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)

---

*Document generated: 2026-01-25*
*Authors: Rob + Claude*
