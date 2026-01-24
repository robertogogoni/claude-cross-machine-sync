/**
 * Multi-Source Completion Engine
 *
 * Aggregates completions from:
 * - Skills (SuperNavigator 34 skills)
 * - Plugins (installed Claude Code plugins)
 * - MCP Tools (Beeper, Chrome, etc.)
 * - Command History (recent commands)
 * - Memory (past solutions from episodic memory)
 *
 * Ranking: semantic relevance + recency + frequency
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  dataDir: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data'),
  registryPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'skill-registry.json'),
  historyPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'completion-history.json'),
  pluginsPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'plugins', 'installed_plugins.json'),
  maxResults: 10,
  maxHistory: 100
};

// ============ Data Sources ============

function loadSkills() {
  try {
    const registry = JSON.parse(fs.readFileSync(CONFIG.registryPath, 'utf8'));
    return registry.skills.map(s => ({
      type: 'skill',
      name: s.name,
      display: `/${s.name}`,
      description: s.aliases.slice(0, 2).join(', '),
      layer: s.layer,
      category: s.category,
      aliases: s.aliases || [],
      keywords: s.triggers?.keywords || []
    }));
  } catch {
    return [];
  }
}

function loadPlugins() {
  try {
    const data = JSON.parse(fs.readFileSync(CONFIG.pluginsPath, 'utf8'));
    const plugins = [];
    for (const [name, versions] of Object.entries(data.plugins || {})) {
      const latest = versions[0];
      plugins.push({
        type: 'plugin',
        name: name.split('@')[0],
        display: name.split('@')[0],
        description: `v${latest.version}`,
        version: latest.version
      });
    }
    return plugins;
  } catch {
    return [];
  }
}

function loadMCPTools() {
  // Static list of known MCP tools (could be dynamically loaded)
  return [
    { type: 'mcp', name: 'beeper:search', display: 'mcp:beeper:search', description: 'Search Beeper chats' },
    { type: 'mcp', name: 'beeper:send', display: 'mcp:beeper:send', description: 'Send Beeper message' },
    { type: 'mcp', name: 'beeper:list', display: 'mcp:beeper:list', description: 'List Beeper messages' },
    { type: 'mcp', name: 'episodic:search', display: 'mcp:episodic:search', description: 'Search conversation history' },
    { type: 'mcp', name: 'chrome:navigate', display: 'mcp:chrome:navigate', description: 'Navigate browser tab' },
    { type: 'mcp', name: 'chrome:screenshot', display: 'mcp:chrome:screenshot', description: 'Take browser screenshot' }
  ];
}

function loadHistory() {
  try {
    const data = JSON.parse(fs.readFileSync(CONFIG.historyPath, 'utf8'));
    return (data.entries || []).map(e => ({
      type: 'history',
      name: e.command,
      display: e.command,
      description: `Used ${e.count}x`,
      count: e.count,
      lastUsed: e.lastUsed
    }));
  } catch {
    return [];
  }
}

function saveHistory(entries) {
  const data = { entries: entries.slice(0, CONFIG.maxHistory) };
  fs.writeFileSync(CONFIG.historyPath, JSON.stringify(data, null, 2));
}

function recordUsage(command) {
  const history = loadHistory();
  const existing = history.find(h => h.name === command);

  if (existing) {
    existing.count = (existing.count || 1) + 1;
    existing.lastUsed = Date.now();
  } else {
    history.unshift({
      type: 'history',
      name: command,
      display: command,
      description: 'Used 1x',
      count: 1,
      lastUsed: Date.now()
    });
  }

  // Sort by recency
  history.sort((a, b) => (b.lastUsed || 0) - (a.lastUsed || 0));
  saveHistory(history);
}

// ============ Matching & Scoring ============

function fuzzyMatch(query, text) {
  query = query.toLowerCase();
  text = text.toLowerCase();

  // Exact match
  if (text === query) return 1.0;

  // Prefix match
  if (text.startsWith(query)) return 0.9;

  // Contains match
  if (text.includes(query)) return 0.7;

  // Fuzzy character match
  let queryIdx = 0;
  let matches = 0;
  for (const char of text) {
    if (queryIdx < query.length && char === query[queryIdx]) {
      matches++;
      queryIdx++;
    }
  }

  if (queryIdx === query.length) {
    return 0.5 + (0.3 * (matches / text.length));
  }

  return 0;
}

function scoreCompletion(query, item) {
  let score = 0;

  // Name match (primary)
  const nameScore = fuzzyMatch(query, item.name);
  score += nameScore * 0.5;

  // Alias match (for skills)
  if (item.aliases) {
    for (const alias of item.aliases) {
      const aliasScore = fuzzyMatch(query, alias);
      if (aliasScore > 0) {
        score += aliasScore * 0.3;
        break;
      }
    }
  }

  // Keyword match (for skills)
  if (item.keywords) {
    for (const kw of item.keywords) {
      if (query.includes(kw) || kw.includes(query)) {
        score += 0.2;
        break;
      }
    }
  }

  // Recency boost (for history)
  if (item.lastUsed) {
    const ageHours = (Date.now() - item.lastUsed) / (1000 * 60 * 60);
    if (ageHours < 1) score += 0.15;
    else if (ageHours < 24) score += 0.10;
    else if (ageHours < 168) score += 0.05;
  }

  // Frequency boost (for history)
  if (item.count) {
    score += Math.min(item.count * 0.02, 0.1);
  }

  // Type priority
  const typePriority = { skill: 0.05, history: 0.03, plugin: 0.02, mcp: 0.01 };
  score += typePriority[item.type] || 0;

  return Math.min(score, 1.0);
}

// ============ Main API ============

function getCompletions(query, options = {}) {
  const { maxResults = CONFIG.maxResults, types = ['skill', 'plugin', 'mcp', 'history'] } = options;

  // Gather all sources
  let items = [];

  if (types.includes('skill')) {
    items = items.concat(loadSkills());
  }
  if (types.includes('plugin')) {
    items = items.concat(loadPlugins());
  }
  if (types.includes('mcp')) {
    items = items.concat(loadMCPTools());
  }
  if (types.includes('history')) {
    items = items.concat(loadHistory());
  }

  // Score and filter
  const scored = items
    .map(item => ({
      ...item,
      score: scoreCompletion(query, item)
    }))
    .filter(item => item.score > 0.1)
    .sort((a, b) => b.score - a.score)
    .slice(0, maxResults);

  return scored;
}

function formatForShell(completions, format = 'plain') {
  switch (format) {
    case 'json':
      return JSON.stringify(completions, null, 2);

    case 'powershell':
      // PowerShell completion format
      return completions.map(c =>
        `"${c.display}"`
      ).join('\n');

    case 'bash':
      // Bash COMPREPLY format
      return completions.map(c => c.display).join('\n');

    case 'zsh':
      // Zsh completion format with descriptions
      return completions.map(c =>
        `${c.display}:${c.description || c.type}`
      ).join('\n');

    case 'fzf':
      // fzf preview format
      return completions.map(c =>
        `${c.display}\t${c.type}\t${c.description || ''}`
      ).join('\n');

    default:
      // Plain text with columns
      const maxName = Math.max(...completions.map(c => c.display.length), 20);
      return completions.map(c =>
        `${c.display.padEnd(maxName)}  [${c.type}]  ${c.description || ''}`
      ).join('\n');
  }
}

// ============ CLI ============

function main() {
  const args = process.argv.slice(2);

  if (args[0] === 'complete' || args[0] === 'query') {
    const query = args[1] || '';
    const format = args[2] || 'plain';
    const completions = getCompletions(query);
    console.log(formatForShell(completions, format));
    return;
  }

  if (args[0] === 'record') {
    const command = args.slice(1).join(' ');
    if (command) {
      recordUsage(command);
      console.log(`Recorded: ${command}`);
    }
    return;
  }

  if (args[0] === 'history') {
    const history = loadHistory();
    console.log('Recent commands:');
    for (const h of history.slice(0, 10)) {
      console.log(`  ${h.name} (${h.count}x)`);
    }
    return;
  }

  if (args[0] === 'sources') {
    console.log('Completion sources:');
    console.log(`  Skills: ${loadSkills().length}`);
    console.log(`  Plugins: ${loadPlugins().length}`);
    console.log(`  MCP Tools: ${loadMCPTools().length}`);
    console.log(`  History: ${loadHistory().length}`);
    return;
  }

  // Interactive test mode
  console.log('=== Completion Engine Test ===\n');
  console.log('Sources:');
  console.log(`  Skills: ${loadSkills().length}`);
  console.log(`  Plugins: ${loadPlugins().length}`);
  console.log(`  MCP Tools: ${loadMCPTools().length}`);
  console.log(`  History: ${loadHistory().length}`);
  console.log('');

  const testQueries = ['debug', 'test', 'brain', 'beep', 'nav', 'sync'];

  for (const query of testQueries) {
    console.log(`Query: "${query}"`);
    const completions = getCompletions(query, { maxResults: 5 });
    if (completions.length === 0) {
      console.log('  No completions\n');
    } else {
      for (const c of completions) {
        console.log(`  ${c.display.padEnd(25)} [${c.type}] (${c.score.toFixed(2)})`);
      }
      console.log('');
    }
  }
}

module.exports = { getCompletions, formatForShell, recordUsage };

if (require.main === module) {
  main();
}
