# Keyboard Backlight with Visual OSD

## ✨ Features

Your keyboard backlight now has **macOS-style visual feedback**!

### What You'll See:

When you press **F5** or **F6**, a notification appears showing:

```
⌨ Keyboard Backlight
████████████░░░░░░░░ 60%
```

- **⌨** Keyboard icon
- **Progress bar** showing current level (filled █ vs empty ░)
- **Percentage** (0-100%)
- **Auto-dismisses** after 1.5 seconds

## 🎮 Controls

| Key | Action |
|-----|--------|
| **F5** | Decrease brightness (5% steps) |
| **F6** | Increase brightness (5% steps) |

## 📍 Notification Location

Notifications appear based on your **mako** configuration:
- Default: Top-right corner
- Configure in: `~/.config/mako/config`

## 🔧 How It Works

1. **F5/F6 keys** → Triggers `~/bin/kbd-backlight` script
2. **Script** → Adjusts brightness with `brightnessctl`
3. **Notification** → Shows current level via `notify-send`
4. **Mako** → Displays the notification

## 🛠️ Manual Control

You can also control brightness from terminal:

```bash
# Increase
~/bin/kbd-backlight up

# Decrease
~/bin/kbd-backlight down

# Check current level
brightnessctl --device='smc::kbd_backlight' info

# Set specific percentage
brightnessctl --device='smc::kbd_backlight' set 75%

# Set specific value (0-255)
brightnessctl --device='smc::kbd_backlight' set 128
```

## 📊 Brightness Levels

- **Minimum:** 0 (off)
- **Maximum:** 255 (full brightness)
- **Current:** Check with `brightnessctl --device='smc::kbd_backlight' get`
- **Percentage:** Calculate as `(current/255) * 100`

## 🎨 Customization

### Change Step Size

Edit `~/bin/kbd-backlight` and change `5%+` and `5%-` to your preference:

```bash
# For 10% steps
brightnessctl --device="$DEVICE" set 10%+ > /dev/null

# For 1% steps (precise control)
brightnessctl --device="$DEVICE" set 1%+ > /dev/null
```

### Change Notification Duration

In `~/bin/kbd-backlight`, change `-t 1500` (1.5 seconds):

```bash
# 3 second duration
notify-send -t 3000 ...

# 1 second duration
notify-send -t 1000 ...
```

### Change Progress Bar Width

Edit the `BAR_WIDTH` variable:

```bash
# Longer bar (30 characters)
BAR_WIDTH=30

# Shorter bar (10 characters)
BAR_WIDTH=10
```

### Change Icons

Replace `⌨` with any emoji or icon:
- 💡 Light bulb
- 🔆 Sun
- ⭐ Star
- 🎹 Keyboard

## 🐛 Troubleshooting

### Notifications not appearing?

1. **Check mako is running:**
   ```bash
   ps aux | grep mako
   ```

2. **Test notifications:**
   ```bash
   notify-send "Test" "Can you see this?"
   ```

3. **Restart mako:**
   ```bash
   killall mako
   mako &
   ```

### F5/F6 not working?

1. **Check keybindings loaded:**
   ```bash
   hyprctl reload
   ```

2. **Test script directly:**
   ```bash
   ~/bin/kbd-backlight up
   ~/bin/kbd-backlight down
   ```

3. **Check key names with wev:**
   ```bash
   wev
   # Then press F5 and F6 to see key codes
   ```

### Wrong brightness changes?

1. **Verify device name:**
   ```bash
   brightnessctl -l | grep kbd
   ```

2. **If different device name**, edit `~/bin/kbd-backlight` and change:
   ```bash
   DEVICE="your-device-name-here"
   ```

## 💡 Tips

1. **Quick brightness check**: Run `~/bin/kbd-backlight up` from terminal to see current level
2. **Disable at night**: Set to 0% with `brightnessctl --device='smc::kbd_backlight' set 0`
3. **Full brightness**: Set to 100% with `brightnessctl --device='smc::kbd_backlight' set 100%`
4. **Add to waybar**: See `OPTIMIZATION_REPORT.md` for waybar integration

## 📱 Like macOS

This implementation mimics macOS behavior:
- ✅ Visual progress bar
- ✅ Percentage display
- ✅ Auto-dismiss after short delay
- ✅ Smooth brightness changes
- ✅ F5/F6 key control

The main difference: notifications appear where your notification daemon is configured (usually top-right) instead of center-screen like macOS.

## 🔗 Related Files

- **Script:** `~/bin/kbd-backlight`
- **Config:** `~/.config/hypr/bindings.conf`
- **Mako config:** `~/.config/mako/config`

---

**Enjoy your new keyboard backlight OSD!** ⌨️✨
