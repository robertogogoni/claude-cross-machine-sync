# Implementation Plan - Obra Superpowers MCP Setup

This plan outlines the steps to install, configure, and fine-tune the Obra Superpowers MCP (Model Context Protocol) integration. The goal is to enable "Superpowers" capabilities (structured workflows, tools) within an MCP-compliant client like Claude Desktop.

## User Review Required
> [!IMPORTANT]
> Since "Obra Superpowers" is primarily a Claude Code plugin, we will first verify if the main repository contains a standalone MCP server implementation. If not, we may need to use `obra/superpowers-chrome` or similar, or potentially use an adapter.

## Proposed Changes

### 1. Installation & Setup
- **Clone Repository**: Clone `https://github.com/obra/superpowers` to a local directory (e.g., `~/obra-superpowers`).
- **Dependency Installation**: Run `npm install` (or equivalent) to install required packages.
- **Build**: Run build scripts to prepare the server.

### 2. MCP Server Configuration
- **Identify Entry Point**: Locate the script to run the MCP server (e.g., `dist/index.js` or a specific command).
- **Claude Desktop Config**:
    - Update `claude_desktop_config.json` to include the Superpowers MCP server.
    - Path: `~/.config/Claude/claude_desktop_config.json` (Linux) or similar.
    - **Draft Config**:
      ```json
      {
        "mcpServers": {
          "superpowers": {
            "command": "node",
            "args": ["/path/to/obra-superpowers/dist/index.js"]
          }
        }
      }
      ```

### 3. Fine-Tuning
- **Prompt Customization**: specific prompts are likely located in `src/prompts` or similar. We will identify these files for the user to edit.
- **Configuration Files**: Check for `.env` or `config.js` files to adjust behaviors (e.g., specific workflow steps).

## Verification Plan

### Automated Tests
- Run `npm test` if available in the repo.
- Attempt to start the server manually to check for startup errors.

### Manual Verification
- Since we cannot interact with the user's Claude Desktop UI, we will verify the server process starts and responds to basic input (if possible via stdio).
