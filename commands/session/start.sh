#!/bin/bash
# Usage: lp session start [branch]
# Starts a new development session using tmux.

source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Start a new development session using tmux."
    echo ""
    echo "Usage: lp session start [options] [branch]"
    echo ""
    echo "Options:"
    echo "  -n, --no-build      Create the bundle window but don't start the build automatically"
    echo "  -b, --build-only    Build the bundle but don't start the server automatically"
    echo "  -d, --description   Add a brief description to the session"
    echo "  -s, --status        Set a status (pending, in-progress, important, ready)"
    echo "  -h, --help          Show this help"
    echo ""
    echo "This command requires 'tmux' to be installed."
    echo ""
    echo "The session will have at least three windows:"
    echo "  1. bundle: Runs 'lp worktree build -s && lp worktree start'"
    echo "  2. git: Opens 'lazygit' (if installed)"
    echo "  3. workspace: A shell for manual commands"
    echo "  (Plus any custom windows defined in your config)"
    echo ""
    echo "All windows will be initialized in the worktree directory."
    exit 0
fi

# Check dependencies
if ! command -v tmux >/dev/null 2>&1; then
    lp_error "'tmux' is not installed. Please install it to use sessions."
    exit 1
fi

SKIP_BUNDLE=false
BUILD_ONLY=false
BRANCH=""
DESCRIPTION=""
STATUS_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-build|-n) SKIP_BUNDLE=true; shift ;;
        --build-only|-b) BUILD_ONLY=true; shift ;;
        --description|-d) DESCRIPTION="$2"; shift 2 ;;
        --status|-s)  STATUS_NAME="$2"; shift 2 ;;
        --help|-h)    shift ;;  # already handled above
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp session start [options] [branch]"
            exit 1
            ;;
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                lp_error "Too many arguments: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

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
    lp_info "Tip: Create the worktree first with 'lp worktree add $BRANCH'"
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
lp worktree cd \"$BRANCH\" > /dev/null 2>&1;
echo \"\";
echo \"  Welcome to your Liferay development session!\";
echo \"\";
echo \"  Window Roles:\";
echo \"    1: bundle       -> The portal bundle and its console output.\";
echo \"    2: git          -> Runs lazygit (if installed) for version control.\";
echo \"    3: workspace    -> Your main shell for navigating and editing the repo.\";
"

if [[ -n "$SESSION_CUSTOM_WINDOWS" ]]; then
    PREAMBLE="$PREAMBLE
echo \"    4+: custom      -> Extra windows from your configuration.\";"
fi

PREAMBLE="$PREAMBLE
echo \"\";
echo \"  Navigation (tmux shortcuts):\";
echo \"    Ctrl+b c       Create a new window (parallel terminal session)\";
echo \"    Ctrl+b &       Kill the current window\";
echo \"    Ctrl+b n       Next window\";
echo \"    Ctrl+b p       Previous window\";
echo \"    Ctrl+b 1-3     Go to specific window (e.g., Ctrl+b 3 for workspace)\";
echo \"    Ctrl+b d       Detach from session (keep it running in background)\";
echo \"\";
echo \"  Scrolling:\";
echo \"    Ctrl+b [       Enter scroll mode (copy mode)\";
echo \"    Use Arrows/PgUp/PgDn to scroll, or mouse wheel if supported.\";
echo \"    Press 'q' to exit scroll mode and return to prompt.\";
echo \"\";
echo \"  Session Commands:\";
echo \"    lp session add <name>     Add a new window to this session\";
echo \"    lp session describe <msg> Update the session description\";
echo \"    lp session status <status> Update the session status (e.g. ready)\";
echo \"    lp session exit           Detach from this session (same as Ctrl+b d)\";
echo \"    lp session enter          Re-enter an existing session\";
echo \"    lp session stop           Stop the bundle and kill the tmux session\";
echo \"\";
exec $USER_SHELL"

if [[ "$SKIP_BUNDLE" == "true" ]]; then
    BUNDLE_COMMAND="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1;
    echo \"\";
    echo \"  Note: Automatic bundle build and start was skipped because the --no-build flag was provided.\";
    echo \"\";
    echo \"  To build and start the bundle, run:\";
    echo \"\";
    echo \"    lp worktree build -s && lp worktree start\";
    echo \"\";
    exec $USER_SHELL"
elif [[ "$BUILD_ONLY" == "true" ]]; then
    BUNDLE_COMMAND="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1 && lp worktree build -s;
    echo \"\";
    echo \"  Note: Automatic server start was skipped because the --build-only flag was provided.\";
    echo \"\";
    echo \"  To start the server, run:\";
    echo \"\";
    echo \"    lp worktree start\";
    echo \"\";
    exec $USER_SHELL"
else
    BUNDLE_COMMAND="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1 && lp worktree build -s && lp worktree start; exec $USER_SHELL"
fi

# Create session with the first window (bundle)
tmux new-session -d -s "$SESSION_NAME" -n "bundle" -c "$WORKTREE_DIR" "$USER_SHELL -ic '$BUNDLE_COMMAND'"

# Set description if provided
if [[ -n "$DESCRIPTION" ]]; then
    tmux set-option -t "$SESSION_NAME" @lp-description "$DESCRIPTION"
fi

# Set status if provided
if [[ -n "$STATUS_NAME" ]]; then
    tmux set-option -t "$SESSION_NAME" @lp-status "$STATUS_NAME"
fi

# Set base index to 1 and move the bundle window to index 1
tmux set-option -t "$SESSION_NAME" base-index 1
tmux move-window -t "$SESSION_NAME:1"

# Customize status bar for this session
_lp_update_tmux_status_line "$SESSION_NAME"
tmux set-window-option -t "$SESSION_NAME" window-status-format "  #I:#W#F "
tmux set-window-option -t "$SESSION_NAME" window-status-current-format "  #I:#W#F "

# Create git window (index 2)
GIT_COMMAND="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1;
if command -v lazygit >/dev/null 2>&1; then
    lazygit;
else
    echo \"\";
    echo \"  This window is intended for git usage.\";
    echo \"  If you install 'lazygit', it will automatically start here.\";
    echo \"\";
    echo \"  Check it out at: https://github.com/jesseduffield/lazygit\";
    echo \"\";
fi; exec $USER_SHELL"

tmux new-window -t "$SESSION_NAME" -n "git" -c "$WORKTREE_DIR" "$USER_SHELL -ic '$GIT_COMMAND'"

# Create workspace window (index 3)
tmux new-window -t "$SESSION_NAME" -n "workspace" -c "$WORKTREE_DIR" "$USER_SHELL -ic '$PREAMBLE'"

# Create custom windows (Option B)
if [[ -n "$SESSION_CUSTOM_WINDOWS" ]]; then
    # Use comma as window delimiter
    IFS=',' read -ra ADDR <<< "$SESSION_CUSTOM_WINDOWS"
    for i in "${ADDR[@]}"; do
        # Use colon as name:command delimiter
        IFSOLD=$IFS
        IFS=':' read -r CUSTOM_NAME CUSTOM_CMD <<< "$i"
        IFS=$IFSOLD
        
        if [[ -n "$CUSTOM_NAME" && -n "$CUSTOM_CMD" ]]; then
            lp_info "Adding custom window '$CUSTOM_NAME'..."
            tmux new-window -t "$SESSION_NAME" -n "$CUSTOM_NAME" -c "$WORKTREE_DIR" "$USER_SHELL -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1; $CUSTOM_CMD; exec $USER_SHELL'"
        fi
    done
fi

# Select the workspace window as default
tmux select-window -t "$SESSION_NAME:workspace"

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
