#!/usr/bin/env node
// MCP server that exposes Claude Code CLI memories as resources and tools
// for Claude Desktop to auto-load as conversation context.

const fs = require('fs');
const readline = require('readline');
const { execSync } = require('child_process');

const PROFILE_PATH = process.env.HOME + '/.claude/memory-profile.md';

const rl = readline.createInterface({ input: process.stdin });

function send(msg) {
  process.stdout.write(JSON.stringify(msg) + '\n');
}

function getProfile() {
  if (fs.existsSync(PROFILE_PATH)) {
    return fs.readFileSync(PROFILE_PATH, 'utf-8');
  }
  return 'No memory profile found. Run claude-memory-sync to generate.';
}

rl.on('line', (line) => {
  let req;
  try { req = JSON.parse(line); } catch { return; }
  const { method, id, params } = req;

  switch (method) {
    case 'initialize':
      send({ jsonrpc: '2.0', id, result: {
        protocolVersion: '2024-11-05',
        capabilities: { resources: {}, tools: {} },
        serverInfo: { name: 'memory-sync', version: '1.0.0' }
      }});
      break;

    case 'notifications/initialized':
      break;

    case 'resources/list':
      send({ jsonrpc: '2.0', id, result: { resources: [{
        uri: 'memory://profile',
        name: 'User Memory Profile',
        description: 'Compiled user profile from Claude Code CLI memories. Read for personalized context.',
        mimeType: 'text/markdown'
      }]}});
      break;

    case 'resources/read':
      if (params?.uri === 'memory://profile') {
        send({ jsonrpc: '2.0', id, result: { contents: [{
          uri: 'memory://profile', mimeType: 'text/markdown', text: getProfile()
        }]}});
      }
      break;

    case 'tools/list':
      send({ jsonrpc: '2.0', id, result: { tools: [
        {
          name: 'get_user_profile',
          description: "Get the user's compiled memory profile — includes hardware specs, preferences, active projects, GitHub repos, and behavioral guidelines. Call this at the start of conversations to personalize responses.",
          inputSchema: { type: 'object', properties: {}, required: [] }
        },
        {
          name: 'sync_memories',
          description: 'Re-sync the memory profile from Claude Code CLI memory files. Use after updating memories.',
          inputSchema: { type: 'object', properties: {}, required: [] }
        }
      ]}});
      break;

    case 'tools/call':
      if (params?.name === 'get_user_profile') {
        send({ jsonrpc: '2.0', id, result: {
          content: [{ type: 'text', text: getProfile() }]
        }});
      } else if (params?.name === 'sync_memories') {
        try {
          execSync(process.env.HOME + '/.local/bin/claude-memory-sync');
          send({ jsonrpc: '2.0', id, result: {
            content: [{ type: 'text', text: 'Memories synced.\n\n' + getProfile() }]
          }});
        } catch (e) {
          send({ jsonrpc: '2.0', id, result: {
            content: [{ type: 'text', text: 'Sync failed: ' + e.message }], isError: true
          }});
        }
      }
      break;

    default:
      if (id) {
        send({ jsonrpc: '2.0', id, error: { code: -32601, message: 'Method not found' }});
      }
  }
});
