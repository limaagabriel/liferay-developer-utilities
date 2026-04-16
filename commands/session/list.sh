#!/bin/bash
# Usage: lp session list
# Lists all active development sessions (tmux) that correspond to git worktrees.

source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "List all active development sessions (tmux) that correspond to git worktrees."
    echo ""
    echo "Usage: lp session list"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_info "Active Liferay Portal sessions:"
lp_info "-------------------------------"

# Get all tmux sessions with their info
# Format: session_name|windows_count|attached_count
tmux_info=$(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}' 2>/dev/null)

if [[ -z "$tmux_info" ]]; then
    lp_info "No active tmux sessions found."
    exit 0
fi

# Get all active worktree branches
worktree_branches=$(git -C "$MAIN_REPO_DIR" worktree list | grep -o '\[.*\]' | tr -d '[]')

found_any=false
while IFS='|' read -r session windows attached; do
    [[ -z "$session" ]] && continue
    # Check if session matches a worktree branch
    if echo "$worktree_branches" | grep -qxw "$session"; then
        status_parts=()
        if [[ "$attached" -gt 0 ]]; then
            status_parts+=("attached")
        fi

        # Check for description
        description=$(tmux show-option -t "$session" -qv @lp-description)
        if [[ -n "$description" ]]; then
            description=" — $description"
        fi

        # Check for status
        status_name=$(tmux show-option -t "$session" -qv @lp-status)
        emoji=$(_lp_status_emoji "$status_name")
        status_emoji_part=""
        if [[ -n "$emoji" ]]; then
            status_emoji_part=" $emoji"
        fi

        if _lp_is_bundle_running "$session"; then
            status_parts+=("bundle running")
        fi

        status=""
        if [[ ${#status_parts[@]} -gt 0 ]]; then
            # Join parts with comma
            status=" ($(IFS=','; echo "${status_parts[*]}"))"
        fi

        lp_info "  $session ($windows windows)$status$status_emoji_part$description"
        found_any=true
    fi
done <<< "$tmux_info"

if ! $found_any; then
    lp_info "No active Liferay Portal sessions found."
fi
