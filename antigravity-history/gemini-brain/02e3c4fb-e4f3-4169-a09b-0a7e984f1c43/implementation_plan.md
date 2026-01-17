# Phase 3: Final Integration & Full Functionality

## Goal Description
The objective is to achieve a fully functional extension where a user can detect a stream, click download, see progress, and get a merged MP4 file. This involves fixing the broken link between the Background logic and the FFmpeg Offscreen worker, ensuring UI updates are rendered, and verifying the end-to-end flow.

## User Review Required
> [!IMPORTANT]
> **Offscreen Script Selection**: `src/offscreen/index.html` currently points to `index.ts` (generic handler), but the `FFmpegManager` expects `main.ts` (specific handler). I will switch it to `main.ts` as it's cleaner and specialized for this extension's needs.

## Proposed Changes

### Background & Offscreen (`src/background`, `src/offscreen`)
Fix the communication pipeline for file merging.

#### [MODIFY] [index.html](file:///home/rob/cat-catch-enhanced/src/offscreen/index.html)
- Change `<script src="./index.ts">` to `<script src="./main.ts">` (or rename `main.ts` to `index.ts` if preferred, but switching the tag is cleaner).

#### [MODIFY] [FFmpegManager.ts](file:///home/rob/cat-catch-enhanced/src/background/processing/FFmpegManager.ts)
- Verify message types match `src/offscreen/main.ts`. (They appear to match `MERGE_SEGMENTS` and `jobId`).

### User Interface (`src/sidepanel`)
Ensure the user sees what's happening.

#### [MODIFY] [App.tsx](file:///home/rob/cat-catch-enhanced/src/sidepanel/App.tsx)
- The current implementation listens for global state, but need to verify it renders `<DownloadItem>` components with progress bars.
- If components are missing, I will create:
    - `src/sidepanel/components/DownloadList.tsx`
    - `src/sidepanel/components/DownloadItem.tsx`

### Settings Persistence (`src/shared/state`)
Ensure settings like "Max Concurrent Downloads" are respected.
- Verify `store.ts` correctly loads/saves to `settingsDb`. (Already confirmed in `store.ts` logic, but will double-check `initialize`).

## Verification Plan

### Automated Tests
- Run existing `store.test.ts` to ensure no regressions.
- (Optional) Create `ffmpeg.test.ts` mocking the offscreen message passing.

### Manual Verification
1.  **Reload Extension**.
2.  **Open Test Page**: Use a simulated HLS stream (or public test URL).
3.  **Start Download**: Click download in Side Panel.
4.  **Observe**:
    -   Side Panel shows "Downloading..." with percentage.
    -   Network tab shows activity.
    -   Status changes to "Merging...".
    -   Browser triggers a file save prompt (or auto-saves).
