/**
 * Skill Activator Hook v2
 *
 * Enhanced with Haiku AI intent detection + keyword fallback.
 *
 * Priority Chain:
 * 1. Haiku API (semantic understanding)
 * 2. Keyword/Pattern matching (fast fallback)
 * 3. Fuzzy matching (last resort)
 *
 * Thresholds:
 * - Auto-inject: score > 0.65
 * - Suggest: score 0.50 - 0.65
 * - Ignore: score < 0.50
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');

// Configuration
const CONFIG = {
  registryPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'skill-registry.json'),
  cachePath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'intent-cache.json'),
  sessionPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'session-skills.json'),
  autoInjectThreshold: 0.65,
  suggestThreshold: 0.50,
  maxSuggestions: 3,
  cacheTTLMinutes: 60,
  useHaiku: true,  // Set to false to disable AI
  haikuModel: 'claude-3-5-haiku-20241022',
  haikuTimeout: 5000
};

// ============ Registry & Session ============

function loadRegistry() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG.registryPath, 'utf8'));
  } catch {
    return { skills: [] };
  }
}

function loadSessionSkills() {
  try {
    const session = JSON.parse(fs.readFileSync(CONFIG.sessionPath, 'utf8'));
    const today = new Date().toISOString().split('T')[0];
    return session.date === today ? new Set(session.skills) : new Set();
  } catch {
    return new Set();
  }
}

function saveSessionSkills(skills) {
  const session = {
    date: new Date().toISOString().split('T')[0],
    skills: Array.from(skills)
  };
  fs.writeFileSync(CONFIG.sessionPath, JSON.stringify(session, null, 2));
}

// ============ Cache ============

function loadCache() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG.cachePath, 'utf8'));
  } catch {
    return { entries: {}, lastCleanup: Date.now() };
  }
}

function saveCache(cache) {
  const now = Date.now();
  const ttlMs = CONFIG.cacheTTLMinutes * 60 * 1000;

  // Cleanup old entries
  if (now - (cache.lastCleanup || 0) > ttlMs) {
    for (const key of Object.keys(cache.entries || {})) {
      if (now - cache.entries[key].timestamp > ttlMs) {
        delete cache.entries[key];
      }
    }
    cache.lastCleanup = now;
  }

  fs.writeFileSync(CONFIG.cachePath, JSON.stringify(cache, null, 2));
}

function hashPrompt(prompt) {
  return crypto.createHash('md5').update(prompt.toLowerCase().trim()).digest('hex');
}

// ============ Haiku API ============

async function callHaiku(prompt, skillList) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('No API key');

  const systemPrompt = `You are a skill matcher. Given a user prompt, identify relevant skills.

Skills:
${skillList}

Respond with JSON only:
{"matches":[{"skill":"name","score":0.0-1.0,"reason":"brief"}]}

Rules:
- Only score >= 0.5
- Max 5 matches
- Be conservative`;

  const body = JSON.stringify({
    model: CONFIG.haikuModel,
    max_tokens: 300,
    messages: [{ role: 'user', content: `Prompt: "${prompt}"` }],
    system: systemPrompt
  });

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.anthropic.com',
      port: 443,
      path: '/v1/messages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (response.error) throw new Error(response.error.message);
          const content = response.content?.[0]?.text || '{}';
          const jsonMatch = content.match(/\{[\s\S]*\}/);
          resolve(jsonMatch ? JSON.parse(jsonMatch[0]) : { matches: [] });
        } catch (e) { reject(e); }
      });
    });

    req.on('error', reject);
    req.setTimeout(CONFIG.haikuTimeout, () => {
      req.destroy();
      reject(new Error('Timeout'));
    });
    req.write(body);
    req.end();
  });
}

// ============ Keyword Fallback ============

function fuzzyScore(str1, str2) {
  str1 = str1.toLowerCase();
  str2 = str2.toLowerCase();
  if (str1 === str2) return 1.0;
  if (str1.includes(str2) || str2.includes(str1)) return 0.8;

  const chars1 = new Set(str1.split(''));
  const chars2 = new Set(str2.split(''));
  const intersection = [...chars1].filter(x => chars2.has(x)).length;
  return intersection / new Set([...chars1, ...chars2]).size;
}

function keywordScore(prompt, skill) {
  const promptLower = prompt.toLowerCase();
  let score = 0;
  let reasons = [];

  for (const kw of skill.triggers?.keywords || []) {
    if (promptLower.includes(kw.toLowerCase())) {
      score += 0.15;
      reasons.push(`kw:${kw}`);
    }
  }

  for (const pattern of skill.triggers?.patterns || []) {
    try {
      if (new RegExp(pattern, 'i').test(promptLower)) {
        score += 0.20;
        reasons.push(`pat:${pattern}`);
      }
    } catch {}
  }

  for (const phrase of skill.triggers?.intent_phrases || []) {
    const sim = fuzzyScore(promptLower, phrase.toLowerCase());
    if (sim > 0.6) {
      score += 0.25 * sim;
      reasons.push(`int:${phrase.substring(0, 15)}...`);
    }
  }

  for (const alias of skill.aliases || []) {
    if (promptLower.includes(alias.toLowerCase())) {
      score += 0.10;
      reasons.push(`alias:${alias}`);
    }
  }

  score += skill.confidence_boost || 0;

  return {
    score: Math.min(score, 1.0),
    reason: reasons.slice(0, 3).join(', ')
  };
}

// ============ Main Analysis ============

async function analyzePrompt(prompt) {
  const registry = loadRegistry();
  const sessionSkills = loadSessionSkills();
  const cache = loadCache();
  const promptHash = hashPrompt(prompt);

  // Check cache
  const cached = cache.entries?.[promptHash];
  if (cached && Date.now() - cached.timestamp < CONFIG.cacheTTLMinutes * 60 * 1000) {
    return cached.results.filter(r => !sessionSkills.has(r.name));
  }

  let results = [];

  // Try Haiku first
  if (CONFIG.useHaiku && process.env.ANTHROPIC_API_KEY) {
    try {
      const skillList = registry.skills.map(s => `- ${s.name}`).join('\n');
      const haiku = await callHaiku(prompt, skillList);

      results = (haiku.matches || []).map(m => {
        const skill = registry.skills.find(s => s.name === m.skill);
        return {
          name: m.skill,
          score: m.score,
          reason: m.reason,
          layer: skill?.layer || 'unknown',
          category: skill?.category || 'unknown',
          source: 'haiku',
          action: m.score >= CONFIG.autoInjectThreshold ? 'inject' : 'suggest'
        };
      });
    } catch (e) {
      // Fall through to keyword matching
    }
  }

  // Fallback to keyword matching if Haiku failed or disabled
  if (results.length === 0) {
    for (const skill of registry.skills) {
      const { score, reason } = keywordScore(prompt, skill);
      if (score >= CONFIG.suggestThreshold) {
        results.push({
          name: skill.name,
          score: parseFloat(score.toFixed(3)),
          reason,
          layer: skill.layer,
          category: skill.category,
          source: 'keywords',
          action: score >= CONFIG.autoInjectThreshold ? 'inject' : 'suggest'
        });
      }
    }
  }

  // Sort by score
  results.sort((a, b) => b.score - a.score);

  // Cache results
  cache.entries = cache.entries || {};
  cache.entries[promptHash] = { timestamp: Date.now(), results };
  saveCache(cache);

  // Filter out already-injected
  return results.filter(r => !sessionSkills.has(r.name));
}

// ============ Output Generation ============

function generateInjection(results) {
  const toInject = results.filter(r => r.action === 'inject');
  const toSuggest = results.filter(r => r.action === 'suggest').slice(0, CONFIG.maxSuggestions);

  let output = '';

  if (toInject.length > 0) {
    output += '\n<skill-activation>\n';
    output += `🎯 Auto-activated skills:\n`;
    for (const s of toInject) {
      output += `• ${s.name} (${s.layer}) - ${s.reason}\n`;
    }
    output += '</skill-activation>\n';

    // Track injected
    const session = loadSessionSkills();
    toInject.forEach(s => session.add(s.name));
    saveSessionSkills(session);
  }

  if (toSuggest.length > 0) {
    output += '\n<skill-suggestions>\n';
    output += `💡 Suggested: `;
    output += toSuggest.map(s => `/${s.name}`).join(', ');
    output += '\n</skill-suggestions>\n';
  }

  return output;
}

// ============ Hook Entry Point ============

async function hook(context) {
  const { prompt } = context;
  if (!prompt || prompt.trim().length < 5) {
    return { additionalContext: '' };
  }

  try {
    const results = await analyzePrompt(prompt);
    if (results.length === 0) {
      return { additionalContext: '' };
    }
    return { additionalContext: generateInjection(results) };
  } catch (e) {
    return { additionalContext: '' };
  }
}

module.exports = hook;

// ============ CLI ============

if (require.main === module) {
  const args = process.argv.slice(2);

  if (args[0] === '--hook') {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => input += chunk);
    process.stdin.on('end', async () => {
      try {
        const data = JSON.parse(input);
        const result = await hook(data);
        console.log(JSON.stringify(result));
      } catch {
        console.log(JSON.stringify({ additionalContext: '' }));
      }
    });
    return;
  }

  if (args[0] === '--analyze') {
    const prompt = args.slice(1).join(' ');
    analyzePrompt(prompt).then(results => {
      console.log(JSON.stringify(results, null, 2));
    });
    return;
  }

  // Test mode
  const testPrompts = [
    "Help me debug this error",
    "I want to write tests for this function",
    "Let's brainstorm a new feature",
    "Create a checkpoint",
    "Something is broken and I don't know why"
  ];

  console.log('=== Skill Activator v2 Test ===\n');
  console.log(`Haiku: ${CONFIG.useHaiku && process.env.ANTHROPIC_API_KEY ? 'enabled' : 'disabled (fallback)'}\n`);

  (async () => {
    for (const prompt of testPrompts) {
      console.log(`"${prompt}"`);
      const results = await analyzePrompt(prompt);
      if (results.length === 0) {
        console.log('  No matches\n');
      } else {
        for (const r of results.slice(0, 3)) {
          console.log(`  ${r.action.toUpperCase()}: ${r.name} (${r.score}) [${r.source}] - ${r.reason}`);
        }
        console.log('');
      }
    }
  })();
}
