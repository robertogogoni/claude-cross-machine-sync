# Chrome Canary Performance Tuning on Low-End Hardware

**Created**: 2026-03-18
**Hardware**: Intel HD 4400 (Haswell), i7-4510U, 8GB RAM, HDD

## Key Findings

### Field trials vs chrome://flags
Chrome Canary auto-enrolls in server-side experiments via `--field-trial-handle`. These appear in `--enable-features` on the process command line but are NOT in Preferences/chrome://flags. Override them with `--disable-features` in the flags conf file. The conf file takes precedence.

### Vulkan on Haswell = bad
Intel HD 4400 has marginal Vulkan support. MESA prints "Haswell Vulkan support is incomplete." OpenGL path is faster for this GPU. Disable Vulkan in Chrome flags.

### WebContentsForceDark is expensive
Forces CSS recalculation on every paint to invert colors. Use a lightweight dark mode extension (like Dark Reader) on specific sites instead, or rely on sites' native `prefers-color-scheme`.

### AI features are CPU hogs
HistoryEmbeddings spawns a TensorFlow Lite XNNPACK model in a utility process. On a 2C/4T CPU, this measurably impacts responsiveness. Disable HistoryEmbeddings, HistoryEmbeddingsAnswers, BrowsingHistoryActorIntegration M1/M2, and BrowsingHistorySimilarVisitsGrouping.

### GPU rasterization helps even on weak GPUs
`--enable-gpu-rasterization` offloads page painting from CPU to GPU. Even Intel HD 4400 handles this better than letting the CPU do it, freeing CPU for JavaScript execution.

### num-raster-threads should match logical cores
Default is 2. Setting to 4 (matching i7-4510U's 4 logical cores) improves page paint time.

### Extensions are the #1 controllable factor
46 extensions = 26 Chrome processes = 4.4 GB RAM. Each extension with `<all_urls>` content scripts adds overhead to every page load. Biggest wins come from disabling extensions that inject into all pages but are only needed occasionally (cat-catch, RSSHub Radar, Vercel).

## Scale factor separation
`--force-device-scale-factor` belongs in `chrome-canary-flags.conf` ONLY, not in `electron-flags.conf`. The latter applies to ALL Electron apps and breaks apps that expect native scaling (Claude Desktop rendered at 75% with grey padding).
