#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "postgresql" "stop" "$@"

confirm_stop() {
    if ! lp_confirm "Stop the shared PostgreSQL container? This will affect all running bundles using it."; then
        lp_info "Aborted."
        return 1
    fi
}

stop_postgresql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/postgresql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Stopping PostgreSQL container"
    lp_run docker compose stop
}

main() {
    confirm_stop || return 0
    stop_postgresql_container
    lp_success "PostgreSQL has been stopped."
}

main "$@"
