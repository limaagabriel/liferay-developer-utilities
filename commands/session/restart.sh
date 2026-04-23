#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "restart" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_tmux_context() {
    if [[ -z "$TMUX" ]]; then
        lp_error "Not currently in a tmux session. Please enter a session first."
        return 1 2>/dev/null || exit 1
    fi

    SESSION_NAME=$(tmux display-message -p '#S')
    BRANCH="$SESSION_NAME"
}

verify_lp_session() {
    if ! tmux list-windows -t "$SESSION_NAME" -F "#W" | grep -q "^bundle$"; then
        lp_error "Could not find a 'bundle' window in this session. Is this an 'lp' session?"
        return 1 2>/dev/null || exit 1
    fi
}

confirm_restart() {
    lp_info "This will stop the portal and restart it."
    printf " Are you sure? [y/N] "
    read -r confirm
    case "$confirm" in
        [yY]|[yY][eE][sS]) ;;
        *)
            lp_info "Aborted."
            return 0 2>/dev/null || exit 0
            ;;
    esac
}

stop_portal() {
    lp_info "Stopping portal in 'bundle' window..."
    tmux send-keys -t "$SESSION_NAME:bundle" C-c
}

wait_for_server_to_stop() {
    lp_info "Waiting for server to stop..."

    local shell_name="${SHELL##*/}"
    [[ -z "$shell_name" ]] && shell_name="bash"

    local max_wait=60
    local wait_count=0

    while true; do
        local current_cmd
        current_cmd=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_current_command}")
        
        if [[ "$current_cmd" == "$shell_name" || "$current_cmd" == "zsh" || "$current_cmd" == "bash" ]]; then
            break
        fi
        
        if [[ $wait_count -ge $max_wait ]]; then
            lp_error "Timed out waiting for server to stop in 'bundle' window."
            lp_info "The 'bundle' window seems to be running: $current_cmd"
            lp_info "You may need to manually stop it or check its state."
            return 1 2>/dev/null || exit 1
        fi

        sleep 1
        ((wait_count++))
    done
}

restart_portal() {
    lp_info "Server stopped. Restarting..."
    tmux send-keys -t "$SESSION_NAME:bundle" "lp bundle start" Enter
}

main() {
    check_tmux_context
    verify_lp_session
    confirm_restart
    stop_portal
    wait_for_server_to_stop
    restart_portal
    lp_success "Restart command sent to 'bundle' window."
}

main "$@"
