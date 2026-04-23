#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "status" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_dependencies() {
    if ! command -v tmux >/dev/null 2>&1; then
        lp_error "'tmux' is not installed. Please install it to use sessions."
        return 1 2>/dev/null || exit 1
    fi
}

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        lp_error "Missing status."
        echo "Usage: lp session status [branch] <status>"
        return 1 2>/dev/null || exit 1
    fi

    BRANCH=""
    STATUS_NAME=""

    if tmux has-session -t "$1" 2>/dev/null; then
        BRANCH="$1"
        shift
        STATUS_NAME="$1"
    else
        if [[ -n "$TMUX" ]]; then
            BRANCH=$(tmux display-message -p '#S')
            STATUS_NAME="$1"
        else
            lp_error "No session specified and not currently in a tmux session."
            echo "Usage: lp session status [branch] <status>"
            return 1 2>/dev/null || exit 1
        fi
    fi

    if [[ -z "$STATUS_NAME" ]]; then
        lp_error "Missing status."
        echo "Usage: lp session status [branch] <status>"
        return 1 2>/dev/null || exit 1
    fi
}

validate_status() {
    EMOJI=$(_lp_status_emoji "$STATUS_NAME")
    if [[ -z "$EMOJI" ]]; then
        lp_error "Invalid status: $STATUS_NAME"
        echo "Valid statuses: pending, in-progress, important, ready"
        return 1 2>/dev/null || exit 1
    fi
}

update_status() {
    lp_info "Setting status for session '$BRANCH' to '$STATUS_NAME'..."
    tmux set-option -t "$BRANCH" @lp-status "$STATUS_NAME"
    _lp_update_tmux_status_line "$BRANCH"
}

main() {
    check_dependencies
    parse_arguments "$@"
    validate_status
    update_status
    lp_success "Status updated."
}

main "$@"
