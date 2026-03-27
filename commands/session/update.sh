#!/bin/bash
# Usage: lp session update [branch] [-d description] [-s status]
# Updates the description and/or status of a development session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Update the description and/or status of a development session."
    echo ""
    echo "Usage: lp session update [branch] [-d description] [-s status]"
    echo ""
    echo "Options:"
    echo "  -d, --describe <description>  Set or update the session description"
    echo "  -s, --status <status>        Set or update the session status"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "If [branch] is omitted, it will use the current session's branch."
    echo "Example:"
    echo "  lp session update -d 'Fixing LPS-123' -s 'in-progress'"
    echo "  lp session update main -s 'ready'"
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

BRANCH=""
DESCRIPTION=""
STATUS_NAME=""

# Check if the first argument is a branch (active tmux session)
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    BRANCH="$1"
    shift
fi

# Parse remaining options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--describe)
            DESCRIPTION="$2"
            shift 2
            ;;
        -s|--status)
            STATUS_NAME="$2"
            shift 2
            ;;
        *)
            lp_error "Unknown option: $1"
            echo "Usage: lp session update [branch] [-d description] [-s status]"
            exit 1
            ;;
    esac
done

if [[ -z "$DESCRIPTION" && -z "$STATUS_NAME" ]]; then
    lp_info "nothing was updated"
    exit 0
fi

# If branch is not provided, detect from current session
if [[ -z "$BRANCH" ]]; then
    if [[ -n "$TMUX" ]]; then
        BRANCH=$(tmux display-message -p '#S')
    else
        lp_error "No session specified and not currently in a tmux session."
        echo "Usage: lp session update [branch] [-d description] [-s status]"
        exit 1
    fi
fi

# Verify session exists
if ! tmux has-session -t "$BRANCH" 2>/dev/null; then
    lp_error "Session '$BRANCH' not found."
    exit 1
fi

# Call the respective scripts
if [[ -n "$DESCRIPTION" ]]; then
    "$_LP_SCRIPTS_DIR/commands/session/describe.sh" "$BRANCH" "$DESCRIPTION"
fi

if [[ -n "$STATUS_NAME" ]]; then
    "$_LP_SCRIPTS_DIR/commands/session/status.sh" "$BRANCH" "$STATUS_NAME"
fi
