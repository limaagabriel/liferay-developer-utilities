#!/bin/bash
# Usage: lp session list
# Lists all active development sessions (tmux) that correspond to git worktrees.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

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
        status=""
        if [[ "$attached" -gt 0 ]]; then
            status=" (attached)"
        fi

        lp_info "  $session ($windows windows)$status"
        found_any=true
    fi
done <<< "$tmux_info"

if ! $found_any; then
    lp_info "No active Liferay Portal sessions found."
fi
