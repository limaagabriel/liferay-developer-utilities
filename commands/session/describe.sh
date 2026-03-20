#!/bin/bash
# Usage: lp session describe [branch] <description>
# Sets or updates the description of a development session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Set or update the description of a development session."
    echo ""
    echo "Usage: lp session describe [branch] <description>"
    echo ""
    echo "If [branch] is omitted, it will use the current session's branch."
    echo "Descriptions are shown in 'lp session list'."
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

BRANCH=""
DESCRIPTION=""

# We need to distinguish between branch and description
# If the first argument is an active tmux session, it's the branch.
# Otherwise, we assume the user is in a session and providing a description.

if [[ $# -eq 0 ]]; then
    lp_error "Missing description."
    echo "Usage: lp session describe [branch] <description>"
    exit 1
fi

if tmux has-session -t "$1" 2>/dev/null; then
    BRANCH="$1"
    shift
    DESCRIPTION="$*"
else
    # Check if we are in a tmux session
    if [[ -n "$TMUX" ]]; then
        BRANCH=$(tmux display-message -p '#S')
        DESCRIPTION="$*"
    else
        lp_error "No session specified and not currently in a tmux session."
        echo "Usage: lp session describe [branch] <description>"
        exit 1
    fi
fi

if [[ -z "$DESCRIPTION" ]]; then
    lp_error "Missing description."
    echo "Usage: lp session describe [branch] <description>"
    exit 1
fi

lp_info "Setting description for session '$BRANCH'..."
tmux set-option -t "$BRANCH" @lp-description "$DESCRIPTION"
_lp_update_tmux_status_line "$BRANCH"
lp_success "Description updated."
