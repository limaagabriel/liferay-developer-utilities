#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "exit" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_tmux_session() {
    if [[ -z "$TMUX" ]]; then
        lp_error "Not currently in a tmux session."
        return 1 2>/dev/null || exit 1
    fi
}

exit_session() {
    lp_info "Exiting session (detaching)..."
    tmux detach-client
}

main() {
    check_tmux_session
    exit_session
}

main "$@"
