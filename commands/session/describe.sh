#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "describe" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_dependencies() {
    if ! command -v tmux >/dev/null 2>&1; then
        lp_error "'tmux' is not installed. Please install it to use sessions."
        return 1 2>/dev/null || exit 1
    fi
}

parse_arguments() {
    BRANCH=""
    DESCRIPTION=""

    if [[ $# -eq 0 ]]; then
        lp_error "Missing description."
        lp_info "Usage: lp session describe [branch] <description>"
        return 1 2>/dev/null || exit 1
    fi

    if tmux has-session -t "$1" 2>/dev/null; then
        BRANCH="$1"
        shift
        DESCRIPTION="$*"
    else
        if [[ -n "$TMUX" ]]; then
            BRANCH=$(tmux display-message -p '#S')
            DESCRIPTION="$*"
        else
            lp_error "No session specified and not currently in a tmux session."
            lp_info "Usage: lp session describe [branch] <description>"
            return 1 2>/dev/null || exit 1
        fi
    fi
}

validate_arguments() {
    if [[ -z "$DESCRIPTION" ]]; then
        lp_error "Missing description."
        lp_info "Usage: lp session describe [branch] <description>"
        return 1 2>/dev/null || exit 1
    fi
}

update_description() {
    lp_info "Setting description for session '$BRANCH'..."
    tmux set-option -t "$BRANCH" @lp-description "$DESCRIPTION"
    _lp_update_tmux_status_line "$BRANCH"
    lp_success "Description updated."
}

main() {
    check_dependencies
    parse_arguments "$@"
    validate_arguments
    update_description
}

main "$@"
