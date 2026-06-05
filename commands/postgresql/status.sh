#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "postgresql" "status" "$@"

list_databases() {
    docker exec postgresql psql -U postgres -tAc \
        "select datname from pg_database order by datname;" 2>/dev/null \
        | grep -vE '^(postgres|template0|template1)$'
}

show_postgresql_status() {
    if ! docker ps --format '{{.Names}}' | grep -q '^postgresql$'; then
        lp_info "PostgreSQL container is not running."
        return 0
    fi

    lp_success "PostgreSQL container is running."

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
    show_postgresql_status
}

main "$@"
