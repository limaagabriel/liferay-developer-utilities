#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "status" "$@"

show_mysql_status() {
    if docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        lp_success "MySQL container is running."
        lp_info "Existing databases:"
        docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "show databases;" | grep -v "Database\|information_schema\|mysql\|performance_schema\|sys"
    else
        lp_info "MySQL container is not running."
    fi
}

main() {
    show_mysql_status
}

main "$@"
