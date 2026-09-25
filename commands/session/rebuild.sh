#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "rebuild" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_tmux_session() {
    if [[ -z "$TMUX" ]]; then
        lp_error "Not currently in a tmux session. Please enter a session first."
        return 1 2>/dev/null || exit 1
    fi

    SESSION_NAME=$(tmux display-message -p '#S') || return $?
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
    if ! lp_confirm "Are you sure?"; then
        lp_info "Aborted."
        return 1
    fi
}

stop_server() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Stopping portal in 'bundle' window"
    tmux send-keys -t "$SESSION_NAME:bundle" C-c || return $?
    ((CURRENT_STEP++))
}

wait_for_server_to_stop() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Waiting for server to stop"

    if ! lp_wait_until 60 _lp_bundle_window_idle "$SESSION_NAME"; then
        local current_cmd
        current_cmd=$(tmux display-message -t "$SESSION_NAME:bundle" -p "#{pane_current_command}")
        lp_error "Timed out waiting for server to stop in 'bundle' window."
        lp_info "The 'bundle' window seems to be running: $current_cmd"
        lp_info "You may need to manually stop it or check its state."
        return 1 2>/dev/null || exit 1
    fi

    ((CURRENT_STEP++))
}

send_rebuild_command() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Starting rebuild and restart"

    local build_cmd="lp bundle build -y && lp bundle start"
    tmux send-keys -t "$SESSION_NAME:bundle" "$build_cmd" Enter || return $?

    lp_success "Rebuild and restart commands sent to 'bundle' window."
    ((CURRENT_STEP++))
}

main() {
    check_tmux_session || return $?
    validate_lp_session || return $?
    confirm_action || return 0

    TOTAL_STEPS=3
    CURRENT_STEP=1

    stop_server || return $?
    wait_for_server_to_stop || return $?
    send_rebuild_command || return $?
}

main "$@"
