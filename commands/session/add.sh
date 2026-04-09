#!/bin/bash
# Usage: lp session add <window-name>
# Adds a new window to the current tmux session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Add a new window to the current development session."
    echo ""
    echo "Usage: lp session add [options] <window-name>"
    echo ""
    echo "Options:"
    echo "  -c, --command <cmd>  Run a command in the new window"
    echo "  -h, --help           Show this help"
    exit 0
fi

if [[ -z "$TMUX" ]]; then
    lp_error "Not currently in a tmux session. Please enter a session first."
    exit 1
fi

COMMAND=""
WINDOW_NAME=""
HAS_COMMAND_FLAG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --command|-c)
            HAS_COMMAND_FLAG=true
            if [[ -n "$2" && "$2" != -* ]]; then
                COMMAND="$2"
                shift 2
            else
                shift
            fi
            ;;
        --help|-h)    shift ;; # Handled above
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$WINDOW_NAME" ]]; then
                WINDOW_NAME="$1"
            else
                lp_error "Too many arguments: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ "$HAS_COMMAND_FLAG" == "true" ]]; then
    if [[ -z "$COMMAND" && -n "$WINDOW_NAME" ]]; then
        COMMAND="$WINDOW_NAME"
    elif [[ -n "$COMMAND" && -z "$WINDOW_NAME" ]]; then
        WINDOW_NAME="$COMMAND"
    fi
fi

if [[ -z "$WINDOW_NAME" ]]; then
    lp_error "Window name is required."
    echo "Usage: lp session add [options] <window-name>"
    exit 1
fi

# Get current session name (which is the branch name)
SESSION_NAME=$(tmux display-message -p '#S')
BRANCH="$SESSION_NAME"
USER_SHELL="${SHELL:-bash}"

lp_info "Adding window '$WINDOW_NAME' to session '$SESSION_NAME'..."

# Prepare the final command
# We explicitly source lp.sh to ensure the 'lp' function is available
FINAL_CMD="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1;"

if [[ -n "$COMMAND" ]]; then
    FINAL_CMD="$FINAL_CMD $COMMAND;"
fi

FINAL_CMD="$FINAL_CMD exec $USER_SHELL"

# Create the new window
tmux new-window -n "$WINDOW_NAME" "$USER_SHELL -ic '$FINAL_CMD'"
