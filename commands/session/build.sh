#!/bin/bash
# Usage: lp session build
# Rebuilds the current worktree bundle and restarts the server in the 'bundle' window.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Rebuild the current worktree bundle and restart the server."
    echo ""
    echo "Usage: lp session build"
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
# We check if the pane is "busy" (running a foreground process)
lp_info "Waiting for server to stop..."
while true; do
    # Get the PID of the foreground process in the pane
    # If it's just the shell, it should be the shell's PID or empty depending on implementation
    # A more reliable way is to check if the pane is at a prompt
    # We'll check if the pane's foreground process is the shell
    PANE_PID=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_pid}")
    FG_PID=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_active_process_pid}")
    
    if [[ "$PANE_PID" == "$FG_PID" ]]; then
        # Foreground process is the shell itself, meaning the previous command finished
        break
    fi
    sleep 1
done

lp_info "Server stopped. Starting rebuild and restart..."

# Send the build and start command to the bundle window
# We use -ic to ensure aliases and functions (like 'lp') are available if sourced in profile
# But better to use the full path or ensure lp.sh is sourced
BUILD_CMD="lp worktree build -y && lp worktree start"
tmux send-keys -t "$SESSION_NAME:bundle" "$BUILD_CMD" Enter

lp_success "Build and start commands sent to 'bundle' window."
