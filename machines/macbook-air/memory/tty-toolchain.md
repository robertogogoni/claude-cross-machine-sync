# TTY & GIF Recording Toolchain

## Installed Tools (MacBook Air, 2026-02-26)

### Terminal Recording
| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| VHS | 0.10.0 | `.tape` DSL → GIF recording | `go install github.com/charmbracelet/vhs@latest` |
| asciinema | 2.4.0 | Terminal session → `.cast` files | `pacman -S asciinema` |
| agg | (cargo) | `.cast` → animated GIF | `cargo install agg` |
| termtosvg | (pip) | Terminal session → SVG animation | `pipx install termtosvg` |
| screen | 5.0.0 | Terminal multiplexer (PTY provider) | `pacman -S screen` |
| tmux | (system) | Terminal multiplexer for recording | `pacman -S tmux` |

### GIF Processing
| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| gifsicle | 1.95 | GIF optimization, frame manipulation | `pacman -S gifsicle` |
| gifski | 1.34.0 | High-quality GIF encoder (pngquant) | `pacman -S gifski` |
| ImageMagick | 7.x | Convert, identify, montage | `pacman -S imagemagick` |
| ffmpeg | 7.x | Video → GIF, frame extraction | `pacman -S ffmpeg` |

### Diagnostic
| Tool | Version | Purpose |
|------|---------|---------|
| `file` | system | Identify GIF format, frame count |
| `identify` | ImageMagick | Detailed GIF frame analysis |
| `gifsicle --info` | gifsicle | Frame timing, dimensions, optimization level |

## VHS Path
Add `~/go/bin` to PATH for VHS access:
```bash
export PATH="$HOME/go/bin:$PATH"
```

## VHS Tape DSL Quick Reference
```tape
Output assets/demo.gif
Set Theme "Catppuccin Mocha"
Set FontSize 14
Set Width 1100
Set Height 700
Set Padding 20
Set TypingSpeed 35ms
Set Shell "bash"

Type "command here"
Enter
Sleep 3s
```

## Key Lessons

### GIF Delta Encoding
GIF89a uses delta frames — each frame stores only changed pixels from the previous frame. When extracting individual frames (e.g., with `convert input.gif frame_%03d.png`), frames after the first will appear garbled unless you **coalesce** first:
```bash
# WRONG: garbled frames
convert demo.gif frame_%03d.png

# RIGHT: coalesce first, then extract
convert -coalesce demo.gif frame_%03d.png
```

### VHS stdout Gotcha
Never redirect stdout to `/dev/null` in VHS tape commands. VHS captures the terminal's visual output — if stdout is suppressed, the GIF shows nothing. Use plain commands that produce visible output.

### Demo Recording Pipeline (chosen approach)
```
VHS (.tape file) → demo.gif (direct, single tool)
```
Alternative pipeline (also available but not primary):
```
tmux (fixed PTY) → asciinema (.cast) → agg (.cast → .gif)
```
The tmux+asciinema+agg pipeline is in `scripts/record-asciinema-demo.sh` but VHS is simpler.

### PEP 668 on Arch Linux
Arch marks its Python as "externally managed" (PEP 668). `pip install --user` is blocked.
- Use `pipx install <package>` instead for CLI tools
- Use virtual environments for libraries
- `termtosvg` was installed via `pipx`

### terminalizer Failed
`terminalizer` (npm) requires native `canvas` module which needs build tools and system libraries that were too complex to install. Use VHS instead.
