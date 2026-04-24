#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "add" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_tmux_session() {
    if [[ -z "$TMUX" ]]; then
        lp_error "Not currently in a tmux session. Please enter a session first."
        return 1 2>/dev/null || exit 1
    fi
}

parse_arguments() {
    COMMAND=""
    WINDOW_NAME=""
    HAS_COMMAND_FLAG=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --command|-c)
                HAS_COMMAND_FLAG=true
                if [[ -n "$2" && "$2" != -* ]]; then
                    COMMAND="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --help|-h)    shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$WINDOW_NAME" ]]; then
                    WINDOW_NAME="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ "$HAS_COMMAND_FLAG" == "true" ]]; then
        if [[ -z "$COMMAND" && -n "$WINDOW_NAME" ]]; then
            COMMAND="$WINDOW_NAME"
        elif [[ -n "$COMMAND" && -z "$WINDOW_NAME" ]]; then
            WINDOW_NAME="$COMMAND"
        fi
    fi
}

validate_arguments() {
    if [[ -z "$WINDOW_NAME" ]]; then
        lp_error "Window name is required."
        lp_info "Usage: lp session add [options] <window-name>"
        return 1 2>/dev/null || exit 1
    fi
}

add_window() {
    local session_name
    session_name=$(tmux display-message -p '#S')
    local user_shell="${SHELL:-bash}"
    
    local branch="$session_name"
    local init_cmd="source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp worktree cd \"$branch\" > /dev/null 2>&1;"

    local tmp_cmd
    tmp_cmd=$(mktemp)
    echo "$init_cmd" > "$tmp_cmd"
    [[ -n "$COMMAND" ]] && echo "$COMMAND" >> "$tmp_cmd"
    echo "rm -f \"$tmp_cmd\"" >> "$tmp_cmd"

    lp_step 1 1 "Adding window '$WINDOW_NAME' to session '$session_name'"
    
    # Create window with the initialization and custom command
    tmux new-window -n "$WINDOW_NAME" "$user_shell -ic \"source $tmp_cmd; exec $user_shell\""
}

main() {
    check_tmux_session
    parse_arguments "$@"
    validate_arguments
    add_window
}

main "$@"
