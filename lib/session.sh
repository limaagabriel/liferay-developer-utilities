#!/bin/bash
# lib/session.sh — Session management helpers for lp.

# _lp_session_name <branch> — translate a branch name into a tmux-safe session name.
# tmux reserves '.' and ':' as target separators (session:window.pane), so any
# branch containing them (e.g. release-7.4.13.149) breaks `tmux -t` lookups.
_lp_session_name() {
    local name="$1"
    name="${name//./_}"
    name="${name//:/_}"
    echo "$name"
}

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

# _lp_is_bundle_running <session_name> — check if bundle process is running
_lp_is_bundle_running() {
    local session="$1"
    local bundle_pane_tty
    
    # We look for a window named 'bundle' and check if its pane has a relevant process
    bundle_pane_tty=$(tmux list-panes -t "$session:bundle" -F "#{pane_tty}" 2>/dev/null | head -n 1)
    if [[ -z "$bundle_pane_tty" ]]; then
        # Fallback to index 1 if name doesn't match
        bundle_pane_tty=$(tmux list-panes -t "$session:1" -F "#{pane_tty}" 2>/dev/null | head -n 1)
    fi

    if [[ -n "$bundle_pane_tty" ]]; then
        # Check for java, ant, or our start/build scripts running on that TTY
        if ps -t "$bundle_pane_tty" -o args= | grep -E "java|ant|catalina\.sh|/start\.sh|/build\.sh|worktree (build|start)" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# _lp_update_tmux_status_line <session_name> — update tmux status-left
_lp_update_tmux_status_line() {
    local session="$1"
    local description status_name emoji status_part
    
    description=$(tmux show-option -t "$session" -qv @lp-description)
    status_name=$(tmux show-option -t "$session" -qv @lp-status)
    emoji=$(_lp_status_emoji "$status_name")
    
    status_part="$emoji#($_LP_SCRIPTS_DIR/commands/session/icon.sh #S)"

    if [[ -n "$description" ]]; then
        status_part="$status_part ($description)"
    fi

    local label='#{?#{@lp-branch},#{@lp-branch},#S}'
    tmux set-option -t "$session" status-left "  $label  $status_part"
    tmux set-option -t "$session" status-left-length 100
    tmux set-option -t "$session" status-interval 5

    # Also update the terminal title
    _lp_set_tmux_titles "$session"
}

# _lp_set_tmux_titles <session_name> — set the host terminal title via tmux
_lp_set_tmux_titles() {
    local session="$1"
    local description status_name emoji title_string
    
    description=$(tmux show-option -t "$session" -qv @lp-description)
    status_name=$(tmux show-option -t "$session" -qv @lp-status)
    emoji=$(_lp_status_emoji "$status_name")
    
    # Note: Terminal title also supports #(...) format
    local label='#{?#{@lp-branch},#{@lp-branch},#S}'
    title_string="$label $emoji#($_LP_SCRIPTS_DIR/commands/session/icon.sh #S)"
    
    if [[ -n "$description" ]]; then
        title_string="$title_string - $description"
    fi
    
    tmux set-option -t "$session" set-titles on
    tmux set-option -t "$session" set-titles-string "$title_string"
}
