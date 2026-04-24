#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "rebuild" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_tmux_session() {
    if [[ -z "$TMUX" ]]; then
        lp_error "Not currently in a tmux session. Please enter a session first."
        return 1 2>/dev/null || exit 1
    fi

    SESSION_NAME=$(tmux display-message -p '#S')
    BRANCH="$SESSION_NAME"
}

validate_lp_session() {
    if ! tmux list-windows -t "$SESSION_NAME" -F "#W" | grep -q "^bundle$"; then
        lp_error "Could not find a 'bundle' window in this session. Is this an 'lp' session?"
        return 1 2>/dev/null || exit 1
    fi
}

confirm_action() {
    lp_info "This will stop the portal, rebuild the bundle, and restart it."
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

stop_server() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Stopping portal in 'bundle' window"
    tmux send-keys -t "$SESSION_NAME:bundle" C-c
    ((CURRENT_STEP++))
}

wait_for_server_to_stop() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Waiting for server to stop"

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
    ((CURRENT_STEP++))
}

send_rebuild_command() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Starting rebuild and restart"

    local build_cmd="lp bundle build -y && lp bundle start"
    tmux send-keys -t "$SESSION_NAME:bundle" "$build_cmd" Enter

    lp_success "Rebuild and restart commands sent to 'bundle' window."
    ((CURRENT_STEP++))
}

main() {
    check_tmux_session
    validate_lp_session
    confirm_action

    TOTAL_STEPS=3
    CURRENT_STEP=1

    stop_server
    wait_for_server_to_stop
    send_rebuild_command
}

main "$@"
