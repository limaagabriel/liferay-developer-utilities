#!/bin/bash
# Usage: lp session start [branch]
# Starts a new development session using tmux.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Start a new development session using tmux."
    echo ""
    echo "Usage: lp session start [branch]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo ""
    echo "This command requires 'tmux' and 'lazygit' to be installed."
    echo ""
    echo "The session will have three windows:"
    echo "  1. bundle: Runs 'lp worktree build -s && lp worktree start'"
    echo "  2. git: Opens 'lazygit'"
    echo "  3. workstation: A shell for manual commands"
    echo ""
    echo "All windows will be initialized in the worktree directory."
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

if ! command -v lazygit >/dev/null 2>&1; then
    lp_error "'lazygit' is not installed. Please install it to use sessions."
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

if [[ "$BRANCH" == "master" ]]; then
    WORKTREE_DIR="$MAIN_REPO_DIR"
else
    lp_branch_vars "$BRANCH"
fi

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree directory '$WORKTREE_DIR' does not exist."
    exit 1
fi

SESSION_NAME="$BRANCH"

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    lp_info "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Detect the current shell
USER_SHELL="${SHELL:-bash}"

lp_info "Starting new session '$SESSION_NAME' at $WORKTREE_DIR using $USER_SHELL..."

# Build preamble
PREAMBLE="
source \"$_LP_SCRIPTS_DIR/lp.sh\";
lp worktree cd \"$BRANCH\";
echo \"\";
echo \"  Welcome to your Liferay development session!\";
echo \"\";
echo \"  Window Roles:\";
echo \"    0: workstation  -> Your main shell for navigating and editing the repo.\";
echo \"    1: git          -> Runs lazygit for all your version control needs.\";
echo \"    2: bundle       -> The running portal bundle and its console output.\";
echo \"\";
echo \"  Navigation (tmux shortcuts):\";
echo \"    Ctrl+b c       Create a new window (parallel terminal session)\";
echo \"    Ctrl+b &       Kill the current window\";
echo \"    Ctrl+b n       Next window\";
echo \"    Ctrl+b p       Previous window\";
echo \"    Ctrl+b 0-2     Go to specific window (e.g., Ctrl+b 0 for workstation)\";
echo \"    Ctrl+b d       Detach from session (keep it running in background)\";
echo \"\";
echo \"  Session Commands:\";
echo \"    lp session add <name>  Add a new window to this session\";
echo \"    lp session exit        Detach from this session (same as Ctrl+b d)\";
echo \"    lp session enter       Re-enter an existing session\";
echo \"    lp session stop        Stop the bundle and kill the tmux session\";
echo \"\";
exec $USER_SHELL"

# Create session with the first window (workstation)
tmux new-session -d -s "$SESSION_NAME" -n "workstation" -c "$WORKTREE_DIR" "$USER_SHELL -ic '$PREAMBLE'"

# Create git window
tmux new-window -t "$SESSION_NAME" -n "git" -c "$WORKTREE_DIR" "$USER_SHELL -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" && lazygit; exec $USER_SHELL'"

# Create bundle window
tmux new-window -t "$SESSION_NAME" -n "bundle" -c "$WORKTREE_DIR" "$USER_SHELL -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" && lp worktree build -s && lp worktree start; exec $USER_SHELL'"

# Customize status bar for this session (add padding)
tmux set-option -t "$SESSION_NAME" status-left "  #S   "
tmux set-option -t "$SESSION_NAME" status-left-length 50
tmux set-window-option -t "$SESSION_NAME" window-status-format "  #I:#W  "
tmux set-window-option -t "$SESSION_NAME" window-status-current-format "  #I:#W  "

# Select the workstation window as default
tmux select-window -t "$SESSION_NAME:workstation"

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
