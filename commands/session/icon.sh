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

show_server_icon() {
    local session_name="$1"
    local port
    port=$(lp_bundle_port http "$(resolve_branch "$session_name")")
    if nc -z localhost "$port" 2>/dev/null; then
        echo "🚀 :$port  "
    else
        echo "🔄  "
    fi
}

show_bundle_icon() {
    local session_name="$1"
    if _lp_is_bundle_building "$session_name"; then
        echo "🔨  "
        return 0
    fi
    _lp_is_bundle_running "$session_name" || return 0
    show_server_icon "$session_name"
}

main() {
    show_bundle_icon "$1" || return $?
}

main "$@"
