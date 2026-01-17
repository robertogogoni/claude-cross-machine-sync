# MacBook Air Sensor Guide

## 🌡️ Your Sensor Status: FULLY WORKING ✅

All **34 temperature sensors** + fan + battery monitoring are operational!

## Quick Sensor Commands

```bash
# View all sensors
sensors

# Real-time monitoring
watch -n 1 sensors

# Show only CPU temps
sensors coretemp-isa-0000

# Show only Apple SMC sensors
sensors applesmc-isa-0300

# Show battery info
sensors BAT0-acpi-0

# Check fan speed
sensors | grep -i exhaust

# Monitor with htop (includes temps)
htop

# Monitor with btop (visual)
btop
```

## Sensor Breakdown

### CPU Temperatures (coretemp)
- **Package id 0**: Overall CPU temp
- **Core 0, Core 1**: Individual core temperatures
- **Safe range**: Below 80°C normal, 105°C critical

### Apple SMC Sensors (applesmc)
Your MacBook has 34 temperature sensors monitoring:

| Sensor | Description |
|--------|-------------|
| **TB0T-TBXT** | Thunderbolt port temperatures |
| **TC0E-TCXC** | CPU/Core detailed temps |
| **TH0A-Th1H** | Heatsink temperatures |
| **TM0P, Tm0P** | Memory region temps |
| **TS2P, Ts0P, Ts0S** | Storage/SSD temps |
| **TW0P** | Wireless module temp |
| **TPCD** | Power controller temp |
| **Exhaust** | Fan speed (RPM) |

### Battery (BAT0-acpi-0)
- **in0**: Battery voltage
- **temp**: Battery temperature  
- **curr1**: Current draw (amps)

## Fan Information

Current: **1190 RPM**
- Min: 1200 RPM
- Max: 6500 RPM

**Note**: Fan speed auto-adjusts based on temperature. If you want manual control, install `mbpfan`:
```bash
yay -S mbpfan-git
sudo systemctl enable --now mbpfan
```

## Temperature Monitoring Tips

1. **Normal temps under light load**: 40-60°C
2. **Under heavy load**: 70-85°C (expected)
3. **Critical threshold**: 105°C (CPU will throttle)
4. **Fan kicks in**: Around 60-70°C

## Add to Waybar (Status Bar)

Edit `~/.config/waybar/config` and add:

```json
"temperature": {
    "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
    "critical-threshold": 85,
    "format": "{icon} {temperatureC}°C",
    "format-icons": ["", "", "", "", ""],
    "tooltip": true
},
"custom/fan": {
    "exec": "sensors | grep -i exhaust | awk '{print $2\" \"$3}'",
    "interval": 5,
    "format": " {}",
    "tooltip": false
}
```

## Troubleshooting

### If sensors command not found:
```bash
sudo pacman -S lm_sensors
```

### If sensors show wrong values:
```bash
sudo sensors-detect --auto
sudo systemctl restart lm_sensors
```

### To configure sensor labels:
Edit `/etc/sensors3.conf` or create `/etc/sensors.d/macbook.conf`

## Example Sensor Output

```
coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +77.0°C  (high = +105.0°C, crit = +105.0°C)
Core 0:        +76.0°C  (high = +105.0°C, crit = +105.0°C)
Core 1:        +76.0°C  (high = +105.0°C, crit = +105.0°C)

applesmc-isa-0300
Adapter: ISA adapter
Exhaust  :   1190 RPM  (min = 1200 RPM, max = 6500 RPM)
TC0P:         +65.8°C   # CPU proximity
TCGC:         +74.0°C   # CPU graphics controller
TM0P:         +53.0°C   # Memory proximity

BAT0-acpi-0
Adapter: ACPI interface
in0:           8.36 V    # Battery voltage
temp:         +31.7°C    # Battery temp
curr1:         0.00 A    # Current draw
```

## Performance Note

With your system now set to **performance governor**, expect:
- Higher temperatures under load (70-85°C normal)
- Fan running more frequently
- Better performance, more power consumption

This is expected and safe! The MacBook Air is designed for these temps.

---

**Pro Tip**: Run `watch -n 1 'sensors | head -20'` in a terminal to monitor temps while gaming/compiling!
