# System Diagnostics Patterns for Linux Performance

**Created**: 2026-03-18
**Context**: Diagnosing Chrome slow loads on Samsung laptop (i7-4510U, 8GB RAM, HDD)

## Diagnostic layers (check in this order)

### 1. Memory pressure (most common bottleneck)
```bash
free -h                              # total/used/available
ps aux --sort=-%mem | head -15       # top consumers
swapon --show                        # swap type (zram vs disk matters!)
```
**Key insight**: zram swap is compressed RAM, not disk I/O. It costs CPU cycles for compression but avoids the catastrophic latency of HDD swap. On 8GB machines with HDD, zram is the right choice.

### 2. CPU load
```bash
uptime                               # load average vs core count
ps aux --sort=-%cpu | head -15       # top consumers
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # governor
```
**Key insight**: Load average > logical core count = saturated. Load 2.44 on 4 cores = CPU-bound.

### 3. Network (often assumed, rarely the cause)
```bash
dig +short google.com                # DNS resolution
ping -c 3 8.8.8.8                    # latency + packet loss
curl -o /dev/null -w "Speed: %{speed_download}" -s "https://speed.cloudflare.com/__down?bytes=10000000"
cat /etc/resolv.conf | grep nameserver  # DNS server
```
**Key insight**: If DNS is <1ms and ping is <5ms, network is NOT the bottleneck. Most "slow page load" complaints on modern connections are CPU/memory, not network.

### 4. Thermal throttling
```bash
for f in /sys/class/thermal/thermal_zone*/temp; do
    zone=$(echo "$f" | grep -oP 'thermal_zone\d+')
    type=$(cat "${f%temp}type" 2>/dev/null)
    temp=$(cat "$f" 2>/dev/null)
    echo "$zone ($type): $((temp/1000))C"
done
```
**Key insight**: Haswell throttles at ~100C. Below 70C is normal under load. Between 70-90C is sustained load but not throttling. Above 90C investigate cooling.

### 5. Disk I/O
```bash
df -h /                              # space
cat /proc/diskstats | grep sda       # I/O stats
```
**Key insight**: HDD vs SSD is the single biggest hardware difference for responsiveness. If system has HDD + Chrome with many extensions, recommend SSD upgrade as #1 hardware change.

### 6. Chrome-specific
```bash
ps aux | grep chrome | wc -l        # process count
ps aux | grep chrome | awk '{sum+=$6} END {printf "%.1f MB\n", sum/1024}'  # total RAM
```
**Key insight**: Each Chrome extension can spawn its own renderer process. 46 extensions = 26 processes = 4.4 GB RAM on a 7.7 GB machine.

### 7. MCP server health (Claude Desktop / CLI)
```bash
# Quick health check: did all servers connect?
grep "started and connected" ~/.config/Claude/logs/mcp.log | tail -14

# Check for disconnects/errors
grep -E "error|disconnected|transport closed" ~/.config/Claude/logs/mcp.log | tail -20

# Per-server stderr (the actual error messages)
tail -20 ~/.config/Claude/logs/mcp-server-<name>.log

# Test a specific npx MCP server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | timeout 10 npx -y <package> 2>&1

# npm cache corruption check (ECOMPROMISED / ENOTEMPTY)
ls ~/.npm/_locks/ 2>/dev/null    # stale locks?
ls ~/.npm/_npx/ 2>/dev/null      # cache exists?

# Fix npm cache corruption
rm -rf ~/.npm/_npx && rm -f ~/.npm/_locks/* && npm cache verify
```
**Key insight**: When multiple npx-based MCP servers fail simultaneously, it's almost always npm cache corruption, not individual server issues. Claude Desktop launches all servers in parallel, causing lock contention. Fix the cache first, investigate individual servers second. See `learnings/mcp-troubleshooting.md` for full playbook.
