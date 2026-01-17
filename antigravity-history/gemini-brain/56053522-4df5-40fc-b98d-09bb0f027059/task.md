# Tasks

- [x] Phase 2: Capture Engine <!-- id: 13 -->
    - [x] Create `src/shared/constants/mimeTypes.ts` <!-- id: 14 -->
    - [x] Implement `NetworkCapture.ts` (port logic from `index.ts`) <!-- id: 15 -->
    - [x] Add CaptureRule Logic (MIME/URL filtering) <!-- id: 16 -->
    - [x] Refactor `src/background/index.ts` to use `NetworkCapture` <!-- id: 17 -->

- [x] Phase 3: Stream Parsers <!-- id: 23 -->
    - [x] Create `src/shared/types/stream.ts` <!-- id: 24 -->
    - [x] Implement `M3U8Parser.ts` <!-- id: 25 -->
    - [x] Implement `MPDParser.ts` <!-- id: 26 -->
    - [x] Implement `ISMParser.ts` <!-- id: 27 -->
    - [x] Create `ParserFactory.ts` <!-- id: 28 -->

- [x] Fix Immer Error <!-- id: 18 -->
    - [x] Analyze `src/shared/state/store.ts` <!-- id: 19 -->
    - [x] Reproduce or Identify the invalid state mutation <!-- id: 20 -->
    - [x] Fix the store action <!-- id: 21 -->
    - [x] Verify fix <!-- id: 22 -->

- [x] Phase 4: Download Manager <!-- id: 30 -->
    - [x] Create `src/background/download/SpeedTracker.ts` <!-- id: 31 -->
    - [x] Create `src/background/download/SegmentDownloader.ts` <!-- id: 32 -->
    - [x] Implement `src/background/download/DownloadManager.ts` <!-- id: 33 -->
    - [x] Integrate with `zustand` store (progress updates) <!-- id: 34 -->

- [x] Phase 5: Encryption & Processing <!-- id: 35 -->
    - [x] Implement `src/background/processing/KeyManager.ts` <!-- id: 36 -->
    - [x] Implement `src/background/processing/CryptoEngine.ts` <!-- id: 37 -->
    - [x] Set up Offscreen Document for FFmpeg <!-- id: 38 -->
    - [x] Implement `src/background/processing/FFmpegManager.ts` <!-- id: 39 -->
    - [x] Integrate decryption into `SegmentDownloader` <!-- id: 40 -->

- [x] Phase 6: UI Polishing & Merging Logic <!-- id: 41 -->
    - [x] Implement `MERGE_SEGMENTS` in `src/offscreen/main.ts` (Read from DB, FFmpeg concat) <!-- id: 42 -->
    - [x] Update `FFmpegManager` to trigger merge <!-- id: 43 -->
    - [x] Update `DownloadManager` to handle merging state and final file save <!-- id: 44 -->
    - [x] Create `Downloads` UI component (Popup/Sidepanel) <!-- id: 45 -->
    - [x] Polish progress bars and formatting <!-- id: 46 -->
