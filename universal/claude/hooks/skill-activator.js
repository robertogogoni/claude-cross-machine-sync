/**
 * Skill Activator Hook
 *
 * Analyzes user prompts and auto-injects relevant skills based on:
 * 1. Keyword matching
 * 2. Pattern matching (regex)
 * 3. Fuzzy matching (fallback)
 *
 * Thresholds:
 * - Auto-inject: score > 0.65
 * - Suggest: score 0.50 - 0.65
 * - Ignore: score < 0.50
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  registryPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'skill-registry.json'),
  cachePath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'skill-cache.json'),
  sessionPath: path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'data', 'session-skills.json'),
  autoInjectThreshold: 0.65,
  suggestThreshold: 0.50,
  maxSuggestions: 3,
  cacheTTLMinutes: 60
};

// Load skill registry
function loadRegistry() {
  try {
    const data = fs.readFileSync(CONFIG.registryPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Failed to load skill registry:', error.message);
    return { skills: [] };
  }
}

// Load session tracking (prevents duplicate injections)
function loadSessionSkills() {
  try {
    const data = fs.readFileSync(CONFIG.sessionPath, 'utf8');
    const session = JSON.parse(data);
    // Check if session is still valid (same day)
    const today = new Date().toISOString().split('T')[0];
    if (session.date === today) {
      return new Set(session.skills);
    }
  } catch {
    // No session file or invalid
  }
  return new Set();
}

// Save session tracking
function saveSessionSkills(skills) {
  const session = {
    date: new Date().toISOString().split('T')[0],
    skills: Array.from(skills)
  };
  fs.writeFileSync(CONFIG.sessionPath, JSON.stringify(session, null, 2));
}

// Simple fuzzy match score (Levenshtein-based)
function fuzzyScore(str1, str2) {
  str1 = str1.toLowerCase();
  str2 = str2.toLowerCase();

  if (str1 === str2) return 1.0;
  if (str1.includes(str2) || str2.includes(str1)) return 0.8;

  // Simple character overlap ratio
  const chars1 = new Set(str1.split(''));
  const chars2 = new Set(str2.split(''));
  const intersection = new Set([...chars1].filter(x => chars2.has(x)));
  const union = new Set([...chars1, ...chars2]);

  return intersection.size / union.size;
}

// Calculate skill relevance score
function calculateScore(prompt, skill) {
  const promptLower = prompt.toLowerCase();
  let score = 0;
  let matches = [];

  // 1. Check keywords (2 points each)
  for (const keyword of skill.triggers.keywords || []) {
    if (promptLower.includes(keyword.toLowerCase())) {
      score += 0.15;
      matches.push(`keyword:${keyword}`);
    }
  }

  // 2. Check patterns (3 points each)
  for (const pattern of skill.triggers.patterns || []) {
    try {
      const regex = new RegExp(pattern, 'i');
      if (regex.test(promptLower)) {
        score += 0.2;
        matches.push(`pattern:${pattern}`);
      }
    } catch {
      // Invalid regex, skip
    }
  }

  // 3. Check intent phrases (4 points for fuzzy match > 0.7)
  for (const phrase of skill.triggers.intent_phrases || []) {
    const fuzzy = fuzzyScore(promptLower, phrase.toLowerCase());
    if (fuzzy > 0.6) {
      score += 0.25 * fuzzy;
      matches.push(`intent:${phrase}(${fuzzy.toFixed(2)})`);
    }
  }

  // 4. Check aliases (bonus)
  for (const alias of skill.aliases || []) {
    if (promptLower.includes(alias.toLowerCase())) {
      score += 0.1;
      matches.push(`alias:${alias}`);
    }
  }

  // 5. Apply confidence boost
  score += (skill.confidence_boost || 0);

  // Cap at 1.0
  score = Math.min(score, 1.0);

  return { score, matches };
}

// Main analysis function
function analyzePrompt(prompt) {
  const registry = loadRegistry();
  const sessionSkills = loadSessionSkills();
  const results = [];

  for (const skill of registry.skills) {
    // Skip already-injected skills
    if (sessionSkills.has(skill.name)) {
      continue;
    }

    const { score, matches } = calculateScore(prompt, skill);

    if (score >= CONFIG.suggestThreshold) {
      results.push({
        name: skill.name,
        layer: skill.layer,
        category: skill.category,
        score: parseFloat(score.toFixed(3)),
        matches,
        action: score >= CONFIG.autoInjectThreshold ? 'inject' : 'suggest'
      });
    }
  }

  // Sort by score descending
  results.sort((a, b) => b.score - a.score);

  return results;
}

// Generate context injection text
function generateInjection(results) {
  const toInject = results.filter(r => r.action === 'inject');
  const toSuggest = results.filter(r => r.action === 'suggest').slice(0, CONFIG.maxSuggestions);

  let injection = '';

  if (toInject.length > 0) {
    injection += '\n<skill-activation>\n';
    injection += `Auto-activated skills based on your prompt:\n`;
    for (const skill of toInject) {
      injection += `- ${skill.name} (${skill.layer} layer, score: ${skill.score})\n`;
    }
    injection += '</skill-activation>\n';

    // Track injected skills
    const sessionSkills = loadSessionSkills();
    for (const skill of toInject) {
      sessionSkills.add(skill.name);
    }
    saveSessionSkills(sessionSkills);
  }

  if (toSuggest.length > 0) {
    injection += '\n<skill-suggestions>\n';
    injection += `Suggested skills (use /skill-name to activate):\n`;
    for (const skill of toSuggest) {
      injection += `- /${skill.name} (score: ${skill.score})\n`;
    }
    injection += '</skill-suggestions>\n';
  }

  return injection;
}

// Hook entry point
async function hook(context) {
  const { prompt } = context;

  if (!prompt || prompt.trim().length < 5) {
    return { additionalContext: '' };
  }

  try {
    const results = analyzePrompt(prompt);

    if (results.length === 0) {
      return { additionalContext: '' };
    }

    const injection = generateInjection(results);

    // Log for debugging
    if (process.env.SKILL_DEBUG) {
      console.log('[Skill Activator]', JSON.stringify(results, null, 2));
    }

    return { additionalContext: injection };
  } catch (error) {
    console.error('[Skill Activator] Error:', error.message);
    return { additionalContext: '' };
  }
}

module.exports = hook;

// CLI modes
if (require.main === module) {
  const args = process.argv.slice(2);

  // Hook mode: read from stdin, output JSON
  if (args[0] === '--hook') {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => input += chunk);
    process.stdin.on('end', () => {
      try {
        const data = JSON.parse(input);
        const prompt = data.prompt || '';
        if (prompt.length < 5) {
          console.log(JSON.stringify({ additionalContext: '' }));
          return;
        }
        const results = analyzePrompt(prompt);
        const injection = generateInjection(results);
        console.log(JSON.stringify({ additionalContext: injection }));
      } catch (e) {
        console.log(JSON.stringify({ additionalContext: '' }));
      }
    });
    return;
  }

  // Analyze mode: single prompt from args
  if (args[0] === '--analyze') {
    const prompt = args.slice(1).join(' ');
    const results = analyzePrompt(prompt);
    const injection = generateInjection(results);
    console.log(JSON.stringify({ additionalContext: injection }));
    return;
  }

  // Test mode: run test prompts
  const testPrompts = [
    "Help me debug this error",
    "I want to write tests for this function",
    "Let's brainstorm a new feature",
    "Create a checkpoint",
    "Something is broken and I don't know why"
  ];

  console.log('=== Skill Activator Test ===\n');

  for (const prompt of testPrompts) {
    console.log(`Prompt: "${prompt}"`);
    const results = analyzePrompt(prompt);
    if (results.length === 0) {
      console.log('  No skills matched\n');
    } else {
      for (const r of results.slice(0, 3)) {
        console.log(`  ${r.action.toUpperCase()}: ${r.name} (${r.score}) [${r.matches.join(', ')}]`);
      }
      console.log('');
    }
  }
}
