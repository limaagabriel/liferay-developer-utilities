#!/bin/bash
# lib/session.sh — Session management helpers for lp.

# _lp_status_emoji <status> — return emoji for a session status
_lp_status_emoji() {
    case "$1" in
        pending)     echo "⏳" ;;
        in-progress) echo "🚧" ;;
        important)   echo "🚨" ;;
        ready)       echo "✅" ;;
        *)           echo "" ;;
    esac
}

# _lp_update_tmux_status_line <session_name> — update tmux status-left
_lp_update_tmux_status_line() {
    local session="$1"
    local description status_name emoji status_part
    
    description=$(tmux show-option -t "$session" -qv @lp-description)
    status_name=$(tmux show-option -t "$session" -qv @lp-status)
    emoji=$(_lp_status_emoji "$status_name")
    
    status_part=""
    if [[ -n "$emoji" ]]; then
        status_part="$emoji "
    fi
    
    if [[ -n "$description" ]]; then
        status_part="${status_part}($description) "
    fi
    
    tmux set-option -t "$session" status-left "  #S  $status_part"
    tmux set-option -t "$session" status-left-length 100
}

# _lp_set_tmux_titles <session_name> — set the host terminal title via tmux
_lp_set_tmux_titles() {
    local session="$1"
    
    tmux set-option -t "$session" set-titles on
    tmux set-option -t "$session" set-titles-string "Session #S"
}
