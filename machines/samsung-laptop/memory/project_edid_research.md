---
name: EDID override research for LG TV
description: Complete research on custom EDID modification for LG TV HDMI-A-1, community comparison, tools, deployment path, raw dumps saved
type: project
---

## Current TV EDID (dumped 2026-04-04)

Raw binary saved at `/tmp/lg-tv-edid.bin` (256 bytes, 2 blocks).
Manufacturer: GSM, Model: 1, Serial: 0x01010101, Made: week 1 of 2017.
**Actual TV model: LG 24TL520S-PS** (24-inch TV/Monitor hybrid, NOT a large TV!)
Serial: 112AZQV18868, webOS 3.9.3-63015, firmware 06.10.60
Physical size: ~530x300mm (24"), but EDID falsely reports 1600x900mm (72")
Real PPI: ~92 (monitor-grade), NOT 35 (as we assumed when thinking it was a big TV)
Picture mode was set to **Vivid** (worst for PC, heavy post-processing, ~80ms input lag)

### Base Block (Block 0) key fields
- **DTD 1 (preferred): 1360x768@60Hz** (85.5 MHz clock) -- THIS IS THE PROBLEM
- DTD 2: 1024x768@60Hz (wasted slot)
- Monitor range: 58-62 Hz V, 30-83 kHz H, max 160 MHz dotclock
- Physical size: 1600x900 mm

### CTA-861 Extension (Block 1)
- VIC 16: 1920x1080@60Hz (148.5 MHz) -- the mode we want but NOT preferred
- VIC 19: 1280x720@50Hz marked as NATIVE (wrong)
- Audio: DTS 5.1, AC-3 5.1, PCM stereo, DD+ 5.1
- HDMI VSDB: Source address 2.0.0.0, TMDS max 150 MHz (0x1E)
- DTD 6: 1920x1080@60Hz (148.5 MHz) -- exists but in last position

### The smoking guns
1. Preferred mode is 1360x768 instead of 1920x1080
2. Native flag on VIC 19 (720p@50Hz) instead of VIC 16 (1080p@60Hz)
3. 1080p@60Hz timing is DTD 6 (last) instead of DTD 1 (first/preferred)
4. TMDS max 150 MHz gives only 1.5 MHz headroom above 1080p's 148.5 MHz

## Community Comparison (linuxhw/EDID repo)

815 GSM0001 entries total. 542 have 1360x768. 170 have 1080p preferred without 1360x768.

| Field | Your TV (2017) | SSCR2 (2022) | LG TV (2010) |
|---|---|---|---|
| DTD 1 (preferred) | 1360x768@60Hz | 1920x1080@60Hz | 1920x1080@60Hz |
| Max TMDS | 150 MHz | not specified | 225 MHz |
| Deep color | none | none | DC_36bit, DC_30bit |
| 1360x768? | YES (preferred) | NO | NO |

Your TV is the outlier. Even a 2010 LG TV reports 1080p preferred with 225 MHz TMDS.
The standard CEA-861 1080p DTD bytes are: `02 3a 80 18 71 38 2d 40 58 2c 45 00`

## What a custom EDID would fix

1. **Swap DTD 1 (1360x768) with DTD 6 (1920x1080)** -- 1080p becomes preferred from boot
2. Aquamarine allocates 1080p framebuffer from start -- no modeswitch needed
3. Could potentially remove `AQ_NO_ATOMIC=1` (get proper vsync back)
4. Could test removing `AQ_NO_MODIFIERS=1` (get tiled buffers back, potential smoothness fix)
5. Set native flag on VIC 16 (1080p@60Hz) instead of VIC 19 (720p@50Hz)
6. Optionally bump TMDS max from 150 to 165 MHz (more headroom)
7. Remove 1360x768 and 1024x768 from DTDs entirely

## Tools

- **edid-decode**: already installed, validates modifications
- **wxEDID**: GUI editor on Flathub, DTD Constructor for visual timing editing
- **xxd + hex edit**: surgical byte-level changes with checksum recalc
- **edid-json-tools**: convert to JSON, edit, convert back
- **edid-rw**: read/write EDID via i2c (for inspecting what TV actually sends)

## Deployment path

```bash
sudo mkdir -p /usr/lib/firmware/edid
sudo cp modified-edid.bin /usr/lib/firmware/edid/lg-tv-1080p.bin

# /etc/mkinitcpio.conf — add to FILES:
FILES=(/usr/lib/firmware/edid/lg-tv-1080p.bin)

# Kernel cmdline (systemd-boot or GRUB):
drm.edid_firmware=HDMI-A-1:edid/lg-tv-1080p.bin

sudo mkinitcpio -P
reboot
```

**Zero bricking risk.** TV EEPROM is never touched. Remove kernel param and reboot to recover.

## Pre-modification checks

Before editing EDID, try these zero-effort TV settings:
1. Rename HDMI input label to "PC" on the TV itself (may change EDID the TV sends)
2. Check for "HDMI ULTRA HD Deep Color" or equivalent per-port setting
3. Check TV firmware version and consider updating

## Laptop EDID (reference)

AUO panel B156XW02 V2, 1366x768@60Hz only, 340x193mm, no extension blocks.
Raw binary at `/tmp/laptop-edid.bin` (128 bytes, 1 block).

## TV Jailbreak (2026-04-05, DONE)

webOS 3.9.3 jailbroken, root via telnet (no password) at 192.168.15.16:23
Homebrew Channel on port 3000, SSH on port 22 (needs password/key setup)

### What we fixed via Luna API
- **Picture mode was "sports" (NOT "game")** despite user thinking it was Game
  - Sports had: TruMotion ON, dynamicContrast high, dynamicColor high, edgeEnhancer on, superResolution medium, noiseReduction on
  - All that post-processing was the main source of lag and bad text rendering
- **Set pictureMode to "game"** via: `luna-send -n 1 'luna://com.webos.settingsservice/setSystemSettings' '{"category":"picture","settings":{"pictureMode":"game"}}'`
- **Enabled hidden pcMode for HDMI1** via: `luna-send -n 1 'luna://com.webos.settingsservice/setSystemSettings' '{"category":"picture","settings":{"pcMode":{"hdmi1":true}}}'`
- pcMode is NOT exposed in the TV menus on this model (hidden flag), but persists in settings DB across reboots
- Result: "way better" per user

### Round 2 fix (2026-04-05): pcMode on wrong port + residual processing
- TV's `dimension.input` reports `hdmi2`, but pcMode was only set on `hdmi1`
- Without pcMode active, game mode still left `edgeEnhancer: on` and `superResolution: medium`
- Switching from AQ_NO_ATOMIC (legacy DRM) to atomic DRM sends AVI InfoFrames, which may have caused the TV to re-evaluate input/port mapping
- **Fixed:** enabled pcMode on both hdmi1+hdmi2, disabled edgeEnhancer and superResolution
- User confirmed visible quality improvement (detected the regression independently before diagnosis)

### Key TV details
- Model: LG 24TL520S-PS (24-inch TV/Monitor hybrid, ~92 PPI, NOT a big TV)
- Firmware: 06.10.60, webOS 3.9.3 (dreadlocks2-dudhwa)
- EDID lies about physical size: reports 1600x900mm (72") when actual is ~530x300mm (24")
- i2c mystery device at 0x3a on HDMI DDC bus (vendor HDMI receiver registers)
- AQ_NO_ATOMIC removed (2026-04-05): atomic DRM now sends AVI InfoFrames, TV sees proper content type
- TV actual input is HDMI 2 (not HDMI 1 as assumed), pcMode now set on both ports

### Luna API reference
```bash
# Get all picture settings
luna-send -n 1 'luna://com.webos.settingsservice/getSystemSettings' '{"category":"picture"}'
# Set picture mode
luna-send -n 1 'luna://com.webos.settingsservice/setSystemSettings' '{"category":"picture","settings":{"pictureMode":"game"}}'
# Set pcMode per HDMI port
luna-send -n 1 'luna://com.webos.settingsservice/setSystemSettings' '{"category":"picture","settings":{"pcMode":{"hdmi1":true}}}'
# Get system info
luna-send -n 1 'luna://com.webos.service.tv.systemproperty/getSystemInfo' '{"keys":["modelName","firmwareVersion","sdkVersion"]}'
```

## Custom EDID: DEPLOYED (verified 2026-04-05)

Custom EDID built and deployed at `/usr/lib/firmware/edid/lg-tv-1080p.bin`:
- DTD 1 swapped to 1920x1080@60Hz (1080p preferred from boot)
- Physical size corrected to 530x300mm in all DTDs
- TMDS max bumped to 165 MHz (was 150)
- VIC 16 (1080p@60Hz) marked native
- 1360x768 demoted to DTD 6 (last, fallback only)
- Loaded via kernel cmdline: `drm.edid_firmware=HDMI-A-1:edid/lg-tv-1080p.bin`
- Baked into initramfs via mkinitcpio FILES array
- Backup at `/usr/lib/firmware/edid/lg-tv-1080p.bin.bak`

**All three next-steps completed:**
1. Custom EDID: DONE (deployed, verified working)
2. AQ_NO_ATOMIC removed: DONE (atomic DRM active, AVI InfoFrames sent)
3. AQ_NO_MODIFIERS removed: DONE (tiled buffers + FBC active)
