---
name: Hyprland workspace system (2026-04-04)
description: Complete smart workspace setup with split-monitor, auto-categorization daemons, dock, and 12 productivity features
type: project
---

## Workspace Architecture

**Plugin:** split-monitor-workspaces (hyprpm, count=5)
- Laptop (eDP-1): WS 1-5 (L1-L5)
- TV (HDMI-A-1): WS 6-10 (T1-T5)
- SUPER+1-5 is context-dependent on focused monitor

**Waybar labels:** Monitor-ID format (L1-L5 / T1-T5) with vivid per-position colors (pink, peach, green, blue, mauve via nth-child CSS).

**IMPORTANT:** Waybar format-icons matches workspace NAME before ID. Never rename workspaces to numbers that collide with another monitor's ID mapping.

## Smart Daemons (all in ~/.local/bin/, pidfile-guarded)

| Daemon | Purpose | Pidfile |
|--------|---------|---------|
| hypr-smart-workspace | Auto-categorizes new windows by keyword matching on class/title | /tmp/hypr-smart-workspace.pid |
| hypr-monitor-handler | Migrates windows when TV connects/disconnects | /tmp/hypr-monitor-handler.pid |
| hypr-activity-pulse | Flashes workspace buttons on background window updates | /tmp/hypr-activity-pulse.pid |

**Smart workspace categories:**
- L1=Dev, L2=Chat, L3=Work, L4=Games, L5=System
- T1=Web, T2=Media, T3=Reference, T4=Files, T5=Extra
- Cache at ~/.config/hypr/smart-workspace-cache.json

## Features Installed

1. hypr-reorganize (SUPER+SHIFT+F1) — one-shot sort all windows
2. Window swallowing — enabled in looknfeel.conf misc section
3. Active window title — waybar hyprland/window module
4. Focus mode (SUPER+F2) — fullscreen + disable 2nd monitor
5. Zen mode (SUPER+F3) — zero-chrome + blank other monitor
6. Clipboard history (SUPER+V) — cliphist + rofi
7. Now-playing (waybar) — playerctl, click play/pause
8. Workspace activity pulse — daemon-based
9. Screenshot + annotate (SHIFT+Print) — grim + slurp + swappy
10. Pomodoro timer (waybar click) — 25min countdown
11. nwg-dock-hyprland — auto-hide dock on laptop bottom edge
12. wlr/taskbar — running app icons in waybar
13. Cheat sheet (SUPER+F1) — floating ghostty terminal

## Key Config Files

- ~/.config/hypr/plugins.conf — split-monitor-workspaces config
- ~/.config/hypr/bindings-pyprland.conf — all custom keybindings
- ~/.config/hypr/workspace-window-rules.conf — utility window rules only (smart daemon handles app routing)
- ~/.config/hypr/autostart.conf — daemon launches
- ~/.config/nwg-dock-hyprland/ — dock pinned apps + style

## Why: Design Decisions

- Icons abandoned at 768p: Nerd Font icons render as illegible squares in 26px waybar
- Monitor-ID labels chosen over purpose labels: L/T prefix eliminates cross-monitor confusion
- Smart daemon over static windowrules: keyword matching catches unknown apps, cache learns
- Pidfile guards added after duplicate daemon issue during config reloads
