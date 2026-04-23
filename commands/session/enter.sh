#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "enter" "$@"
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

validate_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        lp_error "Session '$SESSION_NAME' does not exist."
        return 1 2>/dev/null || exit 1
    fi
}

enter_session() {
    lp_info "Entering session '$SESSION_NAME'..."
    _lp_set_tmux_titles "$SESSION_NAME"
    tmux attach-session -t "$SESSION_NAME"
}

main() {
    check_dependencies
    parse_arguments "$@"
    validate_session
    enter_session
}

main "$@"
