# Cat-Catch Enhanced: Modern Media Capture Extension

## Executive Summary

This plan outlines the development of **Cat-Catch Enhanced**, a next-generation Chrome extension for media resource capture, built on the foundation of [xifangczy/cat-catch](https://github.com/xifangczy/cat-catch). We leverage insights from:
- **Fluent-M3U8** - Modern UI/UX patterns and service architecture
- **N_m3u8DL-RE** - Professional-grade download engine features
- **517 GitHub Issues** - Real user pain points and feature requests

---

## Part 0: Research & Analysis Summary

### 0.1 Your CRX Analysis (v2.6.5)

**Files Analyzed:**
- `cat-catch-2.6.5-chrome.crx` - Chrome Web Store version
- `cat-catch-2.6.5.crx` - Standard version (includes Firefox manifest)

| Aspect | Your v2.6.5 | Latest GitHub |
|--------|-------------|---------------|
| Manifest Version | V3 | V3 |
| Min Chrome | 93 | 93 |
| Total JS Lines | ~11,192 | ~11,195 |
| Structure | Modern | Same |

**Key Finding:** Your v2.6.5 contains modern, up-to-date code with all current features.

### 0.2 Fluent-M3U8 Analysis

**What It Is:** A Python/Qt desktop GUI wrapper around N_m3u8DL-RE + FFmpeg.

**Architecture We Adopt:**
```
Fluent-M3U8 Service Pattern → Our TypeScript Modules
├── download_task_service.py  →  DownloadManager.ts
├── m3u8dl_service.py         →  StreamParser.ts
├── ffmpeg_service.py         →  MediaProcessor.ts
├── speed_service.py          →  SpeedTracker.ts
└── version_service.py        →  UpdateChecker.ts
```

**UI Patterns We Adopt:**
- Sidebar navigation with Home/Task/Settings
- System tray-like behavior (minimize to background)
- Task queue with real-time progress
- SQL-backed persistence (→ IndexedDB for us)

### 0.3 N_m3u8DL-RE Analysis

**What It Is:** Professional C# CLI stream downloader - the gold standard.

**Features We Port to Browser:**

| N_m3u8DL-RE Feature | Browser Implementation |
|---------------------|----------------------|
| `SimpleDownloadManager` | `DownloadManager.ts` with IndexedDB |
| `SpeedContainer` | `SpeedTracker.ts` with performance API |
| `AESUtil` (AES-128) | Web Crypto API |
| `ChaCha20Util` | libsodium.js WASM |
| `HLSExtractor` | Enhanced `M3U8Parser.ts` |
| `ContentProcessor` | `SiteProcessor` plugin system |
| Parallel downloads | `Promise.all` with concurrency limit |
| Retry with backoff | Exponential backoff utility |

**Protocol Support Expansion:**

| Protocol | Current Cat-Catch | Enhanced |
|----------|-------------------|----------|
| HLS (M3U8) | ✅ Full | ✅ Keep |
| DASH (MPD) | ✅ Basic | ✅ Improve |
| MSS (ISM) | ❌ None | ✅ Add |
| Live Streams | ⚠️ Limited | ✅ Real-time merge |

**Encryption Support Expansion:**

| Encryption | Current | Enhanced |
|------------|---------|----------|
| AES-128-CBC | ✅ | ✅ Keep |
| AES-128-ECB | ❌ | ✅ Add |
| ChaCha20 | ❌ | ✅ Add |
| SAMPLE-AES | ❌ | ✅ Add |

### 0.4 GitHub Issues Analysis (517 Open Issues)

**Top User Pain Points:**

| Issue | Problem | Impact | Our Solution |
|-------|---------|--------|--------------|
| #635, #878 | Data loss on page refresh | HIGH | IndexedDB persistence + resume |
| #891, #888 | M3U8 parse failures | HIGH | Enhanced parser with error recovery |
| #877 | Large files (4GB+) wrong format | HIGH | Chunked downloads + MIME handling |
| #399, #201 | FFmpeg service dependency | HIGH | Local FFmpeg.wasm |
| #509 | Infinite retry loops | MEDIUM | Exponential backoff |
| #881 | Extension breaks Discord | MEDIUM | Better site filtering |

**Top Feature Requests:**

| Issue | Request | Our Response |
|-------|---------|--------------|
| #750 | Userscript version (anti-censorship) | Consider for v2 |
| #635 | Desktop app | Companion app option |
| #890 | Firefox sidebar | ✅ Implement |
| #563, #569 | Custom filename templates | ✅ Implement |
| #508 | Auto-save at size threshold | ✅ Implement |
| #470 | Ad segment filtering | ✅ Implement |
| #423 | Thumbnail previews | ✅ Implement |
| #288 | Selective segment downloads | ✅ Implement |

**Platform Issues (Intentionally Limited):**
- YouTube: Legal/policy restrictions
- Douyin: Blocked by default in code
- Various: Anti-scraping measures

---

## Part 1: Current Implementation Analysis

### Architecture (cat-catch v2.6.5)

| Component | Technology | Lines |
|-----------|------------|-------|
| Background Service Worker | Vanilla JS | ~893 |
| Popup UI | jQuery + HTML | ~1,071 |
| Content Scripts | Vanilla JS | ~273 |
| M3U8 Parser | HLS.js + Custom | ~1,940 |
| Deep Search | Proxy Interception | ~791 |
| **Total** | Mixed | **~11,192** |

### Current Strengths
- Comprehensive media capture (HLS, DASH, WebRTC, MediaSource)
- Cross-browser support (Chrome, Firefox, Edge)
- Deep search with 15+ JS API hooks
- Extensive configuration options
- Multi-language support (7 languages)
- Existing integrations (Aria2, MQTT, m3u8DL-RE)

### Current Limitations (From Issue Analysis)
1. **Reliability**: Data lost on refresh, silent failures, infinite loops
2. **Dependencies**: External FFmpeg service can fail
3. **Performance**: No connection pooling, basic retry logic
4. **UI/UX**: jQuery-based, no real-time progress feedback
5. **Storage**: 5MB chrome.storage limit
6. **Type Safety**: No TypeScript, runtime errors

---

## Part 2: Technology Stack

### Core Framework: **TypeScript + React 18**
- Type safety catches bugs at compile time
- React's component model fits extension UIs
- Modern hooks enable clean state management

### Build System: **Vite + CRXJS**
- Lightning-fast HMR during development
- Native ESM support
- CRXJS handles manifest generation
- Tree-shaking reduces bundle size

### State Management: **Zustand + Immer**
- Lightweight (~1KB) vs Redux (~7KB)
- Cross-context state sync for extensions
- Immer for immutable updates

### UI Framework: **Tailwind CSS + shadcn/ui**
- Utility-first CSS, minimal output
- Accessible, customizable components
- Dark mode built-in
- Fluent-inspired design system

### Storage: **IndexedDB via Dexie.js**
- 50MB+ storage vs 5MB limit
- Survives page refreshes (user pain point #1)
- Structured queries and indexing

### Media Processing: **FFmpeg.wasm**
- No external service dependency (user pain point #2)
- Local segment merging
- Format conversion
- Thumbnail generation

### Encryption: **Web Crypto API + libsodium.js**
- AES-128-CBC/ECB via SubtleCrypto
- ChaCha20 via libsodium WASM
- SAMPLE-AES support

### Testing: **Vitest + Playwright**
- Vite-native, fast execution
- E2E extension testing
- Jest-compatible API

---

## Part 3: Enhanced Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CAT-CATCH ENHANCED                               │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Popup     │  │   Options   │  │  Side Panel │  │  Offscreen  │    │
│  │   (React)   │  │   (React)   │  │   (React)   │  │  (FFmpeg)   │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         │                │                │                │            │
│         └────────────────┴────────────────┴────────────────┘            │
│                                   │                                      │
│                          Chrome Message Bus                              │
│                                   │                                      │
│  ┌────────────────────────────────┴────────────────────────────────┐    │
│  │                    SERVICE WORKER (TypeScript)                   │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │    │
│  │  │ CaptureEngine │  │ DownloadMgr   │  │ StateManager  │        │    │
│  │  │  - Network    │  │  - Queue      │  │  - Zustand    │        │    │
│  │  │  - DeepSearch │  │  - Retry      │  │  - IndexedDB  │        │    │
│  │  │  - WebRTC     │  │  - Speed      │  │  - Sync       │        │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘        │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │    │
│  │  │ StreamParser  │  │ SiteProcessor │  │ CryptoEngine  │        │    │
│  │  │  - M3U8       │  │  - Vimeo      │  │  - AES-128    │        │    │
│  │  │  - MPD        │  │  - Custom     │  │  - ChaCha20   │        │    │
│  │  │  - ISM (new)  │  │  - Plugins    │  │  - Keys       │        │    │
│  │  └───────────────┘  └───────────────┘  └───────────────┘        │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                   │                                      │
│  ┌────────────────────────────────┴────────────────────────────────┐    │
│  │                    CONTENT SCRIPTS (TypeScript)                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ MediaDetector│  │ DOMObserver  │  │ OverlayUI    │           │    │
│  │  │  - Video     │  │  - Mutation  │  │  - Controls  │           │    │
│  │  │  - Audio     │  │  - Intersect │  │  - Progress  │           │    │
│  │  │  - Canvas    │  │  - Shadow    │  │  - Download  │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                   │                                      │
│  ┌────────────────────────────────┴────────────────────────────────┐    │
│  │                    INJECTED SCRIPTS (TypeScript)                 │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ DeepSearch   │  │ StreamHook   │  │ WebRTCHook   │           │    │
│  │  │  - JSON.parse│  │  - MediaSrc  │  │  - RTCPeer   │           │    │
│  │  │  - XHR/Fetch │  │  - SourceBuf │  │  - MediaStrm │           │    │
│  │  │  - WebSocket │  │  - Response  │  │  - DataChan  │           │    │
│  │  │  - Worker    │  │  - Blob      │  │  - Recording │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                   │                                      │
│  ┌────────────────────────────────┴────────────────────────────────┐    │
│  │                    DATA LAYER (IndexedDB/Dexie)                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │    │
│  │  │ Resources DB │  │ Downloads DB │  │ Settings DB  │           │    │
│  │  │  - Captured  │  │  - Queue     │  │  - Profiles  │           │    │
│  │  │  - Metadata  │  │  - History   │  │  - Rules     │           │    │
│  │  │  - Thumbnails│  │  - Segments  │  │  - Filters   │           │    │
│  │  │  - Keys      │  │  - Resume    │  │  - Templates │           │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘           │    │
│  └─────────────────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────────┤
│                    OPTIONAL: COMPANION APP                               │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Local service receiving URLs via localhost webhook              │    │
│  │  - Spawns N_m3u8DL-RE for advanced downloads                    │    │
│  │  - Full FFmpeg binary for complex operations                     │    │
│  │  - Reports progress back to extension                            │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Module Structure

```
cat-catch-enhanced/
├── src/
│   ├── background/                    # Service Worker
│   │   ├── index.ts                   # Entry point
│   │   ├── capture/                   # Capture engines
│   │   │   ├── NetworkCapture.ts      # webRequest interception
│   │   │   ├── DeepSearchCapture.ts   # JSON/Fetch/XHR hooks
│   │   │   ├── WebRTCCapture.ts       # WebRTC stream capture
│   │   │   └── MediaSourceCapture.ts  # MediaSource API hooks
│   │   ├── download/                  # Download management (from N_m3u8DL-RE patterns)
│   │   │   ├── DownloadManager.ts     # Queue, retry, progress
│   │   │   ├── SegmentDownloader.ts   # HLS/DASH segments
│   │   │   ├── SpeedTracker.ts        # Bandwidth monitoring
│   │   │   ├── RetryHandler.ts        # Exponential backoff
│   │   │   └── ConnectionPool.ts      # HTTP connection reuse
│   │   ├── parsers/                   # Media format parsers
│   │   │   ├── M3U8Parser.ts          # HLS manifests (enhanced)
│   │   │   ├── MPDParser.ts           # DASH manifests
│   │   │   ├── ISMParser.ts           # Smooth Streaming (NEW)
│   │   │   └── MediaInfoParser.ts     # File metadata
│   │   ├── crypto/                    # Encryption (from N_m3u8DL-RE)
│   │   │   ├── AESDecryptor.ts        # AES-128-CBC/ECB
│   │   │   ├── ChaCha20Decryptor.ts   # ChaCha20 (NEW)
│   │   │   └── KeyManager.ts          # Key detection & storage
│   │   ├── processors/                # Site-specific (from N_m3u8DL-RE)
│   │   │   ├── ProcessorInterface.ts  # Base interface
│   │   │   ├── VimeoProcessor.ts      # Vimeo JSON → M3U8
│   │   │   ├── AdFilterProcessor.ts   # Ad segment removal
│   │   │   └── index.ts               # Processor registry
│   │   └── state/                     # State management
│   │       ├── store.ts               # Zustand store
│   │       └── persist.ts             # IndexedDB persistence
│   │
│   ├── content/                       # Content scripts
│   │   ├── index.ts                   # Entry point
│   │   ├── MediaDetector.ts           # Find media elements
│   │   ├── OverlayUI.tsx              # In-page controls
│   │   └── bridge.ts                  # Page <-> Content bridge
│   │
│   ├── inject/                        # Injected page scripts
│   │   ├── deepSearch.ts              # JSON.parse hooks (15+ APIs)
│   │   ├── streamHooks.ts             # MediaSource/SourceBuffer
│   │   └── webrtcHooks.ts             # RTCPeerConnection
│   │
│   ├── popup/                         # Popup UI (React) - Fluent-inspired
│   │   ├── App.tsx                    # Root component
│   │   ├── components/
│   │   │   ├── ResourceList.tsx       # Captured resources
│   │   │   ├── ResourceCard.tsx       # Single resource with thumbnail
│   │   │   ├── FilterBar.tsx          # Search/filter
│   │   │   ├── DownloadQueue.tsx      # Active downloads with progress
│   │   │   ├── SpeedIndicator.tsx     # Real-time speed display
│   │   │   └── QuickActions.tsx       # Common actions
│   │   ├── hooks/
│   │   │   ├── useResources.ts        # Resource state
│   │   │   ├── useDownloads.ts        # Download state
│   │   │   └── useSpeed.ts            # Speed tracking
│   │   └── styles/
│   │
│   ├── options/                       # Options UI (React)
│   │   ├── App.tsx
│   │   ├── pages/
│   │   │   ├── General.tsx            # General settings
│   │   │   ├── Capture.tsx            # Capture rules
│   │   │   ├── Download.tsx           # Download settings
│   │   │   ├── Templates.tsx          # Filename templates (NEW)
│   │   │   ├── Integrations.tsx       # N_m3u8DL-RE, Aria2, etc.
│   │   │   ├── Advanced.tsx           # Advanced options
│   │   │   └── About.tsx              # About/credits
│   │   └── components/
│   │
│   ├── sidepanel/                     # Side Panel UI (React)
│   │   └── App.tsx                    # Full-featured panel
│   │
│   ├── offscreen/                     # Offscreen document
│   │   ├── index.ts                   # Entry point
│   │   ├── FFmpegProcessor.ts         # FFmpeg.wasm operations
│   │   └── ThumbnailGenerator.ts      # Video frame extraction
│   │
│   ├── shared/                        # Shared code
│   │   ├── types/
│   │   │   ├── resource.ts            # Resource interfaces
│   │   │   ├── download.ts            # Download interfaces
│   │   │   ├── settings.ts            # Settings interfaces
│   │   │   ├── stream.ts              # Stream/variant interfaces
│   │   │   └── messages.ts            # Message types
│   │   ├── utils/
│   │   │   ├── url.ts                 # URL manipulation
│   │   │   ├── format.ts              # Size/time formatting
│   │   │   ├── filename.ts            # Filename template system
│   │   │   ├── retry.ts               # Retry with backoff
│   │   │   └── crypto.ts              # Encryption helpers
│   │   ├── constants/
│   │   │   ├── mimeTypes.ts           # MIME type mappings
│   │   │   ├── extensions.ts          # File extensions
│   │   │   ├── templates.ts           # Filename template vars
│   │   │   └── defaults.ts            # Default settings
│   │   └── db/                        # Database layer
│   │       ├── index.ts               # Dexie setup
│   │       ├── resources.ts           # Resources table
│   │       ├── downloads.ts           # Downloads table
│   │       ├── segments.ts            # Segment state (for resume)
│   │       └── settings.ts            # Settings table
│   │
│   └── lib/                           # Third-party wrappers
│       ├── hls.ts                     # HLS.js wrapper
│       ├── ffmpeg.ts                  # FFmpeg.wasm wrapper
│       ├── sodium.ts                  # libsodium.js wrapper
│       └── streamSaver.ts             # StreamSaver wrapper
│
├── companion/                         # Optional companion app
│   ├── server.ts                      # Local HTTP server
│   ├── n_m3u8dl.ts                    # N_m3u8DL-RE spawner
│   └── progress.ts                    # Progress reporter
│
├── public/
│   ├── icons/
│   ├── _locales/                      # i18n (expand from 7 to 15+)
│   └── fonts/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── manifest.json
├── vite.config.ts
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

---

## Part 4: New & Enhanced Features

### 4.1 Robust Download Manager (From N_m3u8DL-RE)

**Solving:** Issues #509 (infinite loops), #635 (data loss), #399 (service failures)

```typescript
interface DownloadJob {
  id: string;
  resourceId: string;
  status: 'queued' | 'downloading' | 'paused' | 'merging' | 'completed' | 'failed';
  progress: number;           // 0-100
  speed: number;              // bytes/sec (real-time)
  eta: number;                // seconds remaining
  segments: SegmentStatus[];  // For HLS/DASH - enables resume
  retries: number;
  maxRetries: number;
  error?: string;
  createdAt: number;
  completedAt?: number;
}

class DownloadManager {
  private queue: PriorityQueue<DownloadJob>;
  private activeDownloads: Map<string, DownloadWorker>;
  private speedTracker: SpeedTracker;
  private connectionPool: ConnectionPool;

  // Configurable limits
  maxConcurrent: number = 3;
  maxRetries: number = 5;
  retryDelayBase: number = 1000; // Exponential backoff
  speedCheckInterval: number = 500;

  // Core operations
  async enqueue(resource: Resource, options?: DownloadOptions): Promise<string>;
  async pause(jobId: string): Promise<void>;
  async resume(jobId: string): Promise<void>;  // Resume from IndexedDB state
  async cancel(jobId: string): Promise<void>;
  async prioritize(jobId: string): Promise<void>;

  // Batch operations
  async pauseAll(): Promise<void>;
  async resumeAll(): Promise<void>;
  async cancelAll(): Promise<void>;

  // Events for UI
  onProgress: (job: DownloadJob) => void;
  onComplete: (job: DownloadJob) => void;
  onError: (job: DownloadJob, error: Error) => void;
  onSpeedUpdate: (speed: number) => void;
}

// Speed tracking (from N_m3u8DL-RE SpeedContainer)
class SpeedTracker {
  private samples: number[] = [];
  private sampleWindow: number = 10;

  recordBytes(bytes: number): void;
  getCurrentSpeed(): number;  // bytes/sec
  getAverageSpeed(): number;
  getETA(remaining: number): number;
  shouldStop(): boolean;  // For speed limit enforcement
}
```

### 4.2 Enhanced Stream Parsers (From N_m3u8DL-RE)

**Solving:** Issues #891, #888 (M3U8 parse failures)

```typescript
// M3U8 Parser with N_m3u8DL-RE features
class M3U8Parser {
  // Master playlist handling
  parseMaster(content: string, baseUrl: string): MasterPlaylist;

  // Media playlist with all edge cases
  parseMedia(content: string, baseUrl: string): MediaPlaylist;

  // Advanced features from N_m3u8DL-RE
  features: {
    discontinuityHandling: boolean;   // Group segments by encoding
    liveStreamSupport: boolean;       // Calculate refresh intervals
    adSegmentRemoval: boolean;        // Pattern-based filtering
    multipleEXTXMAP: boolean;         // Multiple init segments
    byteRangeSupport: boolean;        // Partial segment requests
  };

  // Encryption info extraction
  extractKeyInfo(playlist: MediaPlaylist): KeyInfo[];

  // Quality selection
  selectBestVariant(
    master: MasterPlaylist,
    preferences: QualityPreferences
  ): StreamVariant;
}

// NEW: ISM/Smooth Streaming Parser
class ISMParser {
  parse(content: string, baseUrl: string): SmoothStreamingManifest;
  extractTracks(): Track[];
  buildSegmentUrls(track: Track): string[];
}
```

### 4.3 Expanded Encryption Support (From N_m3u8DL-RE)

```typescript
// Encryption engine supporting all N_m3u8DL-RE methods
class CryptoEngine {
  // AES-128-CBC (existing)
  async decryptAES128CBC(
    data: ArrayBuffer,
    key: ArrayBuffer,
    iv: ArrayBuffer
  ): Promise<ArrayBuffer>;

  // AES-128-ECB (NEW)
  async decryptAES128ECB(
    data: ArrayBuffer,
    key: ArrayBuffer
  ): Promise<ArrayBuffer>;

  // ChaCha20 (NEW - from N_m3u8DL-RE)
  async decryptChaCha20(
    data: ArrayBuffer,
    key: ArrayBuffer,  // 32 bytes
    nonce: ArrayBuffer // 12 bytes
  ): Promise<ArrayBuffer>;

  // SAMPLE-AES (NEW - partial encryption)
  async decryptSampleAES(
    data: ArrayBuffer,
    key: ArrayBuffer,
    iv: ArrayBuffer
  ): Promise<ArrayBuffer>;

  // Key detection (enhanced from current search.js)
  detectKey(data: any): DetectedKey | null;
}

// Key management with persistence
class KeyManager {
  private keys: Map<string, StoredKey>;

  async storeKey(key: DetectedKey): Promise<void>;
  async getKey(keyId: string): Promise<StoredKey | null>;
  async getAllKeys(): Promise<StoredKey[]>;

  // Auto-match keys to streams
  findMatchingKey(stream: StreamInfo): StoredKey | null;
}
```

### 4.4 Site-Specific Processors (From N_m3u8DL-RE)

**Solving:** Various platform-specific issues

```typescript
// Plugin architecture from N_m3u8DL-RE
interface ContentProcessor {
  name: string;

  // Determine if this processor handles the content
  canProcess(context: ProcessorContext): boolean;

  // Transform the content/URL
  process(content: string, context: ProcessorContext): string;
}

interface ProcessorContext {
  extractorType: 'HLS' | 'DASH' | 'ISM';
  url: string;
  domain: string;
  headers: Record<string, string>;
}

// Built-in processors
class VimeoProcessor implements ContentProcessor {
  name = 'Vimeo';
  canProcess(ctx) { return ctx.url.includes('vimeo'); }
  process(content) { /* JSON → M3U8 conversion */ }
}

class AdFilterProcessor implements ContentProcessor {
  name = 'AdFilter';
  patterns: RegExp[] = [
    /\/ads?\//i,
    /doubleclick/i,
    /googlesyndication/i,
  ];
  process(content) { /* Remove ad segments */ }
}

// Processor registry
class ProcessorRegistry {
  private processors: ContentProcessor[] = [];

  register(processor: ContentProcessor): void;
  unregister(name: string): void;
  process(content: string, context: ProcessorContext): string;
}
```

### 4.5 Filename Template System (User Request #563, #569)

```typescript
// Rich filename templates like N_m3u8DL-RE
interface FilenameTemplate {
  template: string;
  variables: TemplateVariable[];
}

type TemplateVariable =
  | '${title}'        // Page/video title
  | '${domain}'       // Source domain
  | '${date}'         // YYYY-MM-DD
  | '${time}'         // HH-MM-SS
  | '${resolution}'   // 1920x1080
  | '${quality}'      // 1080p
  | '${bandwidth}'    // Bitrate
  | '${codec}'        // h264, vp9, etc.
  | '${language}'     // Audio language
  | '${index}'        // Sequential number
  | '${ext}'          // File extension
  | '${custom:name}'; // User-defined

// Examples:
// "${title}_${resolution}_${date}.${ext}"
// → "My Video_1920x1080_2025-01-15.mp4"

// "${domain}/${title}/${quality}.${ext}"
// → "youtube.com/My Video/1080p.mp4"

function renderFilename(
  template: string,
  context: FilenameContext
): string;
```

### 4.6 Local FFmpeg.wasm (Solving Issue #399, #201)

**Solving:** External service dependency

```typescript
// FFmpeg.wasm in offscreen document (no external service!)
class FFmpegProcessor {
  private ffmpeg: FFmpeg;
  private loaded: boolean = false;

  async init(): Promise<void>;

  // Segment merging (replaces online service)
  async mergeSegments(
    segments: Blob[],
    format: 'mp4' | 'mkv' | 'webm',
    options?: MergeOptions
  ): Promise<Blob>;

  // Format conversion
  async transcode(
    input: Blob,
    outputFormat: string,
    options?: TranscodeOptions
  ): Promise<Blob>;

  // Audio extraction
  async extractAudio(
    video: Blob,
    format: 'mp3' | 'aac' | 'opus'
  ): Promise<Blob>;

  // Subtitle embedding
  async embedSubtitles(
    video: Blob,
    subtitles: SubtitleTrack[]
  ): Promise<Blob>;

  // Thumbnail generation (User request #423)
  async generateThumbnail(
    video: Blob,
    timestamp: number
  ): Promise<Blob>;

  // Progress callback
  onProgress: (progress: number) => void;

  // Memory management
  async cleanup(): Promise<void>;
}
```

### 4.7 Modern UI/UX (Fluent-Inspired)

**Popup Features:**
- Real-time resource list with live updates
- Thumbnail previews (lazy loaded)
- Download progress with speed indicator
- Quick filters (video/audio/playlist/other)
- Dark/light theme with system preference
- Keyboard shortcuts (j/k navigation, Enter download)

**Side Panel Features (Including Firefox #890):**
- Full-featured media browser
- Multi-tab resource aggregation
- Advanced filtering and sorting
- Batch operations
- Download history with resume
- Settings quick access

**Options Page Features:**
- Organized settings categories
- Live preview of changes
- Import/export configuration
- Profile management
- Filename template builder
- Rule editor with visual builder

---

## Part 5: Implementation Phases

### Phase 1: Foundation
**Focus:** Project setup, core infrastructure

**Tasks:**
1. Set up Vite + CRXJS + TypeScript project
2. Configure Tailwind CSS + shadcn/ui
3. Implement IndexedDB layer with Dexie
4. Create Zustand store with persistence
5. Set up message passing infrastructure
6. Basic service worker lifecycle
7. Port manifest.json to enhanced MV3

**Deliverables:**
- Working extension shell
- IndexedDB storing/retrieving data
- Cross-context state sync working

### Phase 2: Capture Engine
**Focus:** Network interception, resource detection

**Tasks:**
1. Port NetworkCapture from background.js
2. Implement CaptureRule system
3. Add MIME type detection
4. URL pattern matching with regex
5. Set-based deduplication
6. Request header capture
7. Resource metadata extraction

**Deliverables:**
- Network requests captured
- Resources stored in IndexedDB
- Basic filtering functional

### Phase 3: Stream Parsers
**Focus:** M3U8, MPD, ISM parsing

**Tasks:**
1. Rewrite M3U8Parser with N_m3u8DL-RE features
2. Enhance MPDParser
3. Implement ISMParser (NEW)
4. Add variant/quality selection
5. Key extraction
6. Subtitle track parsing
7. Ad segment detection

**Deliverables:**
- All stream formats parsing
- Quality selection working
- Encrypted streams detected

### Phase 4: Download Manager
**Focus:** Robust downloading with resume

**Tasks:**
1. Implement DownloadManager class
2. Priority queue with IndexedDB persistence
3. Segment downloader with connection pooling
4. SpeedTracker implementation
5. Retry with exponential backoff
6. Pause/resume with state persistence
7. Progress tracking

**Deliverables:**
- Downloads survive page refresh
- Pause/resume working
- Real-time progress and speed

### Phase 5: Encryption & Processing
**Focus:** Decryption, FFmpeg integration

**Tasks:**
1. Implement CryptoEngine (AES, ChaCha20)
2. KeyManager with persistence
3. Set up FFmpeg.wasm in offscreen document
4. Segment merging
5. Thumbnail generation
6. Format conversion
7. Subtitle embedding

**Deliverables:**
- Encrypted streams decryptable
- Local merging (no external service)
- Thumbnails generating

### Phase 6: Deep Search & Hooks
**Focus:** JavaScript API interception

**Tasks:**
1. Port all 15+ hooks from search.js
2. TypeScript rewrite with better detection
3. Worker hook enhancement
4. WebSocket hook
5. URL classification
6. Confidence scoring
7. Real-time result streaming

**Deliverables:**
- All hooks working
- Hidden URLs detected
- Keys extracted

### Phase 7: Site Processors
**Focus:** Plugin system for site-specific handling

**Tasks:**
1. Implement ProcessorRegistry
2. Port VimeoProcessor
3. Create AdFilterProcessor
4. Add more site processors as needed
5. User-customizable processors
6. Processor enable/disable UI

**Deliverables:**
- Plugin architecture working
- Vimeo, ad filtering functional
- Extensible for future sites

### Phase 8: UI/UX Implementation
**Focus:** Modern React UI

**Tasks:**
1. Popup with resource list, progress
2. Side panel (Chrome + Firefox)
3. Options page with all settings
4. Filename template builder
5. Rule editor
6. Theme system
7. Keyboard shortcuts
8. Accessibility

**Deliverables:**
- Beautiful, responsive UI
- All features accessible
- Keyboard navigation

### Phase 9: Integrations
**Focus:** External tool support

**Tasks:**
1. Enhanced N_m3u8DL-RE command generation
2. Aria2 RPC improvements
3. MQTT publishing
4. send2local webhook
5. Optional companion app
6. Import/export settings

**Deliverables:**
- All integrations working
- Companion app optional

### Phase 10: Testing & Release
**Focus:** Quality assurance, documentation

**Tasks:**
1. Unit tests for all modules
2. Integration tests
3. E2E tests with Playwright
4. Performance profiling
5. Cross-browser testing
6. Security audit
7. Documentation
8. Store submission

**Deliverables:**
- 80%+ test coverage
- Performance benchmarks met
- Store listings live

---

## Part 6: Technical Specifications

### Performance Targets

| Metric | Current | Target | Method |
|--------|---------|--------|--------|
| Popup Load Time | ~500ms | <100ms | Code splitting, lazy load |
| Resource Dedup | O(n) | O(1) | Set-based lookup |
| Memory Usage | ~50MB | <30MB | Efficient data structures |
| Bundle Size | ~1.5MB | <500KB | Tree-shaking, compression |
| HLS Download Speed | 1x | 3x | Connection pooling |
| Resume After Crash | ❌ | ✅ | IndexedDB state |

### Browser Support

| Browser | Minimum Version | Notes |
|---------|-----------------|-------|
| Chrome | 116+ | Full features |
| Edge | 116+ | Full features |
| Firefox | 115+ | Side panel, slightly different APIs |
| Brave | 1.57+ | Full features |
| Opera | 102+ | Full features |

### Security Measures

1. **Content Security Policy**: Strict CSP in manifest
2. **Data Encryption**: AES-256 for stored credentials
3. **URL Sanitization**: All URLs validated before use
4. **Permissions**: Minimal required permissions
5. **Audit Logging**: Optional activity logging
6. **No External Dependencies**: FFmpeg local, no remote services

---

## Part 7: Addressing User Issues

### Direct Solutions for Top Issues

| Issue | Problem | Solution |
|-------|---------|----------|
| #635 | Data lost on refresh | IndexedDB persistence + auto-save |
| #509 | Infinite retry loops | Exponential backoff with max retries |
| #399 | FFmpeg service down | Local FFmpeg.wasm |
| #891 | M3U8 parse failures | Enhanced parser with error recovery |
| #877 | Large files wrong format | Proper MIME handling + chunking |
| #881 | Breaks Discord | Improved site filtering |
| #890 | No Firefox sidebar | Firefox side panel support |
| #563 | Filename customization | Full template system |
| #423 | No thumbnails | FFmpeg.wasm thumbnail generation |
| #470 | Ads in downloads | Ad segment filter processor |

### Feature Requests Implemented

| Issue | Request | Implementation |
|-------|---------|----------------|
| #563, #569 | Custom filenames | Template system with variables |
| #508 | Auto-save threshold | Configurable size limit |
| #288 | Selective segments | Segment picker UI |
| #423 | Thumbnails | FFmpeg.wasm frame extraction |
| #470 | Ad removal | Pattern-based segment filtering |
| #890 | Firefox sidebar | Cross-browser side panel |

---

## Part 8: Summary

### What We're Building

**Cat-Catch Enhanced** transforms the existing capable extension into a professional-grade tool by:

1. **Solving Real Problems**
   - No more data loss on refresh (IndexedDB)
   - No more external service failures (local FFmpeg)
   - No more infinite loops (proper retry logic)

2. **Adding Professional Features** (from N_m3u8DL-RE)
   - Connection pooling for 3x faster downloads
   - ChaCha20/SAMPLE-AES encryption
   - ISM/Smooth Streaming support
   - Site-specific processors
   - Rich filename templates

3. **Modern Architecture**
   - TypeScript for reliability
   - React for maintainable UI
   - IndexedDB for persistence
   - Plugin system for extensibility

4. **Better UX** (Fluent-inspired)
   - Real-time progress and speed
   - Thumbnail previews
   - Pause/resume downloads
   - Cross-browser side panel

### Key Differentiators

| Aspect | Original Cat-Catch | Cat-Catch Enhanced |
|--------|-------------------|-------------------|
| **Reliability** | Data can be lost | Survives crashes |
| **Dependencies** | External FFmpeg | Fully local |
| **Encryption** | AES-128 only | AES + ChaCha20 + SAMPLE-AES |
| **Protocols** | HLS, DASH | + ISM/Smooth Streaming |
| **Speed** | Sequential | 3x faster with pooling |
| **UI** | jQuery | Modern React |
| **Storage** | 5MB limit | 50MB+ IndexedDB |
| **Resume** | Not possible | Full resume support |

---

## Next Steps

Ready to proceed with implementation upon your approval. Please confirm:

1. **Priority order** for the 10 phases
2. **Must-have vs nice-to-have** features
3. **Target browsers** (Chrome-first or cross-browser)
4. **Distribution** (Web Store, self-hosted, or both)
5. **Companion app** (include or defer)

This plan addresses the 517 open issues, incorporates N_m3u8DL-RE's professional features, adopts Fluent-M3U8's UI patterns, and provides a solid foundation for a modern, reliable media capture extension.
