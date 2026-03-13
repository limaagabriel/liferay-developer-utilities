#!/bin/bash
# Usage: lp session enter [branch]
# Attaches to an existing tmux session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Enter an existing development session."
    echo ""
    echo "Usage: lp session enter [branch]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
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
    lp_info "Entering session '$SESSION_NAME'..."
    tmux attach-session -t "$SESSION_NAME"
else
    lp_error "Session '$SESSION_NAME' does not exist."
    exit 1
fi
