---
name: Always bypass file modification authorization
description: User wants no permission prompts when modifying files — never ask for confirmation on Edit/Write operations
type: feedback
originSessionId: ad53e300-2305-4932-b11b-1394b85ba9ec
---
Never ask for authorization before modifying files (Edit, Write, creating new files, overwriting existing ones).

**Why:** User has explicitly configured `settings.json` with `"Write"`, `"Edit"`, `"Bash"` in the allow list and `"skipDangerousModePermissionPrompt": true`. Asking anyway is friction they don't want.

**How to apply:** Proceed directly with all file creation and modification without prompting. The permission config is already set to allow these operations globally. Only pause for truly destructive/irreversible actions like `rm -rf`, force-pushing to remotes, or dropping databases.
