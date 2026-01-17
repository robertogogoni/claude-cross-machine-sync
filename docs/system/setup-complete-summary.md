# Setup Complete! 🎉

**Date:** 2025-11-17  
**System:** MacBook Air 7,2 running Arch Linux + Hyprland

---

## ✅ What Was Installed

### New CLI Tools (Official Repos)
- ✅ `zellij` - Modern terminal multiplexer
- ✅ `git-delta` - Beautiful git diffs
- ✅ `yazi` - TUI file manager
- ✅ `cliphist` - Clipboard history for Wayland
- ✅ `xh` - Modern HTTP client (Rust-based httpie clone)
- ✅ `bottom` (btm) - System monitor
- ✅ `glow` - Markdown renderer for terminal
- ✅ `bandwhich` - Network bandwidth monitor
- ✅ `dive` - Docker image layer explorer

### New Tools (AUR)
- ✅ `mbpfan` - MacBook fan controller
- ✅ `libinput-gestures` - Touchpad gesture daemon
- ✅ `bluetuith` - Bluetooth manager TUI
- ✅ `systemctl-tui` - Systemd service manager

### Power Management
- ✅ `tlp` - Advanced power management
- ✅ `tlp-rdw` - TLP radio device wizard
- ✅ `powertop` - Power consumption analyzer (already installed, configured)

---

## 🔧 Configurations Applied

### 1. Git Configuration
✅ Configured git-delta as default pager:
```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
```

### 2. Shell Enhancements (~/.bashrc)
✅ Added comprehensive aliases:
- Modern command replacements: `ls→eza`, `cat→bat`, `find→fd`, `grep→rg`, `du→dust`, `df→duf`, `ps→procs`
- Git shortcuts: `gst`, `gd`, `gl`, `gco`, `ga`, `gc`, `gp`, `gpl`, `lg`
- Docker shortcuts: `d`, `dc`, `dps`, `dimg`, `dlog`, `dexec`, `dlogs`
- System monitoring: `top→btop`, `htop→btop`, `cpu→btop`
- Utilities: `http→xh`, `md→glow`, `net→bandwhich`
- Zoxide integration with `cd` alias
- Docker BuildKit enabled by default
- Better bash history settings (10,000 lines, no duplicates)

**Note:** These aliases will be active after you source your bashrc or start a new terminal:
```bash
source ~/.bashrc
```

### 3. Hyprland - Clipboard History
✅ Added to `~/.config/hypr/autostart.conf`:
```conf
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

✅ Added to `~/.config/hypr/bindings.conf`:
```conf
bindd = SUPER, V, Clipboard history, exec, cliphist list | walker --dmenu | cliphist decode | wl-copy
```

**Usage:** Press `Super + V` to open clipboard history picker!

### 4. Hyprland - Performance Optimizations
✅ Added to `~/.config/hypr/looknfeel.conf`:
- Reduced blur (size=3, passes=1) for Intel HD Graphics 6000
- Disabled drop shadows for better performance
- Optimized animations (faster, smoother)
- Enabled VFR (variable frame rate) for power savings
- Disabled VRR for Intel iGPU compatibility

**Note:** Restart Hyprland to apply changes (or just log out/log back in)

### 5. Touchpad Gestures
✅ Created `~/.config/libinput-gestures.conf` with macOS-style gestures:

**3-finger swipes:**
- Left/Right: Switch workspaces
- Up: Show applications (walker)
- Down: Close active window

**4-finger swipes:**
- Up: Fullscreen toggle
- Down: Exit fullscreen
- Left/Right: Move window to workspace

**Pinch gestures:**
- Out: Show applications
- In: Close window

**Note:** You need to **log out and log back in** for gestures to work (input group membership required).

After relogin, gestures will auto-start. Check status:
```bash
libinput-gestures-setup status
```

### 6. Power Management Services
✅ **mbpfan** - MacBook fan control
- Service: `mbpfan.service`
- Status: ✅ Enabled and running
- Config: `/etc/mbpfan.conf`

✅ **TLP** - Advanced laptop power management
- Service: `tlp.service`
- Status: ✅ Enabled and running
- Config: `/etc/tlp.conf` (uses defaults for now)
- Replaced: `power-profiles-daemon` (conflicted with TLP)

✅ **Powertop Auto-tune** - Runtime power optimizations
- Service: `powertop-autotune.service`
- Status: ✅ Enabled (runs on boot)
- Manually run: `sudo powertop --auto-tune`

✅ **Masked conflicting services:**
- `systemd-rfkill.service`
- `systemd-rfkill.socket`

---

## 🚀 How to Use Your New Tools

### Terminal Multiplexer
```bash
zellij              # Start zellij session
zellij ls           # List sessions
zellij a <session>  # Attach to session
```

### File Manager
```bash
yazi                # Launch in current directory
yazi /path/to/dir   # Launch in specific directory
```

### Git with Delta
```bash
git diff            # Automatically uses delta
git log -p          # Logs with diffs in delta
git show <commit>   # Show commit with delta
```

### Clipboard History
- `Super + V` - Open clipboard history picker
- Or manually: `cliphist list`

### HTTP Requests
```bash
xh https://api.github.com/users/github
xh POST https://httpbin.org/post name=rob age=30
```

### System Monitoring
```bash
btop                # Visual system monitor
bottom              # Alternative system monitor (btm)
bandwhich           # Network usage by process (needs sudo)
```

### Markdown Viewer
```bash
glow README.md                           # Render markdown
glow ~/system-report-and-recommendations.md
```

### Docker Image Inspector
```bash
dive <image-name>   # Analyze Docker image layers
```

### Bluetooth Manager
```bash
bluetuith           # TUI for Bluetooth management
```

### Systemd Service Manager
```bash
systemctl-tui       # Manage systemd services interactively
```

---

## ⚠️ Important: Required Actions

### 1. Reload Shell Configuration
To activate the new aliases:
```bash
source ~/.bashrc
# Or just open a new terminal
```

### 2. Restart Hyprland (or reboot)
To activate:
- Clipboard history (cliphist)
- Performance optimizations
- Touchpad gestures

**Quick restart:**
```bash
# Log out and log back in
# Or reload Hyprland config:
hyprctl reload
```

### 3. Relogin for Gestures
The `input` group membership won't take effect until you log out and back in.

After relogin:
```bash
# Gestures should auto-start. Verify:
libinput-gestures-setup status

# If not running, start it:
libinput-gestures-setup start
```

---

## 📊 Service Status Summary

```bash
# Check all services at once:
systemctl status mbpfan.service tlp.service --no-pager
systemctl status powertop-autotune.service --no-pager
systemctl --user status libinput-gestures.service --no-pager
```

Currently running:
- ✅ mbpfan (fan control)
- ✅ TLP (power management)
- ✅ powertop-autotune (enabled for next boot)
- ⏳ libinput-gestures (will start after relogin)

---

## 🎯 Power Management Tips

### Check Power Stats
```bash
sudo tlp-stat -b        # Battery info
sudo tlp-stat -s        # System info
sudo powertop           # Interactive power monitor
```

### Adjust TLP Settings (Optional)
Edit `/etc/tlp.conf` for fine-tuning:
```bash
sudo nano /etc/tlp.conf
sudo tlp start          # Apply changes
```

### Check Fan Status
```bash
sudo systemctl status mbpfan
cat /etc/mbpfan.conf    # View fan config
```

---

## 📚 Documentation & Resources

### Quick Reference
- Zellij: https://zellij.dev/documentation/
- Yazi: https://yazi-rs.github.io/
- Git Delta: https://github.com/dandavison/delta
- TLP: https://linrunner.de/tlp/
- libinput-gestures: https://github.com/bulletmark/libinput-gestures

### Your System Report
The full system analysis with all recommendations is available at:
```bash
glow ~/system-report-and-recommendations.md
```

---

## 🔥 Next Steps (Optional)

1. **Customize touchpad gestures:**
   Edit `~/.config/libinput-gestures.conf` to adjust gesture sensitivity or actions

2. **Tune TLP for better battery:**
   Edit `/etc/tlp.conf` and uncomment/modify battery thresholds

3. **Explore your new tools:**
   - Try `yazi` as your file manager
   - Use `xh` instead of curl for API testing
   - Check `dive` to optimize your Docker images
   - Use `Super+V` frequently for clipboard history

4. **Set zellij as default multiplexer:**
   Add to your workflow or configure auto-start if desired

---

## ✨ Summary

Your MacBook Air is now **fully optimized** with:
- 🚀 Modern CLI tooling with intuitive aliases
- 🎨 Beautiful git diffs with delta
- 📋 System-wide clipboard history
- 🖱️ macOS-style touchpad gestures
- ⚡ Optimized performance for Intel HD Graphics 6000
- 🔋 Advanced power management (TLP + powertop + mbpfan)
- 🛠️ Comprehensive developer utilities

**Enjoy your supercharged Arch Linux setup!** 🎉
