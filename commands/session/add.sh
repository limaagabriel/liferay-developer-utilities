#!/bin/bash
# Usage: lp session add <window-name>
# Adds a new window to the current tmux session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Add a new window to the current development session."
    echo ""
    echo "Usage: lp session add <window-name>"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    exit 0
fi

if [[ -z "$TMUX" ]]; then
    lp_error "Not currently in a tmux session. Please enter a session first."
    exit 1
fi

WINDOW_NAME="$1"

if [[ -z "$WINDOW_NAME" ]]; then
    lp_error "Window name is required."
    echo "Usage: lp session add <window-name>"
    exit 1
fi

# Get current session name (which is the branch name)
SESSION_NAME=$(tmux display-message -p '#S')
BRANCH="$SESSION_NAME"
USER_SHELL="${SHELL:-bash}"

lp_info "Adding window '$WINDOW_NAME' to session '$SESSION_NAME'..."

# Create the new window
# We explicitly source lp.sh to ensure the 'lp' function is available
tmux new-window -n "$WINDOW_NAME" "$USER_SHELL -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1; exec $USER_SHELL'"
