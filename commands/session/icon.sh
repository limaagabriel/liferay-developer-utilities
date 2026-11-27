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

# Tomcat opens the HTTP port at "Server initialization", minutes before the
# portal is ready, so the port alone is not enough: wait for "Server startup".
tomcat_started() {
    local bundle_dir="$1"
    local last_event
    last_event=$(ls -t "$bundle_dir"/tomcat-*/logs/catalina.*.log 2>/dev/null |
        while IFS= read -r log; do
            grep -oE "Server (initialization|startup) in" "$log" | tail -n 1
        done | head -n 1)
    [[ "$last_event" == "Server startup in" ]]
}

show_server_icon() {
    local branch
    branch=$(resolve_branch "$1")
    local port
    port=$(lp_bundle_port http "$branch")
    if nc -z localhost "$port" 2>/dev/null && tomcat_started "$BUNDLES_DIR/$branch"; then
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
