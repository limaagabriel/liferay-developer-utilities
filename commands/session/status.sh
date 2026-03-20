#!/bin/bash
# Usage: lp session status [branch] <status>
# Sets or updates the status of a development session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Set or update the status of a development session."
    echo ""
    echo "Usage: lp session status [branch] <status>"
    echo ""
    echo "Predefined statuses: pending, in-progress, important, ready"
    echo ""
    echo "If [branch] is omitted, it will use the current session's branch."
    echo "Statuses are shown in 'lp session list' and the tmux status bar."
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

BRANCH=""
STATUS_NAME=""

# We need to distinguish between branch and status
if [[ $# -eq 0 ]]; then
    lp_error "Missing status."
    echo "Usage: lp session status [branch] <status>"
    exit 1
fi

if tmux has-session -t "$1" 2>/dev/null; then
    BRANCH="$1"
    shift
    STATUS_NAME="$1"
else
    # Check if we are in a tmux session
    if [[ -n "$TMUX" ]]; then
        BRANCH=$(tmux display-message -p '#S')
        STATUS_NAME="$1"
    else
        lp_error "No session specified and not currently in a tmux session."
        echo "Usage: lp session status [branch] <status>"
        exit 1
    fi
fi

if [[ -z "$STATUS_NAME" ]]; then
    lp_error "Missing status."
    echo "Usage: lp session status [branch] <status>"
    exit 1
fi

# Validate status
EMOJI=$(_lp_status_emoji "$STATUS_NAME")
if [[ -z "$EMOJI" ]]; then
    lp_error "Invalid status: $STATUS_NAME"
    echo "Valid statuses: pending, in-progress, important, ready"
    exit 1
fi

lp_info "Setting status for session '$BRANCH' to '$STATUS_NAME'..."
tmux set-option -t "$BRANCH" @lp-status "$STATUS_NAME"
_lp_update_tmux_status_line "$BRANCH"

lp_success "Status updated."
