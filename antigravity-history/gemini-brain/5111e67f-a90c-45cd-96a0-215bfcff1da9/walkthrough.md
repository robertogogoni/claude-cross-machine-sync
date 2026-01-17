# Obra Superpowers MCP Installation Walkthrough

I have successfully installed and configured a custom **Obra Superpowers MCP Server** for you. Since the official `obra/superpowers` repository is a skills library for Claude Code, I created a custom adapter that makes these skills available to Claude Desktop as MCP tools.

## Installation Details

### 1. Components
- **Source Repository**: `~/obra-superpowers` (Contains the core skills/prompts)
- **MCP Server Wrapper**: `~/obra-superpowers-mcp` (Node.js server that serves the skills)
- **Configuration**: `~/.config/Claude/claude_desktop_config.json`

### 2. Available Tools
The following MCP tools are now available in Claude Desktop:
- **`brainstorm`**: Loads the "Brainstorming" workflow prompt. Use this to refine ideas before coding.
- **`write_plan`**: Loads the "Implementation Plan" prompt. use this to generate detailed plans.
- **`execute_plan`**: Loads the "Execute Plan" prompt.

## Plugin Installation (Claude Code CLI)

I have also installed the **Superpowers Plugin** for your `claude` CLI tool using the following commands:
1. `claude plugin marketplace add obra/superpowers-marketplace`
2. `claude plugin install superpowers@superpowers-marketplace`

You can now use `claude` in your terminal with the new superpowers!

## Verification

To verify the installation:
1.  **Restart Claude Desktop** explicitly (Quit and Open).
2.  Look for the **socket plug icon** (MCP tools) in the top right of the chat input.
3.  Ask Claude: *"Run the brainstorm tool to help me design a todo app"* or *"What tools do you have?"*.
4.  Claude should call the `brainstorm` tool and receive the prompt content from the `obra/superpowers` repository.

## Fine-Tuning and Configuration

You can "fine-tune" the behavior of these superpowers by directly editing the source markdown files. The MCP server reads these files dynamically every time a tool is called.

### How to Modify Prompts
Edit the following files to change how the Superpowers behave:

- **Brainstorming**: `~/obra-superpowers/commands/brainstorm.md`
- **Planning**: `~/obra-superpowers/commands/write-plan.md`
- **Execution**: `~/obra-superpowers/commands/execute-plan.md`

### Example Customization
If you want the `brainstorm` tool to always ask about security implications, add that instruction to `brainstorm.md`:
```markdown
...
(Existing content)
...
**IMPORTANT**: Always ask the user about security constraints for the project.
```

### Advanced Configuration
The MCP server implementation is located at `~/obra-superpowers-mcp/index.js`. You can modify this file to:
- Add new tools (mapped to new markdown files).
- Change the descriptions of existing tools.

## Using with Antigravity (Me!)

You can also ask me to use these superpowers directly in our chat! Since I have access to the files, I can read the "Skill" definitions and follow their protocols manually.

**How to ask:**
- "Antigravity, please run the **brainstorming** skill for a new feature."
- "Can you use the **systematic debugging** superpower to fix this error?"

When you ask this, I will:
1.  Read the corresponding `SKILL.md` file (e.g., `~/obra-superpowers/skills/brainstorming/SKILL.md`).
2.  Adopt the persona and workflow described in that file.
3.  Guide you through the process (e.g., asking one question at a time, creating a design doc, etc.).

