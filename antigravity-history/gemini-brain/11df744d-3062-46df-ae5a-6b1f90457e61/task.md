# Task: Diagnose and Fix Input Method & Keyboard Layout

- [x] Investigate current configuration <!-- id: 0 -->
  - [x] Check environment variables in Hyprland config (`envs.conf`) <!-- id: 1 -->
  - [x] Check keyboard input configuration (`input.conf`) <!-- id: 2 -->
  - [x] Check `.XCompose` file <!-- id: 3 -->
- [/] Fix Wayland Diagnose Warning <!-- id: 4 -->
  - [/] Unset or correct `GTK_IM_MODULE` <!-- id: 5 -->
- [/] Fix 'ç' Character Input <!-- id: 6 -->
  - [/] Investigate `GTK_IM_MODULE=cedilla` vs Warning <!-- id: 7 -->
  - [x] Configure `envs.conf` for cedilla/fcitx support <!-- id: 8 -->
  - [ ] Verify `' + c` produces `ç` in terminals <!-- id: 9 -->
- [ ] Verification <!-- id: 10 -->
  - [ ] Restart Hyprland <!-- id: 11 -->
