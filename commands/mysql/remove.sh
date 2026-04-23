#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "remove" "$@"

remove_mysql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/mysql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Removing MySQL container"
    lp_run docker compose -f template.yaml down
    lp_run docker rm -f mysql &> /dev/null || true
}

main() {
    remove_mysql_container
    lp_success "MySQL has been removed."
}

main "$@"
