#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "stop" "$@"

confirm_stop() {
    local confirm
    read -p "Stop the shared MySQL container? This will affect all running bundles using it. [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 0 2>/dev/null || exit 0
    fi
}

stop_mysql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/mysql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Stopping MySQL container"
    lp_run docker compose stop
}

main() {
    confirm_stop
    stop_mysql_container
    lp_success "MySQL has been stopped."
}

main "$@"
