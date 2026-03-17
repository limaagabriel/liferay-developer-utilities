#!/bin/bash
# Usage: lp session rebuild
# Rebuilds the current worktree bundle and restarts the server in the 'bundle' window.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Rebuild the current worktree bundle and restart the server."
    echo ""
    echo "Usage: lp session rebuild"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo ""
    echo "This command MUST be run inside an active lp tmux session."
    echo "It will:"
    echo "  1. Stop the current server in the 'bundle' window (SIGINT)"
    echo "  2. Wait for the process to terminate"
    echo "  3. Run 'lp worktree build -y && lp worktree start' in that window"
    exit 0
fi

if [[ -z "$TMUX" ]]; then
    lp_error "Not currently in a tmux session. Please enter a session first."
    exit 1
fi

SESSION_NAME=$(tmux display-message -p '#S')
BRANCH="$SESSION_NAME"

# Verify we are in an lp session by checking for the 'bundle' window
if ! tmux list-windows -t "$SESSION_NAME" -F "#W" | grep -q "^bundle$"; then
    lp_error "Could not find a 'bundle' window in this session. Is this an 'lp' session?"
    exit 1
fi

lp_info "This will stop the portal, rebuild the bundle, and restart it."
printf " Are you sure? [y/N] "
read -r confirm
case "$confirm" in
    [yY]|[yY][eE][sS]) ;;
    *)
        lp_info "Aborted."
        exit 0
        ;;
esac

lp_info "Stopping portal in 'bundle' window..."
tmux send-keys -t "$SESSION_NAME:bundle" C-c

# Wait for the process in the bundle window to finish
# We check if the pane's current command is the shell (meaning the server stopped)
lp_info "Waiting for server to stop..."

# Get the shell name (e.g., bash or zsh)
SHELL_NAME="${SHELL##*/}"
[[ -z "$SHELL_NAME" ]] && SHELL_NAME="bash"

# Add a timeout to prevent infinite loop (e.g., 60 seconds)
MAX_WAIT=60
WAIT_COUNT=0

while true; do
    CURRENT_CMD=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_current_command}")
    
    if [[ "$CURRENT_CMD" == "$SHELL_NAME" || "$CURRENT_CMD" == "zsh" || "$CURRENT_CMD" == "bash" ]]; then
        # Foreground process is the shell itself, meaning the previous command finished
        break
    fi
    
    if [[ $WAIT_COUNT -ge $MAX_WAIT ]]; then
        lp_error "Timed out waiting for server to stop in 'bundle' window."
        lp_info "The 'bundle' window seems to be running: $CURRENT_CMD"
        lp_info "You may need to manually stop it or check its state."
        exit 1
    fi

    sleep 1
    ((WAIT_COUNT++))
done

lp_info "Server stopped. Starting rebuild and restart..."

# Send the build and start command to the bundle window
# We use -ic to ensure aliases and functions (like 'lp') are available if sourced in profile
# But better to use the full path or ensure lp.sh is sourced
BUILD_CMD="lp worktree build -y && lp worktree start"
tmux send-keys -t "$SESSION_NAME:bundle" "$BUILD_CMD" Enter

lp_success "Rebuild and restart commands sent to 'bundle' window."
