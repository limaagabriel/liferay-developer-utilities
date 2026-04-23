#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "update" "$@"
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
    STATUS_NAME=""

    if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
        BRANCH="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--describe)
                DESCRIPTION="$2"
                shift 2
                ;;
            -s|--status)
                STATUS_NAME="$2"
                shift 2
                ;;
            *)
                lp_error "Unknown option: $1"
                echo "Usage: lp session update [branch] [-d description] [-s status]"
                return 1 2>/dev/null || exit 1
                ;;
        esac
    done

    if [[ -z "$DESCRIPTION" && -z "$STATUS_NAME" ]]; then
        lp_info "nothing was updated"
        return 0 2>/dev/null || exit 0
    fi
}

detect_session() {
    if [[ -z "$BRANCH" ]]; then
        if [[ -n "$TMUX" ]]; then
            BRANCH=$(tmux display-message -p '#S')
        else
            lp_error "No session specified and not currently in a tmux session."
            echo "Usage: lp session update [branch] [-d description] [-s status]"
            return 1 2>/dev/null || exit 1
        fi
    fi

    if ! tmux has-session -t "$BRANCH" 2>/dev/null; then
        lp_error "Session '$BRANCH' not found."
        return 1 2>/dev/null || exit 1
    fi
}

apply_updates() {
    if [[ -n "$DESCRIPTION" ]]; then
        "$_LP_SCRIPTS_DIR/commands/session/describe.sh" "$BRANCH" "$DESCRIPTION"
    fi

    if [[ -n "$STATUS_NAME" ]]; then
        "$_LP_SCRIPTS_DIR/commands/session/status.sh" "$BRANCH" "$STATUS_NAME"
    fi
}

main() {
    check_dependencies
    parse_arguments "$@"
    detect_session
    apply_updates
}

main "$@"
