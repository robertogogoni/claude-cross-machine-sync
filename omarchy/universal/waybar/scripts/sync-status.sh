#!/bin/bash
# Claude Sync Status — Waybar module
# Shows knowledge stats + sync state with Nerd Font icons
# Output: JSON {"text":"...", "tooltip":"...", "class":"..."}

STATUS_FILE="$HOME/.local/state/omarchy-sync-status.json"
LOG_FILE="$HOME/.local/state/omarchy-sync.log"
REPO_DIR="$HOME/claude-cross-machine-sync"
MEMORY_DIR="$HOME/.claude/projects/-home-robthepirate/memory"
SERVICE="omarchy-sync.service"

# ── Check daemon ──────────────────────────────────────────────────────────────

daemon_active=false
systemctl --user is-active "$SERVICE" &>/dev/null && daemon_active=true

# ── Read status file ─────────────────────────────────────────────────────────

status_event="" status_detail="" status_machine="" status_ts=""
stale=false age=0

if [ -f "$STATUS_FILE" ]; then
    status_event=$(jq -r '.event // ""' "$STATUS_FILE" 2>/dev/null)
    status_detail=$(jq -r '.detail // ""' "$STATUS_FILE" 2>/dev/null)
    status_machine=$(jq -r '.machine // ""' "$STATUS_FILE" 2>/dev/null)
    status_ts=$(jq -r '.timestamp // ""' "$STATUS_FILE" 2>/dev/null)

    if [ -n "$status_ts" ]; then
        ts_epoch=$(date -d "$status_ts" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        age=$(( now_epoch - ts_epoch ))
        [ "$age" -gt 600 ] && stale=true
    fi
fi

# ── Knowledge inventory ──────────────────────────────────────────────────────

count_files() { ls "$1" 2>/dev/null | wc -l; }
count_md() { ls "$1"/*.md 2>/dev/null | wc -l; }
count_dirs() { ls -d "$1"/*/ 2>/dev/null | wc -l; }

n_memories=$(ls "$MEMORY_DIR"/*.md 2>/dev/null | grep -cv '/MEMORY\.md$')
n_learnings=$(count_md "$REPO_DIR/learnings")
n_agents=$(count_md "$HOME/.claude/agents")
n_commands=$(count_md "$HOME/.claude/commands")
n_skills=$(count_dirs "$HOME/.claude/skills")
n_total=$(( n_memories + n_learnings + n_agents + n_commands + n_skills ))

# Knowledge volume
mem_lines=$(cat "$MEMORY_DIR"/*.md 2>/dev/null | wc -l)
learn_lines=$(cat "$REPO_DIR/learnings"/*.md 2>/dev/null | wc -l)
total_lines=$(( mem_lines + learn_lines ))

# Machines in registry (only entries under the 'machines:' section, before 'platforms:')
n_machines=$(sed -n '/^machines:/,/^[a-z]/p' "$REPO_DIR/machines/registry.yaml" 2>/dev/null | grep -c "^  [a-z].*:$" || echo 0)

# ── Watched directories ──────────────────────────────────────────────────────

watch_count=0
for d in hypr waybar alacritty kitty ghostty walker mako; do
    [ -d "$HOME/.config/$d" ] && (( watch_count++ ))
done
for d in agents commands skills; do
    [ -d "$HOME/.claude/$d" ] && (( watch_count++ ))
done
for d in "$HOME/.claude/projects"/*/memory; do
    [ -d "$d" ] && (( watch_count++ ))
done

# ── Sync stats ───────────────────────────────────────────────────────────────

sync_today=0 sync_total=0
if [ -f "$LOG_FILE" ]; then
    today=$(date +%Y-%m-%d)
    sync_today=$(grep -c "^\[$today.*Sync complete\|^\[$today.*knowledge pushed" "$LOG_FILE" 2>/dev/null || echo 0)
    sync_total=$(grep -c "Sync complete\|knowledge pushed" "$LOG_FILE" 2>/dev/null || echo 0)
fi

# Last knowledge commit
last_knowledge_commit=""
if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    last_knowledge_commit=$(git log -1 --format="%ar: %s" -- machines/*/memory/ learnings/ universal/claude/ 2>/dev/null)
    [ ${#last_knowledge_commit} -gt 55 ] && last_knowledge_commit="${last_knowledge_commit:0:52}..."
fi

# ── Recent events from log ───────────────────────────────────────────────────

last_events=()
if [ -f "$LOG_FILE" ]; then
    while IFS= read -r line; do
        clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
        msg="${clean#*] }"
        [ ${#msg} -gt 55 ] && msg="${msg:0:52}..."
        last_events+=("$msg")
    done < <(grep -E "(synced|pushed|Change detected|Sync complete|knowledge pushed|Deploy complete)" "$LOG_FILE" 2>/dev/null | tail -4)
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

format_ago() {
    local s="$1"
    if [ "$s" -lt 60 ]; then echo "${s}s"
    elif [ "$s" -lt 3600 ]; then echo "$(( s / 60 ))m"
    elif [ "$s" -lt 86400 ]; then echo "$(( s / 3600 ))h"
    else echo "$(( s / 86400 ))d"; fi
}

progress_bar() {
    local n="$1" max="$2" width="${3:-6}"
    [ "$max" -eq 0 ] && max=1
    local filled=$(( (n * width + max/2) / max ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled )) bar=""
    for (( i=0; i<filled; i++ )); do bar+="▰"; done
    for (( i=0; i<empty; i++ )); do bar+="▱"; done
    echo "$bar"
}

# ── Build output ─────────────────────────────────────────────────────────────

if ! $daemon_active; then
    text="󰒍"
    tooltip="Claude Sync  ·  Daemon stopped"
    tooltip+=$'\n'"────────────────────────────"
    tooltip+=$'\n'"  Start: systemctl --user start $SERVICE"
    tooltip+=$'\n'"────────────────────────────"
    tooltip+=$'\n'"  Knowledge: $n_total items ($n_memories memories, $n_learnings learnings)"
    class="sync-off"

elif $stale; then
    text="󰒍"
    tooltip="Claude Sync  ·  Stale ($(format_ago "$age"))"
    tooltip+=$'\n'"────────────────────────────"
    tooltip+=$'\n'"  Machine: $status_machine"
    tooltip+=$'\n'"  Last: $status_event"
    class="sync-warn"

else
    # ── Healthy state ──
    case "$status_event" in
        sync|change) class="sync-active" ;;
        *)           class="sync-ok" ;;
    esac

    ago=""
    [ -n "$status_ts" ] && [ "$ts_epoch" -gt 0 ] && ago="$(format_ago "$age")"

    # Bar text: icon + memory count
    mem_bar=$(progress_bar "$n_memories" 30)
    text="󰑐 ${mem_bar}"

    # ── Tooltip ──
    tooltip="Claude Sync  ·  ${status_machine}"
    tooltip+=$'\n'"────────────────────────────"

    # Knowledge section
    tooltip+=$'\n'"  Knowledge"
    tooltip+=$'\n'"    󰠲  Memories     $n_memories  $(progress_bar "$n_memories" 30 8)"
    tooltip+=$'\n'"    󰛨  Learnings    $n_learnings  $(progress_bar "$n_learnings" 30 8)"
    tooltip+=$'\n'"    󰙨  Agents       $n_agents"
    tooltip+=$'\n'"    󰘳  Commands     $n_commands"
    tooltip+=$'\n'"    󰓥  Skills       $n_skills"
    tooltip+=$'\n'"    ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─"
    tooltip+=$'\n'"    󰗚  Total        $n_total items  (${total_lines} lines)"

    # Sync section
    tooltip+=$'\n'"────────────────────────────"
    tooltip+=$'\n'"  Sync"
    tooltip+=$'\n'"    󰑐  Status       $status_event ${ago:+($ago)}"
    tooltip+=$'\n'"    󰈈  Watching     $watch_count dirs"
    tooltip+=$'\n'"    󰓦  Today        $sync_today syncs"
    tooltip+=$'\n'"    󰊢  Machines     $n_machines registered"

    # Last knowledge commit
    if [ -n "$last_knowledge_commit" ]; then
        tooltip+=$'\n'"────────────────────────────"
        tooltip+=$'\n'"  Last push"
        tooltip+=$'\n'"    $last_knowledge_commit"
    fi

    # Recent events
    if [ ${#last_events[@]} -gt 0 ]; then
        tooltip+=$'\n'"────────────────────────────"
        tooltip+=$'\n'"  Recent"
        for line in "${last_events[@]}"; do
            tooltip+=$'\n'"    $line"
        done
    fi
fi

jq -n -c --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
