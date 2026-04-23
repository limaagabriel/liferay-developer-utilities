#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "start" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_dependencies() {
    if ! command -v tmux >/dev/null 2>&1; then
        lp_error "'tmux' is not installed. Please install it to use sessions."
        return 1 2>/dev/null || exit 1
    fi
}

parse_arguments() {
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
            --verbose|-v)  shift ;;
            -*)
                lp_error "Unknown option: $1"
                lp_error "Usage: lp session start [options] [branch]"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$BRANCH" ]]; then
                    BRANCH="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    lp_resolve_branch --reference --default-master
}

handle_existing_session() {
    SESSION_NAME="$BRANCH"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        lp_info "Session '$SESSION_NAME' already exists. Attaching..."
        _lp_set_tmux_titles "$SESSION_NAME"
        tmux attach-session -t "$SESSION_NAME"
        return 0 2>/dev/null || exit 0
    fi
}

get_bundle_command() {
    if [[ "$SKIP_BUNDLE" == "true" ]]; then
        echo "source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1;
        echo \"\";
        echo \"  Note: Automatic bundle build and start was skipped because the --no-build flag was provided.\";
        echo \"\";
        echo \"  To build and start the bundle, run:\";
        echo \"\";
        echo \"    lp bundle build -s && lp bundle start\";
        echo \"\""
    elif [[ "$BUILD_ONLY" == "true" ]]; then
        echo "source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1 && lp bundle build -s;
        echo \"\";
        echo \"  Note: Automatic server start was skipped because the --build-only flag was provided.\";
        echo \"\";
        echo \"  To start the server, run:\";
        echo \"\";
        echo \"    lp bundle start\";
        echo \"\""
    else
        echo "source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1 && lp bundle build -s && lp bundle start"
    fi
}

get_git_command() {
    echo "source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1;
    if command -v lazygit >/dev/null 2>&1; then
        lazygit;
    else
        echo \"\";
        echo \"  This window is intended for git usage.\";
        echo \"  If you install lazygit, it will automatically start here.\";
        echo \"\";
        echo \"  Check it out at: https://github.com/jesseduffield/lazygit\";
        echo \"\";
    fi"
}

get_workspace_preamble() {
    cat <<EOF
source "$_LP_SCRIPTS_DIR/lp.sh";
lp worktree cd "$BRANCH" > /dev/null 2>&1;
echo "";
echo "  Welcome to your Liferay development session!";
echo "";
echo "  Window Roles:";
echo "    1: bundle       -> The portal bundle and its console output.";
echo "    2: git          -> Runs lazygit (if installed) for version control.";
echo "    3: workspace    -> Your main shell for navigating and editing the repo.";
$( [[ -n "$SESSION_CUSTOM_WINDOWS" ]] && echo "echo \"    4+: custom      -> Extra windows from your configuration.\";" )
echo "";
echo "  Navigation (tmux shortcuts):";
echo "    Ctrl+b c       Create a new window (parallel terminal session)";
echo "    Ctrl+b &       Kill the current window";
echo "    Ctrl+b n       Next window";
echo "    Ctrl+b p       Previous window";
echo "    Ctrl+b 1-3     Go to specific window (e.g., Ctrl+b 3 for workspace)";
echo "    Ctrl+b d       Detach from session (keep it running in background)";
echo "";
echo "  Scrolling:";
echo "    Ctrl+b [       Enter scroll mode (copy mode)";
echo "    Use Arrows/PgUp/PgDn to scroll, or mouse wheel if supported.";
echo "    Press q to exit scroll mode and return to prompt.";
echo "";
echo "  Session Commands:";
echo "    lp session add <name>     Add a new window to this session";
echo "    lp session describe <msg> Update the session description";
echo "    lp session status <status> Update the session status (e.g. ready)";
echo "    lp session exit           Detach from this session (same as Ctrl+b d)";
echo "    lp session enter          Re-enter an existing session";
EOF
}

setup_tmux_session() {
    USER_SHELL="${SHELL:-bash}"
    lp_info "Starting new session '$SESSION_NAME' at $WORKTREE_DIR using $USER_SHELL..."

    local bundle_cmd
    bundle_cmd=$(get_bundle_command)
    local tmp_bundle
    tmp_bundle=$(mktemp)
    echo "$bundle_cmd" > "$tmp_bundle"
    echo "rm -f \"$tmp_bundle\"" >> "$tmp_bundle"

    # Create session with the bundle command
    tmux new-session -d -s "$SESSION_NAME" -n "bundle" -c "$WORKTREE_DIR" "$USER_SHELL -ic \"source $tmp_bundle; exec $USER_SHELL\""

    # Set base-index to 1 and move the first window from 0 to 1
    tmux set-option -t "$SESSION_NAME" base-index 1
    tmux move-window -t "$SESSION_NAME:0" -t "$SESSION_NAME:1" 2>/dev/null || true

    if [[ -n "$DESCRIPTION" ]]; then
        tmux set-option -t "$SESSION_NAME" @lp-description "$DESCRIPTION"
    fi

    if [[ -n "$STATUS_NAME" ]]; then
        tmux set-option -t "$SESSION_NAME" @lp-status "$STATUS_NAME"
    fi

    _lp_set_tmux_titles "$SESSION_NAME"
    
    _lp_update_tmux_status_line "$SESSION_NAME"
    tmux set-window-option -t "$SESSION_NAME" window-status-format "  #I:#W#F "
    tmux set-window-option -t "$SESSION_NAME" window-status-current-format "  #I:#W#F "
}

add_standard_windows() {
    # Initialize git window (index 2)
    local git_cmd
    git_cmd=$(get_git_command)
    local tmp_git
    tmp_git=$(mktemp)
    echo "$git_cmd" > "$tmp_git"
    echo "rm -f \"$tmp_git\"" >> "$tmp_git"
    tmux new-window -t "$SESSION_NAME" -n "git" -c "$WORKTREE_DIR" "$USER_SHELL -ic \"source $tmp_git; exec $USER_SHELL\""

    # Create and initialize workspace window (index 3)
    local workspace_preamble
    workspace_preamble=$(get_workspace_preamble)
    local tmp_workspace
    tmp_workspace=$(mktemp)
    echo "clear" > "$tmp_workspace"
    echo "$workspace_preamble" >> "$tmp_workspace"
    echo "rm -f \"$tmp_workspace\"" >> "$tmp_workspace"
    tmux new-window -t "$SESSION_NAME" -n "workspace" -c "$WORKTREE_DIR" "$USER_SHELL -ic \"source $tmp_workspace; exec $USER_SHELL\""
}

add_custom_windows() {
    if [[ -n "$SESSION_CUSTOM_WINDOWS" ]]; then
        IFS=',' read -ra ADDR <<< "$SESSION_CUSTOM_WINDOWS"
        for i in "${ADDR[@]}"; do
            IFSOLD=$IFS
            IFS=':' read -r CUSTOM_NAME CUSTOM_CMD <<< "$i"
            IFS=$IFSOLD
            
            if [[ -n "$CUSTOM_NAME" && -n "$CUSTOM_CMD" ]]; then
                lp_info "Adding custom window '$CUSTOM_NAME'..."
                local tmp_custom
                tmp_custom=$(mktemp)
                echo "source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$BRANCH\" > /dev/null 2>&1; $CUSTOM_CMD" > "$tmp_custom"
                echo "rm -f \"$tmp_custom\"" >> "$tmp_custom"
                tmux new-window -t "$SESSION_NAME" -n "$CUSTOM_NAME" -c "$WORKTREE_DIR" "$USER_SHELL -ic \"source $tmp_custom; exec $USER_SHELL\""
            fi
        done
    fi
}

main() {
    check_dependencies || return 1
    parse_arguments "$@" || return 1
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return 1
    handle_existing_session || return 0
    setup_tmux_session
    add_standard_windows
    add_custom_windows
    tmux select-window -t "$SESSION_NAME:workspace"
    tmux attach-session -t "$SESSION_NAME"
}

main "$@"
