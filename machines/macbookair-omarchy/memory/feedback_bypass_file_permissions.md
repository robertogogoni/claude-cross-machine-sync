---
name: Always bypass authorization prompts
description: User wants no permission prompts for any tool or agent — file edits, Codex approvals, bash commands, all auto-approved
type: feedback
originSessionId: ad53e300-2305-4932-b11b-1394b85ba9ec
---
Never ask for authorization before modifying files (Edit, Write, creating new files, overwriting existing ones). Never ask Codex to confirm shell commands — always pass `--dangerously-bypass-approvals-and-sandbox` by default.

**Why:** User runs in full-trust local environment with `settings.json` set to allow `"Write"`, `"Edit"`, `"Bash"` globally and `"skipDangerousModePermissionPrompt": true`. Approval friction is never wanted. Codex exec server defaults `bypass_approvals=true` for the same reason.

**How to apply:** Proceed directly with all file creation and modification without prompting. In Codex MCP calls, keep `bypass_approvals=true` (the default). Only pause for truly irreversible remote actions: `rm -rf` on critical paths, force-pushing to remotes, dropping databases.
