---
name: tool-discovery
description: Use when user asks "what tools are available?", "is there a tool for...", "can Claude do...", "how can I...", mentions MCP servers, wants to discover capabilities, or seems uncertain about available integrations. Helps discover and search for tools, MCP servers, and plugins.
version: 1.0.0
---

# Tool Discovery & Search

This skill helps you discover available tools, MCP servers, and plugins. If a tool doesn't exist locally, it automatically searches for solutions.

## When This Skill Applies

Activate this skill when:
- User asks about available tools or capabilities
- User wants to know if Claude can do something
- User mentions "MCP", "plugin", "integration", or "tool"
- User seems uncertain about how to accomplish a task
- User asks "is there a way to..." or "can you..."

## Current Available Tools

### Core Claude Code Tools
Always available without configuration:
- **Bash**: Execute shell commands, run scripts, system operations
- **Read**: Read file contents, view code, examine configurations
- **Edit**: Modify existing files with precise edits
- **Write**: Create new files, overwrite existing ones
- **Glob**: Find files by pattern (e.g., `**/*.js`)
- **Grep**: Search code for patterns, find text across files
- **WebSearch**: Search the web for information
- **WebFetch**: Fetch and read web page content
- **LSP**: Language server features (go to definition, find references, hover info)
- **NotebookEdit**: Edit Jupyter notebooks
- **Skill**: Invoke other skills
- **Task**: Spawn specialized agents for complex tasks
- **TodoWrite**: Create and manage task lists
- **AskUserQuestion**: Ask clarifying questions with options

### Connected MCP Servers

Your currently configured MCP servers:

#### **Beeper** (messaging & chat)
- **Tool**: `mcp__beeper__search_chats`
- **Purpose**: Search and interact with chat messages across platforms
- **Use when**: Working with messages, chat history, or messaging platforms

#### **Claude in Chrome** (browser automation)
Tools available:
- `mcp__claude-in-chrome__javascript_tool`: Execute JavaScript in browser
- `mcp__claude-in-chrome__read_page`: Read page accessibility tree
- `mcp__claude-in-chrome__find`: Find elements on page
- `mcp__claude-in-chrome__form_input`: Fill form fields
- `mcp__claude-in-chrome__computer`: Mouse/keyboard control
- `mcp__claude-in-chrome__navigate`: Navigate URLs
- `mcp__claude-in-chrome__screenshot`: Take screenshots
- `mcp__claude-in-chrome__gif_creator`: Record browser actions as GIF
- `mcp__claude-in-chrome__upload_image`: Upload images to pages
- `mcp__claude-in-chrome__get_page_text`: Extract page text
- `mcp__claude-in-chrome__tabs_*`: Manage browser tabs
- `mcp__claude-in-chrome__read_console_messages`: Debug JavaScript
- `mcp__claude-in-chrome__read_network_requests`: Monitor network activity
- `mcp__claude-in-chrome__shortcuts_*`: Use browser shortcuts/workflows

**Use when**: Web scraping, browser automation, testing web apps, form filling, web interaction

#### **Episodic Memory** (conversation history)
- **Tool**: `mcp__plugin_episodic-memory_episodic-memory__search`
- **Purpose**: Search previous Claude Code conversations
- **Use when**: Recalling past decisions, finding previous solutions, remembering context

### Installed Plugins

Your currently enabled plugins:
- **superpowers@superpowers-marketplace**: Advanced development workflows
- **episodic-memory@superpowers-marketplace**: Cross-session memory

## Tool Discovery Process

When a user needs a tool that isn't currently available:

### Step 1: Understand the Need
Ask clarifying questions:
- What specific task are you trying to accomplish?
- What data/services do you need to interact with?
- What format is the input/output?

### Step 2: Search Existing Resources

Check these locations for potential solutions:

1. **MCP Registry** - Search official MCP servers:
   ```bash
   # Search the MCP registry on GitHub
   gh search repos "mcp server" topic:mcp
   ```

2. **Claude Plugins Marketplace**:
   ```bash
   # Check official plugins
   ls ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/
   ls ~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/
   ```

3. **Awesome MCP Servers**: Search https://github.com/punkpeye/awesome-mcp-servers

4. **NPM/PyPI for MCP**:
   ```bash
   # Search npm for MCP servers
   npm search mcp-server

   # Search PyPI
   pip search mcp
   ```

### Step 3: Present Options

Once you find relevant tools:

1. **Describe the tool**: What it does and how it helps
2. **Installation method**: How to install it
3. **Configuration needed**: What setup is required
4. **Example usage**: Show how it would solve the user's problem

### Step 4: Offer Installation Assistance

Ask the user:
- "I found [tool name] that can [capability]. Would you like me to help install it?"
- Provide installation commands
- Help configure `.mcp.json` or plugin settings

## Common Tool Categories & Solutions

### Database Access
- **PostgreSQL**: `@modelcontextprotocol/server-postgres`
- **SQLite**: `@modelcontextprotocol/server-sqlite`
- **MySQL**: Search npm for `mcp-server-mysql`

### API Integrations
- **GitHub**: `@modelcontextprotocol/server-github`
- **GitLab**: Available in official plugins
- **Slack**: Available in official plugins
- **Linear**: Available in official plugins
- **Stripe**: Available in official plugins

### Development Tools
- **Playwright**: Browser testing (official plugin)
- **Firebase**: Firebase integration (official plugin)
- **Docker**: Search for MCP docker servers
- **Kubernetes**: Search for MCP k8s servers

### Productivity
- **Google Drive**: Search MCP registry
- **Notion**: Search MCP registry
- **Calendar**: Search MCP registry

### AI & Data
- **Sentry**: Error tracking
- **Memory/RAG**: Episodic memory (already installed!)
- **Vector DBs**: Search for Pinecone, Weaviate MCP servers

## How to Install New MCP Servers

### Method 1: NPM-based MCP Server
```bash
# Install globally
npm install -g @modelcontextprotocol/server-NAME

# Add to ~/.claude.json
```

Then add configuration to `~/.claude.json`:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-NAME"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
```

### Method 2: Python MCP Server
```bash
# Install with pip
pip install mcp-server-NAME

# Add to ~/.claude.json
```

Configuration:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "python",
      "args": ["-m", "mcp_server_name"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
```

### Method 3: Custom MCP Server
```bash
# Clone repository
git clone https://github.com/org/mcp-server-name
cd mcp-server-name
npm install

# Add to ~/.claude.json with full path
```

## Search Strategy

When searching for a tool:

1. **Start broad**: "mcp server for [use case]"
2. **Check official sources**: Anthropic's MCP registry, official plugins
3. **Search GitHub**: `gh search repos "mcp [service name]"`
4. **Check awesome lists**: awesome-mcp-servers, awesome-claude
5. **Search package managers**: npm, PyPI, crates.io

## Example Interactions

### User: "Can Claude access my Google Calendar?"
Response pattern:
1. "Let me search for a Google Calendar MCP server..."
2. Use WebSearch or gh search to find options
3. Present findings: "I found [X] MCP server that provides Google Calendar integration"
4. Explain installation and configuration
5. Offer to help set it up

### User: "Is there a way to interact with Docker?"
Response pattern:
1. Check if docker MCP exists
2. Search GitHub/npm for docker MCP servers
3. Present options with pros/cons
4. Guide installation if user wants to proceed

### User: "What tools do I have?"
Response pattern:
1. List core tools
2. List connected MCP servers with their capabilities
3. List installed plugins
4. Mention discovery capabilities: "I can also search for new tools if you need something specific"

## Proactive Discovery

When you notice the user struggling with a task:
- Suggest: "This task might be easier with [tool]. Would you like me to search for an MCP server that can help?"
- Offer: "I can search the MCP registry for solutions if you'd like"

## Important Notes

- Always verify tool compatibility before suggesting installation
- Check if tools require API keys or authentication
- Warn about security implications of tools that access sensitive data
- Prioritize official Anthropic MCP servers when available
- Test that installed tools work before declaring success

## Quick Reference Commands

```bash
# Search MCP registry
gh search repos topic:mcp "keyword"

# List installed MCP servers
cat ~/.claude.json | grep -A 5 mcpServers

# List available plugins
ls ~/.claude/plugins/marketplaces/

# Check skill availability
ls ~/.claude/skills/

# Search npm for MCP
npm search mcp-server
```

## When to Use This Skill

✅ User asks "what can Claude do?"
✅ User wants to know available integrations
✅ User needs a capability that might require a new tool
✅ User mentions a service/API by name
✅ User seems uncertain about how to proceed

❌ User has a clear plan and knows what tools to use
❌ Task is straightforward with existing tools
❌ User is already using a specific tool successfully
