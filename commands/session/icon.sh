#!/bin/bash
if [[ -z "$_LP_SCRIPTS_DIR" ]]; then
    _LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "icon" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

show_bundle_icon() {
    local session_name="$1"
    if _lp_is_bundle_running "$session_name"; then
        echo " 🚀"
    fi
}

main() {
    show_bundle_icon "$1"
}

main "$@"
