#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "status" "$@"

list_databases() {
    docker exec -e MYSQL_PWD=root mysql mysql -uroot -N -e "show databases;" 2>/dev/null \
        | grep -vE '^(information_schema|mysql|performance_schema|sys)$'
}

show_mysql_status() {
    if ! docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        lp_info "MySQL container is not running."
        return 0
    fi

    lp_success "MySQL container is running."

    local dbs
    dbs=$(list_databases)

    if [[ -z "$dbs" ]]; then
        lp_info "No user databases."
        return 0
    fi

    local count
    count=$(echo "$dbs" | wc -l)
    lp_info ""
    lp_info "Databases ($count):"
    while IFS= read -r db; do
        lp_info "  - $db"
    done <<< "$dbs"
}

main() {
    show_mysql_status
}

main "$@"
