#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "start" "$@"

BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) shift ;;
        -*)
            lp_error "Unknown option: $1"
            return 1 2>/dev/null || exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

prepare_environment() {
    cd "$_LP_SCRIPTS_DIR/commands/mysql" || { return 1 2>/dev/null || exit 1; }
}

start_mysql_container() {
    lp_step 1 3 "Starting MySQL container"

    if docker ps -a --format '{{.Names}}' | grep -q '^mysql$'; then
        if ! docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
            lp_run docker compose -f ./template.yaml up -d || return $?
        fi
    else
        lp_run docker compose -f ./template.yaml up -d || return $?
    fi
}

wait_for_mysql_ready() {
    lp_step 2 3 "Waiting for MySQL to be ready"
    until docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "select 1" &> /dev/null; do
        sleep 1
    done
}

initialize_database() {
    lp_step 3 3 "Creating database '$BRANCH'"
    
    if docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "show databases;" | grep -q "^$BRANCH$"; then
        lp_info "Database '$BRANCH' already exists, skipping creation."
    else
        lp_run docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "create schema \`$BRANCH\` default character set utf8;" || return $?
    fi
}

main() {
    prepare_environment
    start_mysql_container
    wait_for_mysql_ready
    initialize_database
    lp_success "MySQL is ready."
}

main "$@"
