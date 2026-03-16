#!/bin/bash
# Usage: lp session stop [branch]
# Kills the tmux session and all processes within it (including the bundle).

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Stop a development session."
    echo ""
    echo "Usage: lp session stop [branch]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo ""
    echo "This will kill the tmux session and all running processes within it,"
    echo "effectively stopping the bundle, any git tools, and open shells."
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed."
    exit 1
fi

BRANCH="$1"

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

if [[ -z "$BRANCH" ]]; then
    if lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
    else
        BRANCH="${LP_WORKTREE_REFERENCE_BRANCH:-master}"
    fi
fi

SESSION_NAME="$BRANCH"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    lp_info "Stopping session '$SESSION_NAME'..."
    tmux kill-session -t "$SESSION_NAME"
    lp_success "Session stopped."
else
    lp_error "Session '$SESSION_NAME' does not exist."
    exit 1
fi
