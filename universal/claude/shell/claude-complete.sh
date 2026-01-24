#!/bin/bash
#
# Claude Code Completion for Bash/Zsh
#
# Installation:
#   # Add to ~/.bashrc or ~/.zshrc:
#   source ~/.claude/shell/claude-complete.sh
#
# Usage:
#   claude /deb<TAB>    # Completes to /systematic-debugging
#   claude /nav<TAB>    # Shows nav-init, nav-start, etc.
#

CLAUDE_COMPLETION_ENGINE="$HOME/.claude/engine/completion-engine.js"

# Get completions from engine
_claude_get_completions() {
    local query="$1"
    local format="${2:-bash}"

    if [[ ! -f "$CLAUDE_COMPLETION_ENGINE" ]]; then
        return 1
    fi

    node "$CLAUDE_COMPLETION_ENGINE" complete "$query" "$format" 2>/dev/null
}

# Record command usage for better suggestions
_claude_record_usage() {
    local cmd="$1"
    if [[ "$cmd" =~ ^/ ]]; then
        node "$CLAUDE_COMPLETION_ENGINE" record "$cmd" 2>/dev/null
    fi
}

# Bash completion function
_claude_bash_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Remove leading slash for query
    local query="${cur#/}"

    # Get completions
    local completions
    completions=$(_claude_get_completions "$query" "bash")

    if [[ -n "$completions" ]]; then
        COMPREPLY=($(compgen -W "$completions" -- "$cur"))
    fi
}

# Zsh completion function
_claude_zsh_complete() {
    local query="${words[CURRENT]#/}"

    # Get completions with descriptions
    local completions
    completions=$(_claude_get_completions "$query" "zsh")

    if [[ -n "$completions" ]]; then
        local -a matches
        while IFS=: read -r cmd desc; do
            matches+=("$cmd:$desc")
        done <<< "$completions"

        _describe 'claude commands' matches
    fi
}

# Wrapper function that records usage
claude_with_history() {
    # Record the first argument if it's a skill
    if [[ "$1" =~ ^/ ]]; then
        _claude_record_usage "$1"
    fi

    # Run claude
    command claude "$@"
}

# Interactive completion browser (requires fzf)
claude_browse() {
    local query="${1:-}"

    if command -v fzf &>/dev/null; then
        local selected
        selected=$(_claude_get_completions "$query" "fzf" | \
            fzf --header="Claude Completions" \
                --delimiter=$'\t' \
                --with-nth=1,2,3 \
                --preview='echo "Type: {2}\nDescription: {3}"' | \
            cut -f1)

        if [[ -n "$selected" ]]; then
            echo "$selected"
        fi
    else
        echo "fzf not installed. Install with: brew install fzf"
        _claude_get_completions "$query" "plain"
    fi
}

# Show completion sources
claude_sources() {
    node "$CLAUDE_COMPLETION_ENGINE" sources 2>/dev/null
}

# Register completions based on shell
if [[ -n "$ZSH_VERSION" ]]; then
    # Zsh
    autoload -Uz compinit
    compinit -u 2>/dev/null

    compdef _claude_zsh_complete claude

    echo "Claude Code completions loaded (zsh). Use Tab after 'claude /' for suggestions."

elif [[ -n "$BASH_VERSION" ]]; then
    # Bash
    complete -F _claude_bash_complete claude

    echo "Claude Code completions loaded (bash). Use Tab after 'claude /' for suggestions."
fi

# Optional: Create alias that tracks usage
# alias claude='claude_with_history'
