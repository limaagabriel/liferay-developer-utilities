#!/bin/bash
if [[ -z "$_LP_SCRIPTS_DIR" ]]; then
    _LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "icon" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

resolve_branch() {
    local session_name="$1"
    local branch
    branch=$(tmux show-option -t "$session_name" -qv @lp-branch 2>/dev/null)
    echo "${branch:-$session_name}"
}

is_bundle_up() {
    local session_name="$1"
    local port="$2"
    _lp_is_bundle_running "$session_name" || return 1
    nc -z localhost "$port" 2>/dev/null
}

show_bundle_icon() {
    local session_name="$1"
    local port
    port=$(lp_bundle_port http "$(resolve_branch "$session_name")")
    is_bundle_up "$session_name" "$port" || return 0
    echo " 🚀 :$port"
}

main() {
    show_bundle_icon "$1" || return $?
}

main "$@"
