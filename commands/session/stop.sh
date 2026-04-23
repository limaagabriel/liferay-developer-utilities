#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "stop" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_dependencies() {
    if ! command -v tmux >/dev/null 2>&1; then
        lp_error "'tmux' is not installed."
        return 1 2>/dev/null || exit 1
    fi
}

parse_arguments() {
    BRANCH="$1"

    if [[ -z "$BRANCH" ]]; then
        if lp_detect_worktree; then
            BRANCH="$LP_DETECTED_BRANCH"
        else
            BRANCH="${LP_WORKTREE_REFERENCE_BRANCH:-master}"
        fi
    fi

    SESSION_NAME="$BRANCH"
}

stop_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        lp_info "Stopping session '$SESSION_NAME'..."
        tmux kill-session -t "$SESSION_NAME"
        lp_success "Session stopped."
    else
        lp_error "Session '$SESSION_NAME' does not exist."
        return 1 2>/dev/null || exit 1
    fi
}

main() {
    check_dependencies
    parse_arguments "$@"
    stop_session
}

main "$@"
