#!/bin/bash
# Claude Sync Dashboard — Rich TUI with gum + Unicode
# Launched from waybar click or directly
#
# Features:
#   - Real-time sync status with color-coded indicators
#   - Knowledge inventory with growth sparklines
#   - Per-machine health and last sync times
#   - Cortex bridge status
#   - Recent sync events timeline
#   - Learnings browser
#   - Interactive menu (refresh, browse, settings)

set -o pipefail

REPO_DIR="$HOME/claude-cross-machine-sync"
MEMORY_DIR="$HOME/.claude/projects"
LOG_FILE="$HOME/.local/state/omarchy-sync.log"
STATUS_FILE="$HOME/.local/state/omarchy-sync-status.json"
CORTEX_STATUS="$HOME/.local/state/cortex-bridge-status.json"
CORTEX_LOG="$HOME/.local/state/cortex-bridge.log"
SERVICE="omarchy-sync.service"
REGISTRY="$REPO_DIR/machines/registry.yaml"

# ── Colors (Catppuccin Mocha) ─────────────────────────────────────────────────

R='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[38;5;211m'
GREEN='\033[38;5;115m'
YELLOW='\033[38;5;223m'
BLUE='\033[38;5;111m'
PURPLE='\033[38;5;183m'
CYAN='\033[38;5;117m'
TEAL='\033[38;5;116m'
GRAY='\033[38;5;243m'
WHITE='\033[38;5;255m'

# ── Unicode drawing ───────────────────────────────────────────────────────────

H_LINE="━"
H_LINE_DIM="─"
BOX_TL="╭" BOX_TR="╮" BOX_BL="╰" BOX_BR="╯" BOX_V="│" BOX_H="─"
SPARK_CHARS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')

_repeat() { local s="" i; for ((i=0; i<$1; i++)); do s+="$2"; done; echo -n "$s"; }

_bar() {
    local pct="$1" width="${2:-20}" filled empty
    filled=$(( (pct * width + 50) / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0
    empty=$(( width - filled ))
    local color="$GREEN"
    [ "$pct" -ge 60 ] && color="$YELLOW"
    [ "$pct" -ge 85 ] && color="$RED"
    echo -ne "${color}$(_repeat "$filled" "$H_LINE")${GRAY}$(_repeat "$empty" "$H_LINE_DIM")${R}"
}

_section_header() {
    local title="$1" width="${2:-56}"
    local inner=$(( width - 4 ))
    local pad=$(( inner - ${#title} ))
    echo -e "${GRAY}${BOX_TL}$(_repeat "$inner" "$BOX_H")${BOX_TR}${R}"
    echo -e "${GRAY}${BOX_V}${R} ${BOLD}${WHITE}${title}${R}$(_repeat "$((pad - 1))" " ") ${GRAY}${BOX_V}${R}"
    echo -e "${GRAY}${BOX_V}$(_repeat "$inner" "$BOX_H")${BOX_V}${R}"
}

_section_footer() {
    local width="${1:-56}"
    local inner=$(( width - 4 ))
    echo -e "${GRAY}${BOX_BL}$(_repeat "$inner" "$BOX_H")${BOX_BR}${R}"
}

_pad_line() {
    local content="$1" width="${2:-56}"
    # Strip ANSI for length calculation
    local stripped=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( width - 4 - ${#stripped} ))
    [ "$pad" -lt 0 ] && pad=0
    echo -e "${GRAY}${BOX_V}${R} ${content}$(_repeat "$pad" " ") ${GRAY}${BOX_V}${R}"
}

# ── Data collection ───────────────────────────────────────────────────────────

W=56

# Daemon status
daemon_active=false
systemctl --user is-active "$SERVICE" &>/dev/null && daemon_active=true
daemon_uptime=""
if $daemon_active; then
    daemon_uptime=$(systemctl --user show "$SERVICE" --property=ActiveEnterTimestamp --value 2>/dev/null)
    if [ -n "$daemon_uptime" ]; then
        start_epoch=$(date -d "$daemon_uptime" +%s 2>/dev/null || echo 0)
        now=$(date +%s)
        up_s=$(( now - start_epoch ))
        up_d=$(( up_s / 86400 ))
        up_h=$(( (up_s % 86400) / 3600 ))
        up_m=$(( (up_s % 3600) / 60 ))
        if [ "$up_d" -gt 0 ]; then daemon_uptime="${up_d}d ${up_h}h"
        elif [ "$up_h" -gt 0 ]; then daemon_uptime="${up_h}h ${up_m}m"
        else daemon_uptime="${up_m}m"; fi
    fi
fi

# Status file
status_event="" status_detail="" status_machine="" status_ts="" status_age=""
if [ -f "$STATUS_FILE" ]; then
    status_event=$(jq -r '.event // ""' "$STATUS_FILE" 2>/dev/null)
    status_detail=$(jq -r '.detail // ""' "$STATUS_FILE" 2>/dev/null)
    status_machine=$(jq -r '.machine // ""' "$STATUS_FILE" 2>/dev/null)
    status_ts=$(jq -r '.timestamp // ""' "$STATUS_FILE" 2>/dev/null)
    if [ -n "$status_ts" ]; then
        ts_epoch=$(date -d "$status_ts" +%s 2>/dev/null || echo 0)
        now=$(date +%s)
        age=$(( now - ts_epoch ))
        if [ "$age" -lt 60 ]; then status_age="${age}s"
        elif [ "$age" -lt 3600 ]; then status_age="$(( age / 60 ))m"
        else status_age="$(( age / 3600 ))h"; fi
    fi
fi

# Cortex bridge
cortex_event="" cortex_count=0 cortex_ts=""
if [ -f "$CORTEX_STATUS" ]; then
    cortex_event=$(jq -r '.event // ""' "$CORTEX_STATUS" 2>/dev/null)
    cortex_count=$(jq -r '.count // 0' "$CORTEX_STATUS" 2>/dev/null)
    cortex_ts=$(jq -r '.timestamp // ""' "$CORTEX_STATUS" 2>/dev/null)
fi

# Knowledge inventory
_count_knowledge() {
    local dir="$1" pattern="${2:-*.md}"
    ls "$dir"/$pattern 2>/dev/null | wc -l
}

# Find all memory directories
memory_dirs=()
for d in "$HOME/.claude/projects"/*/memory; do
    [ -d "$d" ] && memory_dirs+=("$d")
done
n_memories=0
for d in "${memory_dirs[@]}"; do
    n=$(ls "$d"/*.md 2>/dev/null | grep -cv '/MEMORY\.md$' || echo 0)
    n_memories=$(( n_memories + n ))
done
n_learnings=$(_count_knowledge "$REPO_DIR/learnings")
n_agents=$(_count_knowledge "$HOME/.claude/agents")
n_commands=$(_count_knowledge "$HOME/.claude/commands")
n_skills=$(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l)
n_total=$(( n_memories + n_learnings + n_agents + n_commands + n_skills ))

# Lines of knowledge
mem_lines=0
for d in "${memory_dirs[@]}"; do
    l=$(cat "$d"/*.md 2>/dev/null | wc -l)
    mem_lines=$(( mem_lines + l ))
done
learn_lines=$(cat "$REPO_DIR/learnings"/*.md 2>/dev/null | wc -l)
total_lines=$(( mem_lines + learn_lines ))

# Git stats
cd "$REPO_DIR" 2>/dev/null
commits_today=$(git log --oneline --since="$(date +%Y-%m-%d)" 2>/dev/null | wc -l)
commits_week=$(git log --oneline --since="7 days ago" 2>/dev/null | wc -l)
commits_total=$(git rev-list --count HEAD 2>/dev/null || echo 0)

# Per-machine stats from git
_machine_stats() {
    local machine="$1"
    local last_commit last_ago
    last_commit=$(git log -1 --format="%ar" -- "machines/$machine/" 2>/dev/null)
    local mem_count=$(ls "machines/$machine/memory/"*.md 2>/dev/null | wc -l)
    echo "${last_commit:-never}|${mem_count}"
}

# Machines from registry
machines=()
if [ -f "$REGISTRY" ]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9_-]+):$ ]]; then
            machines+=("${BASH_REMATCH[1]}")
        fi
    done < <(sed -n '/^machines:/,/^[a-z]/p' "$REGISTRY")
fi

# Sync log stats
sync_today=0
if [ -f "$LOG_FILE" ]; then
    today=$(date +%Y-%m-%d)
    sync_today=$(grep -c "^\[$today.*Sync complete\|^\[$today.*knowledge pushed" "$LOG_FILE" 2>/dev/null || echo 0)
fi

# Recent events (cleaned)
recent_events=()
if [ -f "$LOG_FILE" ]; then
    while IFS= read -r line; do
        clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
        if [[ "$clean" =~ ^\[([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2})\]\ (.*) ]]; then
            ts="${BASH_REMATCH[1]}"
            msg="${BASH_REMATCH[2]}"
            time_only=$(date -d "$ts" '+%H:%M' 2>/dev/null || echo "${ts:11:5}")
            [ ${#msg} -gt 42 ] && msg="${msg:0:39}..."
            recent_events+=("${time_only}  ${msg}")
        fi
    done < <(grep -E "(synced|pushed|Change detected|Sync complete|knowledge pushed|Deploy|pulling|Checking)" "$LOG_FILE" 2>/dev/null | tail -8)
fi

# Knowledge growth (commits per day, last 7 days)
growth_data=()
for i in $(seq 6 -1 0); do
    day=$(date -d "$i days ago" +%Y-%m-%d)
    count=$(git log --oneline --since="$day" --until="$(date -d "$((i-1)) days ago" +%Y-%m-%d)" -- machines/*/memory/ learnings/ 2>/dev/null | wc -l)
    growth_data+=("$count")
done

_sparkline() {
    local values=("$@")
    local max=0
    for v in "${values[@]}"; do [ "$v" -gt "$max" ] 2>/dev/null && max="$v"; done
    [ "$max" -eq 0 ] && max=1
    for v in "${values[@]}"; do
        local idx=$(( (v * 7) / max ))
        [ "$idx" -gt 7 ] && idx=7
        [ "$idx" -lt 0 ] && idx=0
        echo -ne "${TEAL}${SPARK_CHARS[$idx]}${R}"
    done
}

# ── Render ────────────────────────────────────────────────────────────────────

clear
echo ""
echo -e "  ${BOLD}${PURPLE}󰑐  Claude Sync Dashboard${R}  ${GRAY}$(date '+%H:%M %b %d')${R}"
echo -e "  ${GRAY}$(_repeat 52 '━')${R}"
echo ""

# ── Daemon Status ─────────────────────────────────────────────────────────────

_section_header "Sync Status" $W

if $daemon_active; then
    _pad_line "${GREEN}${BOLD}  RUNNING${R}  ${GRAY}uptime ${daemon_uptime}${R}" $W
else
    _pad_line "${RED}${BOLD}  STOPPED${R}  ${GRAY}systemctl --user start ${SERVICE}${R}" $W
fi
_pad_line "${GRAY}Event${R}      ${WHITE}${status_event}${R} ${GRAY}(${status_age} ago)${R}" $W
_pad_line "${GRAY}Machine${R}    ${CYAN}${status_machine}${R}" $W
_pad_line "${GRAY}Today${R}      ${WHITE}${sync_today}${R} ${GRAY}syncs${R}  ${GRAY}|${R}  ${WHITE}${commits_today}${R} ${GRAY}commits${R}" $W
_pad_line "${GRAY}This week${R}  ${WHITE}${commits_week}${R} ${GRAY}commits${R}  ${GRAY}|${R}  ${WHITE}${commits_total}${R} ${GRAY}total${R}" $W

_section_footer $W
echo ""

# ── Knowledge Inventory ───────────────────────────────────────────────────────

_section_header "Knowledge" $W

mem_pct=$(( n_memories * 100 / 30 ))
[ "$mem_pct" -gt 100 ] && mem_pct=100
learn_pct=$(( n_learnings * 100 / 30 ))
[ "$learn_pct" -gt 100 ] && learn_pct=100

_pad_line "${PURPLE}󰠲${R}  ${WHITE}Memories${R}     ${BOLD}${n_memories}${R}  $(_bar "$mem_pct" 14)" $W
_pad_line "${BLUE}󰛨${R}  ${WHITE}Learnings${R}    ${BOLD}${n_learnings}${R}  $(_bar "$learn_pct" 14)" $W
_pad_line "${CYAN}󰙨${R}  ${WHITE}Agents${R}       ${BOLD}${n_agents}${R}" $W
_pad_line "${TEAL}󰘳${R}  ${WHITE}Commands${R}     ${BOLD}${n_commands}${R}" $W
_pad_line "${GREEN}󰓥${R}  ${WHITE}Skills${R}       ${BOLD}${n_skills}${R}" $W

echo -e "${GRAY}${BOX_V}$(_repeat 52 "$BOX_H")${BOX_V}${R}"
_pad_line "${GRAY}Total${R}  ${BOLD}${WHITE}${n_total}${R} ${GRAY}items${R}  ${DIM}(${total_lines} lines)${R}" $W

# Growth sparkline
if [ ${#growth_data[@]} -gt 0 ]; then
    spark=$(_sparkline "${growth_data[@]}")
    _pad_line "${GRAY}7-day growth${R}  ${spark}  ${DIM}knowledge commits${R}" $W
fi

_section_footer $W
echo ""

# ── Machines ──────────────────────────────────────────────────────────────────

_section_header "Machines (${#machines[@]})" $W

for machine in "${machines[@]}"; do
    IFS='|' read -r last_ago mem_count <<< "$(_machine_stats "$machine")"

    # Status indicator
    if [ "$machine" = "$status_machine" ]; then
        indicator="${GREEN}●${R}"
    else
        indicator="${GRAY}○${R}"
    fi

    # Color based on recency
    color="$WHITE"
    echo "$last_ago" | grep -q "month\|year" && color="$GRAY"

    display_name=$(echo "$machine" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    _pad_line "${indicator} ${color}${display_name}${R}  ${DIM}${mem_count} memories${R}  ${GRAY}${last_ago}${R}" $W
done

_section_footer $W
echo ""

# ── Cortex Bridge ─────────────────────────────────────────────────────────────

_section_header "Cortex Bridge" $W

if [ -n "$cortex_event" ]; then
    case "$cortex_event" in
        bridged)
            _pad_line "${GREEN}${R}  ${WHITE}${cortex_count} insights bridged${R}" $W
            ;;
        idle)
            _pad_line "${CYAN}󰒲${R}  ${GRAY}Idle (no new insights)${R}" $W
            ;;
        skipped)
            _pad_line "${YELLOW}${R}  ${GRAY}Skipped (cortex data not found)${R}" $W
            ;;
        *)
            _pad_line "${GRAY}${cortex_event}${R}" $W
            ;;
    esac
    if [ -n "$cortex_ts" ]; then
        cortex_ago=""
        ct_epoch=$(date -d "$cortex_ts" +%s 2>/dev/null || echo 0)
        if [ "$ct_epoch" -gt 0 ]; then
            ct_age=$(( $(date +%s) - ct_epoch ))
            if [ "$ct_age" -lt 60 ]; then cortex_ago="${ct_age}s ago"
            elif [ "$ct_age" -lt 3600 ]; then cortex_ago="$(( ct_age / 60 ))m ago"
            else cortex_ago="$(( ct_age / 3600 ))h ago"; fi
        fi
        _pad_line "${GRAY}Last run${R}  ${DIM}${cortex_ago}${R}" $W
    fi
else
    _pad_line "${GRAY}No bridge status available${R}" $W
fi

_section_footer $W
echo ""

# ── Recent Events ─────────────────────────────────────────────────────────────

if [ ${#recent_events[@]} -gt 0 ]; then
    _section_header "Recent Events" $W

    for event in "${recent_events[@]}"; do
        time_part="${event:0:5}"
        msg_part="${event:7}"

        # Color code by event type
        color="$GRAY"
        echo "$msg_part" | grep -qi "sync complete\|pushed" && color="$GREEN"
        echo "$msg_part" | grep -qi "change detected\|deploy" && color="$CYAN"
        echo "$msg_part" | grep -qi "error\|fail" && color="$RED"
        echo "$msg_part" | grep -qi "checking" && color="$DIM"

        _pad_line "${DIM}${time_part}${R}  ${color}${msg_part}${R}" $W
    done

    _section_footer $W
    echo ""
fi

# ── Footer ────────────────────────────────────────────────────────────────────

echo -e "  ${GRAY}Machine: ${CYAN}${status_machine}${R}  ${GRAY}|  Press any key to close${R}"
echo ""

# Wait for keypress
read -rsn1
