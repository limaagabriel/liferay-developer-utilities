#!/bin/bash
# Usage: lp session restart
# Restarts the server in the 'bundle' window.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Restart the server in the current session."
    echo ""
    echo "Usage: lp session restart"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo ""
    echo "This command MUST be run inside an active lp tmux session."
    echo "It will:"
    echo "  1. Stop the current server in the 'bundle' window (SIGINT)"
    echo "  2. Wait for the process to terminate"
    echo "  3. Run 'lp worktree start' in that window"
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

lp_info "This will stop the portal and restart it."
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
lp_info "Waiting for server to stop..."
while true; do
    PANE_PID=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_pid}")
    FG_PID=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_active_process_pid}")
    
    if [[ "$PANE_PID" == "$FG_PID" ]]; then
        break
    fi
    sleep 1
done

lp_info "Server stopped. Restarting..."

# Send the start command to the bundle window
RESTART_CMD="lp worktree start"
tmux send-keys -t "$SESSION_NAME:bundle" "$RESTART_CMD" Enter

lp_success "Restart command sent to 'bundle' window."
