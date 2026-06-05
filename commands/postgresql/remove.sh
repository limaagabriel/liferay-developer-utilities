#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "postgresql" "remove" "$@"

confirm_removal() {
    if ! lp_confirm "Remove the shared PostgreSQL container? This will destroy ALL databases."; then
        lp_info "Aborted."
        return 1
    fi
}

remove_postgresql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/postgresql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Removing PostgreSQL container"
    lp_run docker compose -f template.yaml down -v
}

main() {
    confirm_removal || return 0
    remove_postgresql_container
    lp_success "PostgreSQL has been removed."
}

main "$@"
