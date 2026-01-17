# Audio System Setup - Arch Linux

## Overview
Your system is now configured with a fully functional PipeWire audio stack with optimized settings and helpful utilities.

## System Configuration

### Audio Stack
- **Audio Server**: PipeWire 1.4.9 with PulseAudio compatibility
- **Session Manager**: WirePlumber 0.5.12
- **Default Output**: Analog Stereo (HDA Intel PCH)
- **Sample Rate**: 48kHz
- **Volume**: 75% (configurable)

### Hardware
- **Card 0 (HDMI)**: Intel Broadwell HDMI Audio (00:03.0)
- **Card 1 (PCH)**: Intel Wildcat Point-LP HD Audio (00:1b.0) - **Primary**
  - Cirrus Logic CS4208 codec
  - Analog stereo output (speakers/headphones)
  - Analog stereo input (microphone)

## Configuration Files

### PipeWire Configuration
- `~/.config/pipewire/pipewire.conf.d/99-custom.conf`
  - 48kHz sample rate with support for 44.1kHz and 96kHz
  - Balanced quantum settings (1024) for good latency/performance
  - High-quality resampling (quality level 4)

### WirePlumber Configuration
- `~/.config/wireplumber/main.lua.d/51-default-profile.lua`
  - Automatically sets PCH card to duplex analog stereo mode on startup
- `~/.config/wireplumber/main.lua.d/52-default-sink.lua`
  - Sets analog output as default with high priority (2000)

## Installed Tools

### Core Utilities
- **alsa-utils**: Hardware-level audio tools (aplay, amixer, speaker-test)
- **pavucontrol**: GUI volume control and device management
- **helvum**: Visual PipeWire graph/patchbay (GUI)
- **playerctl**: Media player control from command line
- **easyeffects**: Audio effects and equalization (GUI)

### Helper Scripts (in ~/bin/)
All scripts are executable and ready to use:

#### audio-switch
Interactive script to switch between audio outputs (analog, HDMI, etc.)
```bash
audio-switch
```

#### audio-reset
Restarts audio services and resets to optimal default configuration
```bash
audio-reset
```

#### audio-volume
Quick volume control from command line
```bash
audio-volume up          # Increase by 5%
audio-volume down        # Decrease by 5%
audio-volume mute        # Toggle mute
audio-volume set 80      # Set to specific percentage
```

## Common Tasks

### GUI Volume Control
```bash
pavucontrol
```

### Test Audio
```bash
speaker-test -t wav -c 2 -l 1
```

### Check Audio Status
```bash
pactl info
pactl list sinks short
pactl get-sink-volume @DEFAULT_SINK@
```

### Switch to HDMI Output
```bash
pactl set-default-sink alsa_output.pci-0000_00_03.0.hdmi-surround
```

### Switch Back to Analog
```bash
pactl set-default-sink alsa_output.pci-0000_00_1b.0.analog-stereo
```

### Visual Audio Routing (Patchbay)
```bash
helvum
```

### Audio Effects/EQ
```bash
easyeffects
```

## Troubleshooting

### No Audio Output
1. Check volume is not muted:
   ```bash
   pactl get-sink-mute @DEFAULT_SINK@
   amixer get Master
   ```

2. Verify correct output device is selected:
   ```bash
   pactl info | grep "Default Sink"
   ```

3. Run the reset script:
   ```bash
   audio-reset
   ```

### Audio Services Not Running
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Check for Errors
```bash
journalctl --user -u pipewire -u wireplumber --since "10 minutes ago"
```

### Profile Issues
If the analog output disappears after reboot, manually set profile:
```bash
pactl set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo+input:analog-stereo
```
(This should be automatic with the WirePlumber configuration)

## Advanced Configuration

### Adjust Latency
Edit `~/.config/pipewire/pipewire.conf.d/99-custom.conf` and modify:
- Lower quantum (256-512) = lower latency, higher CPU
- Higher quantum (2048+) = higher latency, lower CPU

After changes, restart:
```bash
systemctl --user restart pipewire wireplumber
```

### Install Additional Audio Plugins (optional)
For EasyEffects:
```bash
sudo pacman -S lsp-plugins-lv2 calf zam-plugins-lv2 mda.lv2
```

## Additional Resources
- PipeWire Wiki: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/home
- WirePlumber Docs: https://pipewire.pages.freedesktop.org/wireplumber/
- Arch Wiki Audio: https://wiki.archlinux.org/title/PipeWire
