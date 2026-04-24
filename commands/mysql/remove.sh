#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "remove" "$@"

confirm_removal() {
    local confirm
    read -p "Remove the shared MySQL container? This will destroy ALL databases. [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 0 2>/dev/null || exit 0
    fi
}

remove_mysql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/mysql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Removing MySQL container"
    lp_run docker compose -f template.yaml down -v
}

main() {
    confirm_removal
    remove_mysql_container
    lp_success "MySQL has been removed."
}

main "$@"
