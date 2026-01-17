# Chrome Canary Experimental Flags - Quick Reference

## 🚀 Quick Start

I've set up Chrome Canary with command-line flags, but you need to manually enable the experimental features in `chrome://flags`.

### Launch Chrome with Enhanced Features
```bash
chrome-canary-ai
```

Or manually:
```bash
google-chrome-canary --enable-features=PromptAPIForGeminiNano,OptimizationGuideOnDeviceModel chrome://flags
```

---

## 📝 Flags to Enable Manually

Open `chrome://flags` in Chrome Canary and search for each flag:

### 🤖 AI & Machine Learning (Most Exciting!)

| Flag Name | Setting | Description |
|-----------|---------|-------------|
| `prompt-api-for-gemini-nano` | **Enabled** | ⭐⭐⭐ Gemini Nano on-device AI assistant |
| `optimization-guide-on-device-model` | **Enabled** | ⭐⭐⭐ Required for Gemini Nano (needs 22GB!) |

**After enabling AI flags:**
1. Go to `chrome://components`
2. Find "Optimization Guide On Device Model"
3. Click "Check for update"
4. Wait for 22GB model download
5. Requires: 4GB+ GPU VRAM

### ⚡ Performance

| Flag Name | Setting | Description |
|-----------|---------|-------------|
| `enable-parallel-downloading` | **Enabled** | ⭐⭐ Faster downloads via parallel connections |
| `enable-quic` | **Enabled** | ⭐⭐ QUIC protocol for lower latency |
| `enable-gpu-rasterization` | **Enabled** | ⭐⭐ GPU-accelerated rendering |
| `enable-zero-copy` | **Try it** | ⭐ Much faster but may crash (unstable!) |

### 🎨 UI/UX

| Flag Name | Setting | Description |
|-----------|---------|-------------|
| `enable-force-dark` | **Enabled** | ⭐⭐ Dark mode on all websites |
| `enable-reader-mode` | **Enabled** | ⭐ Distraction-free reading |
| `memory-saver-memory-usage-in-hovercards` | **Enabled** | ⭐ View tab memory usage on hover |
| Tab Groups improvements | **Search** | ⭐⭐ Enhanced tab organization |

### 🛠️ Developer

| Flag Name | Setting | Description |
|-----------|---------|-------------|
| `enable-experimental-web-platform-features` | **Enabled** | ⭐⭐⭐ Latest web APIs |
| `enable-javascript-harmony` | **Enabled** | ⭐⭐ Experimental JavaScript features |
| `chrome-labs` | **Enabled** | ⭐ Access experimental features menu |

### 🔒 Security

| Flag Name | Setting | Description |
|-----------|---------|-------------|
| Enhanced Safe Browsing | **Default** | Uses Gemini Nano to detect scams |

---

## 🎯 Step-by-Step Setup Guide

### 1. Enable Core Flags
```
chrome://flags
```
Search and enable:
- `prompt-api-for-gemini-nano`
- `optimization-guide-on-device-model`
- `enable-parallel-downloading`
- `enable-experimental-web-platform-features`

Click **"Relaunch"** button at bottom.

### 2. Download AI Model
```
chrome://components
```
- Find "Optimization Guide On Device Model"
- Click "Check for update"
- Wait for download (22GB, may take a while)

### 3. Test AI Features
Open DevTools Console (F12) and try:
```javascript
const session = await ai.assistant.create();
const result = await session.prompt("Hello, who are you?");
console.log(result);
```

### 4. Check GPU/WebGPU Support
```
chrome://gpu
```
Verify WebGPU is enabled for AI acceleration.

---

## 🔥 Most Exciting Features

### 1. **Gemini Nano Integration** ⭐⭐⭐
- On-device AI that runs locally
- No internet required after download
- Privacy-focused (data stays on device)
- Access via `window.ai` JavaScript API

### 2. **Agentic Browsing** (Coming Soon) ⭐⭐⭐
- Gemini can automate web tasks
- Book appointments, order food, shopping
- Look for "Contextual tasks" flag

### 3. **WebGPU & WebNN** ⭐⭐⭐
- Hardware-accelerated ML inference
- 20x faster than CPU for AI tasks
- Already enabled by default in Chrome 113+

### 4. **Nano Banana** (Experimental) ⭐⭐
- Generate images from browser search
- Transforms search bar to "Create image…"

### 5. **Deep Search** ⭐⭐
- AI-powered research assistant
- Cross-references multiple sources
- Generates structured reports

---

## ⚠️ Important Warnings

### ❌ Flags to AVOID
- `enable-zero-copy` - Fast but crashes frequently
- `disable-site-isolation` - Security vulnerability

### 💾 System Requirements for AI
- **Disk:** 22GB free space (for Gemini Nano model)
- **GPU:** 4GB+ VRAM required
- **RAM:** 8GB+ recommended
- **OS:** Linux, Windows 10/11, macOS 13+

### 🐛 Troubleshooting
- **Crashes?** Reset all flags: `chrome://flags` → "Reset all"
- **AI not working?** Check `chrome://components` for model status
- **Slow?** Disable `enable-zero-copy` if enabled

---

## 📚 Additional Resources

### Chrome URLs
- `chrome://flags` - Enable experimental features
- `chrome://components` - Download AI models
- `chrome://gpu` - Check GPU/WebGPU status
- `chrome://version` - Check Chrome version

### Useful Commands
```bash
# Launch with specific profile
chrome-canary-ai --user-data-dir=/tmp/chrome-test

# Launch with additional debugging
google-chrome-canary --enable-logging --v=1

# Check Chrome version
google-chrome-canary --version
```

### Key Flag Searches
- Search "AI" - All AI-related flags
- Search "experimental" - Latest features
- Search "performance" - Speed optimizations
- Search "webgpu" - Graphics acceleration

---

## 🎓 Learning Resources

### Testing AI Features
```javascript
// Check if AI is available
const canCreateSession = await ai.assistant.capabilities();
console.log('AI available:', canCreateSession);

// Create session with system prompt
const session = await ai.assistant.create({
  systemPrompt: "You are a helpful assistant."
});

// Streaming response
const stream = session.promptStreaming("Explain quantum computing");
for await (const chunk of stream) {
  console.log(chunk);
}
```

### WebGPU Test
```javascript
// Check WebGPU support
const adapter = await navigator.gpu?.requestAdapter();
console.log('WebGPU supported:', !!adapter);
```

---

## 📊 Flag Status Reference

✅ **Stable** - Works reliably  
🔄 **Experimental** - May have bugs  
⚠️ **Unstable** - Known to cause crashes  
🚀 **Coming Soon** - In development  
❌ **Deprecated** - Being removed

---

**Last Updated:** December 2024  
**Chrome Canary Version:** 145.0.7582.1

For the latest flags, always check `chrome://flags` directly as new features are added daily to Canary builds.
