# System Report & Package Recommendations
**Generated:** 2025-11-17

## 📊 System Overview

You're running a well-configured **Arch Linux + Hyprland** setup on a **MacBook Air 7,2 (Early 2015)** with an excellent selection of modern development tools and utilities.

---

## 🖥️ Hardware Specifications

| Component | Details |
|-----------|---------|
| **Model** | MacBook Air 7,2 (Early 2015) |
| **CPU** | Intel Core i5-5250U @ 1.60GHz (2 cores, 4 threads) |
| **RAM** | 8 GB |
| **GPU** | Intel HD Graphics 6000 |
| **Storage** | 113 GB SSD (69 GB available) |
| **Display** | Intel integrated |
| **Chassis** | Laptop 💻 |
| **Kernel** | Linux 6.17.8-arch1-1 |
| **Firmware** | 489.0.0.0.0 (2023-10-07) |

---

## 🎯 Current Software Setup

### Display Server & Window Manager
- **Compositor:** Hyprland 0.52.1 (Wayland)
- **Status Bar:** Waybar 0.14.0
- **Launcher:** Walker 2.10.0 + Elephant suite
- **Notification Daemon:** Mako 1.10.0
- **Lock Screen:** Hyprlock 0.9.2
- **Idle Manager:** Hypridle 0.1.7
- **Screenshot Tools:** Hyprshot, Slurp, Satty
- **Screen Recorder:** GPU Screen Recorder + OBS Studio

### Terminal Environment
- **Terminals:** Warp, Alacritty, Ghostty, Kitty
- **Shell:** Bash 5.3.3, Fish 4.2.1
- **Prompt:** Starship 1.24.1
- **Multiplexer:** (None detected - see recommendations)

### Development Tools
**Version Managers:**
- mise 2025.11.3 (managing Node.js 25.1.0)

**Languages & Compilers:**
- Rust 1.91.1 + Cargo
- Clang 21.1.5 + LLVM 21.1.5
- Python 3.x
- Java
- Lua + LuaRocks

**Editors & IDEs:**
- Neovim 0.11.5 (omarchy-nvim custom build)
- Claude Code 2.0.37

**Version Control:**
- Git 2.51.2
- GitHub CLI 2.83.1
- LazyGit 0.56.0

**Containers:**
- Docker 28.5.2
- Docker Compose 2.40.3
- Docker Buildx 0.29.1
- LazyDocker 0.24.2

### Modern CLI Utilities
✅ **File Navigation & Search:**
- `eza` 0.23.4 (modern `ls`)
- `bat` 0.26.0 (modern `cat`)
- `fd` 10.3.0 (modern `find`)
- `ripgrep` 15.1.0 (modern `grep`)
- `fzf` 0.66.1 (fuzzy finder)
- `zoxide` 0.9.8 (smart cd)
- `plocate` 1.1.23 (fast file locator)

✅ **System Monitoring:**
- `btop` 1.4.5
- `htop` 3.4.1
- `procs` 0.14.10 (modern `ps`)
- `iotop` 0.6
- `inxi` 3.3.39 (system info)

✅ **Disk & Performance:**
- `duf` 0.9.1 (modern `df`)
- `dust` 1.2.3 (modern `du`)
- `ncdu` 2.9.9 (disk usage analyzer)
- `hyperfine` 1.19.0 (benchmarking)

✅ **Misc Tools:**
- `jq` 1.8.1 (JSON processor)
- `tldr` 3.4.3 (simplified man pages)
- `gum` 0.17.0 (shell script helpers)

### Productivity Applications
- 1Password (Beta + CLI)
- Signal Desktop
- Obsidian
- Typora
- LibreOffice Fresh
- Claude Desktop
- Beeper v4
- Spotify

### Mac-Specific Packages (Already Installed)
- `broadcom-wl` - WiFi driver for Broadcom chips
- `macbook12-spi-driver-dkms` - Keyboard/trackpad drivers
- `brightnessctl` - Screen brightness control
- `intel-ucode` - Intel microcode updates
- `powertop` - Power management tuning
- `power-profiles-daemon` - Power profile switching

### Custom Omarchy Packages
- `omarchy-chromium` - Custom Chromium build
- `omarchy-nvim` - Custom Neovim config
- `omarchy-walker` - Custom Walker launcher
- `omarchy-keyring` - Custom keyring

---

## 📦 Package Summary

- **Total Explicitly Installed:** 200 packages
- **AUR Packages:** beeper-v4-bin, claude-desktop-bin, simple-usb-automount
- **Display Server:** Wayland (Hyprland)
- **Init System:** systemd + UWSM session manager
- **Package Manager:** pacman + yay (AUR helper)

---

## 🚀 Recommended Packages to Install

### 1. Terminal Multiplexer
You don't currently have tmux or zellij installed.

**Recommendation: `zellij`** (Modern, Rust-based multiplexer with great defaults)
```bash
sudo pacman -S zellij
```
or **`tmux`** (Classic, widely-used)
```bash
sudo pacman -S tmux
```

**Why:** Essential for managing multiple terminal sessions, especially when working remotely or with complex workflows.

---

### 2. Better Git Diff Tool: `delta`
```bash
sudo pacman -S git-delta
```
**Why:** Syntax-highlighted git diffs with side-by-side view. Works beautifully with your existing LazyGit setup.

**Configure:**
```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
```

---

### 3. File Manager TUI: `yazi`
```bash
sudo pacman -S yazi
```
**Why:** Modern, fast terminal file manager built in Rust with image preview support. Perfect complement to your Hyprland setup.

---

### 4. Better `cat` with Code Context: `cheat`
```bash
sudo pacman -S cheat
```
**Why:** Community-driven cheat sheets for CLI commands. Complements your existing `tldr`.

---

### 5. Network Monitoring: `bandwhich`
```bash
sudo pacman -S bandwhich
```
**Why:** Monitor network bandwidth usage by process in real-time. Useful for laptop/mobile work.

---

### 6. JSON/YAML/TOML Viewer: `fx`
```bash
yay -S fx
```
**Why:** Interactive JSON viewer with fuzzy search. Great for API development and config file inspection.

---

### 7. HTTP Client: `httpie` or `xh`
```bash
sudo pacman -S httpie     # Python-based, feature-rich
# OR
sudo pacman -S xh         # Rust-based, fast clone of httpie
```
**Why:** User-friendly HTTP client for API testing. Better UX than curl for interactive use.

---

### 8. Process Manager: `bottom` (btm)
```bash
sudo pacman -S bottom
```
**Why:** Another excellent system monitor with a beautiful interface. Alternative to btop with different features.

---

### 9. Clipboard Manager for Wayland: `cliphist`
```bash
sudo pacman -S cliphist
```
**Why:** Clipboard history manager for Wayland. Integrates with wl-clipboard (which you already have).

**Setup with Hyprland:**
```bash
# Add to hyprland.conf:
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Bind a key to show history (example):
bind = SUPER, V, exec, cliphist list | walker --dmenu | cliphist decode | wl-copy
```

---

### 10. Color Scheme Manager: `flavours`
```bash
yay -S flavours
```
**Why:** Manage and apply color schemes across your terminal apps (Alacritty, Kitty, etc.) from base16 templates.

---

### 11. Mac Touchpad Gestures: `libinput-gestures`
```bash
sudo pacman -S libinput-gestures
```
**Why:** Configure touchpad gestures for Wayland. Essential for MacBook trackpad users.

**Setup:**
```bash
sudo gpasswd -a $USER input
libinput-gestures-setup autostart
```

---

### 12. Systemd Service Manager: `systemctl-tui`
```bash
yay -S systemctl-tui
```
**Why:** Interactive TUI for managing systemd services. Makes troubleshooting easier.

---

### 13. Markdown Preview: `glow`
```bash
sudo pacman -S glow
```
**Why:** Render markdown files in the terminal with style. Great for README files and documentation.

---

### 14. MacBook Fan Control: `mbpfan`
```bash
sudo pacman -S mbpfan
```
**Why:** Better fan control for MacBooks running Linux. Prevents overheating and improves battery life.

**Enable:**
```bash
sudo systemctl enable --now mbpfan
```

---

### 15. WiFi Menu for Wayland: `iwgtk`
```bash
sudo pacman -S iwgtk
```
**Why:** GTK-based GUI for iwd (which you're already using). Makes WiFi management easier on Hyprland.

---

### 16. Secrets Manager: `age`
```bash
sudo pacman -S age
```
**Why:** Modern, simple file encryption tool. Great for encrypting dotfiles and secrets in git repos.

---

### 17. Container Image Manager: `dive`
```bash
sudo pacman -S dive
```
**Why:** Explore Docker image layers and optimize image size. Perfect complement to your existing Docker setup.

---

### 18. Code Statistics: `scc`
```bash
sudo pacman -S scc
```
**Why:** Faster alternative to `tokei` (which you have) with more features. Count lines of code in projects.

---

### 19. Bluetooth Manager TUI: `bluetuith`
```bash
yay -S bluetuith
```
**Why:** TUI for managing Bluetooth devices. Lighter than Blueberry (which you have) for quick connections.

---

### 20. Session Manager: `ananicy-cpp`
```bash
sudo pacman -S ananicy-cpp
```
**Why:** Automatically adjust process priorities for better system responsiveness on your dual-core system.

---

## 🍎 Mac-Specific Recommendations

### Already Installed & Configured Well:
✅ Broadcom WiFi drivers (`broadcom-wl`)
✅ MacBook SPI drivers for keyboard/trackpad
✅ Brightness control (`brightnessctl`)
✅ Power management (`powertop`, `power-profiles-daemon`)
✅ Intel microcode updates

### Additional Mac-Specific Suggestions:

#### 1. **macOS-Like Keybindings**
You can configure Hyprland to use Cmd (Super) key like macOS:
```conf
# ~/.config/hypr/hyprland.conf examples:
bind = SUPER, Q, killactive          # Cmd+Q to quit
bind = SUPER, W, killactive          # Cmd+W to close
bind = SUPER, T, exec, warp-terminal # Cmd+T for new terminal
bind = SUPER, C, exec, wl-copy       # Copy
bind = SUPER, V, exec, wl-paste      # Paste
```

#### 2. **Function Key Mapping**
Check if function keys (F1-F12, brightness, volume) are working:
```bash
# Test with:
wev
```
If not working properly, configure with `brightnessctl`, `pamixer` (already installed).

#### 3. **Trackpad Configuration**
Fine-tune your trackpad settings for Wayland. Check:
```bash
cat ~/.config/hypr/hyprland.conf | grep -A10 "input {"
```

Recommended settings for MacBook trackpads:
```conf
input {
    touchpad {
        natural_scroll = yes
        scroll_factor = 0.3
        clickfinger_behavior = true
        tap-to-click = true
        drag_lock = false
        disable_while_typing = true
    }
}
```

---

## 🔧 Configuration Improvements

### 1. **Shell Enhancements**
Consider adding these to your shell config:

**For Bash (`~/.bashrc`):**
```bash
# Better history
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Aliases leveraging installed tools
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias du='dust'
alias df='duf'
alias ps='procs'
alias cd='z'  # using zoxide

# Docker shortcuts
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='lazydocker'
```

### 2. **Git Configuration Enhancements**
```bash
# Better git log with your installed tools
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Use lazygit from anywhere
git config --global alias.lg "!lazygit"
```

### 3. **Neovim LSP Servers**
Check which LSP servers you have installed:
```bash
mise list
```

Consider installing LSPs for your languages:
```bash
# TypeScript/JavaScript
mise install node-lts
npm install -g typescript-language-server

# Rust (via rustup)
rustup component add rust-analyzer

# Python
pipx install python-lsp-server

# Bash
sudo pacman -S bash-language-server

# Markdown
sudo pacman -S marksman
```

### 4. **Docker Optimization**
Enable Docker BuildKit permanently:
```bash
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
```

### 5. **Hyprland Performance Tweaks**
For your Intel HD Graphics 6000, ensure these are in `hyprland.conf`:
```conf
decoration {
    blur {
        enabled = yes
        size = 3      # Lower blur for better performance
        passes = 1    # Single pass for older GPU
    }
    drop_shadow = no  # Disable shadows for performance
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.0
    
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default
}

misc {
    vfr = true          # Variable refresh rate
    vrr = 0             # VRR off for Intel iGPU
}
```

---

## 📚 Useful Resources

### Arch Linux on MacBook Air 7,2
- [Arch Wiki: MacBook](https://wiki.archlinux.org/title/Mac)
- [Arch Wiki: MacBookAir7,x](https://wiki.archlinux.org/title/MacBookAir7,x)

### Hyprland Resources
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Awesome Hyprland](https://github.com/hyprland-community/awesome-hyprland)
- [Hyprland Dotfiles Collection](https://github.com/search?q=hyprland+dotfiles&type=repositories)

### Wayland Tools
- [Awesome Wayland](https://github.com/natpen/awesome-wayland)

### MacBook Linux Communities
- r/linuxhardware
- r/archlinux
- [MacBook Linux Telegram Group](https://t.me/macbooklinux)

---

## 📊 Summary

Your system is **extremely well-configured** with:
- ✅ Modern development environment (Rust, Node, Python, Docker)
- ✅ Excellent CLI tooling (eza, bat, fd, ripgrep, fzf, zoxide)
- ✅ Polished Hyprland Wayland setup
- ✅ Mac-specific drivers and power management
- ✅ Quality productivity apps

**Key Gaps to Consider:**
1. No terminal multiplexer (tmux/zellij)
2. Missing clipboard history manager (cliphist)
3. Could benefit from git-delta for better diffs
4. Mac fan control (mbpfan) for better thermal management
5. Gesture support for trackpad (libinput-gestures)

**Priority Installs:**
```bash
# Essential missing tools
sudo pacman -S zellij git-delta yazi cliphist mbpfan libinput-gestures

# Nice-to-have additions
sudo pacman -S httpie bottom glow bandwhich dive
```

Enjoy your optimized Arch Linux + Hyprland setup on your MacBook Air! 🚀
