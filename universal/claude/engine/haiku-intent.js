/**
 * Haiku Intent Analyzer
 *
 * Uses Claude Haiku for fast, cheap semantic intent detection.
 * Falls back to keyword matching if API unavailable.
 *
 * Cost: ~$0.25/1M input tokens, ~$1.25/1M output tokens
 * Speed: ~200ms first call, <10ms cached
 */

const https = require('https');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  apiKeyEnvVar: 'ANTHROPIC_API_KEY',
  model: 'claude-3-5-haiku-20241022',
  maxTokens: 500,
  cachePath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'intent-cache.json'),
  cacheTTLMinutes: 60,
  registryPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'skill-registry.json')
};

// Load cache
function loadCache() {
  try {
    const data = fs.readFileSync(CONFIG.cachePath, 'utf8');
    return JSON.parse(data);
  } catch {
    return { entries: {}, lastCleanup: Date.now() };
  }
}

// Save cache
function saveCache(cache) {
  // Cleanup old entries
  const now = Date.now();
  const ttlMs = CONFIG.cacheTTLMinutes * 60 * 1000;

  if (now - cache.lastCleanup > ttlMs) {
    for (const key of Object.keys(cache.entries)) {
      if (now - cache.entries[key].timestamp > ttlMs) {
        delete cache.entries[key];
      }
    }
    cache.lastCleanup = now;
  }

  fs.writeFileSync(CONFIG.cachePath, JSON.stringify(cache, null, 2));
}

// Hash prompt for cache key
function hashPrompt(prompt) {
  return crypto.createHash('md5').update(prompt.toLowerCase().trim()).digest('hex');
}

// Load skill registry
function loadRegistry() {
  try {
    const data = fs.readFileSync(CONFIG.registryPath, 'utf8');
    return JSON.parse(data);
  } catch {
    return { skills: [] };
  }
}

// Build skill list for prompt
function buildSkillList(registry) {
  return registry.skills.map(s =>
    `- ${s.name}: ${s.aliases.slice(0, 2).join(', ')}`
  ).join('\n');
}

// Call Haiku API
async function callHaiku(prompt, skillList) {
  const apiKey = process.env[CONFIG.apiKeyEnvVar];

  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY not set');
  }

  const systemPrompt = `You are a skill matcher for Claude Code. Given a user prompt, identify which skills are relevant.

Available skills:
${skillList}

Respond with a JSON object containing an array of matches:
{
  "matches": [
    {"skill": "skill-name", "score": 0.0-1.0, "reason": "brief reason"}
  ]
}

Rules:
- Only include skills with score >= 0.5
- Score 0.9-1.0: Directly requested or obvious match
- Score 0.7-0.89: Strongly implied
- Score 0.5-0.69: Possibly relevant
- Maximum 5 matches
- Be conservative - don't match unrelated skills`;

  const requestBody = JSON.stringify({
    model: CONFIG.model,
    max_tokens: CONFIG.maxTokens,
    messages: [
      { role: 'user', content: `User prompt: "${prompt}"` }
    ],
    system: systemPrompt
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.anthropic.com',
      port: 443,
      path: '/v1/messages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (response.error) {
            reject(new Error(response.error.message));
            return;
          }
          const content = response.content?.[0]?.text || '{}';
          // Extract JSON from response
          const jsonMatch = content.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            resolve(JSON.parse(jsonMatch[0]));
          } else {
            resolve({ matches: [] });
          }
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    req.write(requestBody);
    req.end();
  });
}

// Main analysis function
async function analyzeIntent(prompt, options = {}) {
  const { useCache = true, forceApi = false } = options;

  const registry = loadRegistry();
  const cache = loadCache();
  const promptHash = hashPrompt(prompt);

  // Check cache
  if (useCache && !forceApi && cache.entries[promptHash]) {
    const cached = cache.entries[promptHash];
    const age = Date.now() - cached.timestamp;
    if (age < CONFIG.cacheTTLMinutes * 60 * 1000) {
      return {
        ...cached.result,
        cached: true,
        cacheAge: Math.round(age / 1000)
      };
    }
  }

  // Try Haiku API
  try {
    const skillList = buildSkillList(registry);
    const result = await callHaiku(prompt, skillList);

    // Enrich with layer info
    const enriched = {
      matches: (result.matches || []).map(m => {
        const skill = registry.skills.find(s => s.name === m.skill);
        return {
          ...m,
          layer: skill?.layer || 'unknown',
          category: skill?.category || 'unknown'
        };
      }),
      source: 'haiku',
      cached: false
    };

    // Cache result
    cache.entries[promptHash] = {
      timestamp: Date.now(),
      result: enriched
    };
    saveCache(cache);

    return enriched;

  } catch (error) {
    // Fallback to keyword matching
    console.error('[Haiku] API error, falling back to keywords:', error.message);
    return {
      matches: [],
      source: 'fallback',
      error: error.message,
      cached: false
    };
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);

  if (args[0] === '--analyze' && args[1]) {
    const prompt = args.slice(1).join(' ');
    const result = await analyzeIntent(prompt);
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (args[0] === '--clear-cache') {
    fs.writeFileSync(CONFIG.cachePath, JSON.stringify({ entries: {}, lastCleanup: Date.now() }));
    console.log('Cache cleared');
    return;
  }

  if (args[0] === '--cache-stats') {
    const cache = loadCache();
    const entries = Object.keys(cache.entries).length;
    console.log(`Cache entries: ${entries}`);
    console.log(`Last cleanup: ${new Date(cache.lastCleanup).toISOString()}`);
    return;
  }

  // Test mode
  console.log('=== Haiku Intent Analyzer Test ===\n');

  const testPrompts = [
    "Help me debug this error in the API",
    "I want to write tests for the auth module",
    "Let's brainstorm a new dashboard feature",
    "Something is broken and I don't know why",
    "Create a checkpoint before I make changes"
  ];

  for (const prompt of testPrompts) {
    console.log(`Prompt: "${prompt}"`);
    try {
      const result = await analyzeIntent(prompt, { forceApi: true });
      if (result.matches.length === 0) {
        console.log('  No matches');
      } else {
        for (const m of result.matches) {
          console.log(`  ${m.skill}: ${m.score} - ${m.reason}`);
        }
      }
      console.log(`  Source: ${result.source}${result.cached ? ' (cached)' : ''}\n`);
    } catch (e) {
      console.log(`  Error: ${e.message}\n`);
    }
  }
}

module.exports = { analyzeIntent, loadCache, hashPrompt };

if (require.main === module) {
  main().catch(console.error);
}
