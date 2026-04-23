#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "start" "$@"

prepare_environment() {
    cd "$_LP_SCRIPTS_DIR/commands/mysql" || { return 1 2>/dev/null || exit 1; }
}

start_mysql_container() {
    lp_step 1 3 "Starting MySQL container"

    if docker ps -a --format '{{.Names}}' | grep -q '^mysql$'; then
        lp_run docker compose -f ./template.yaml down || return $?
        lp_run docker rm -f mysql &> /dev/null || true
    fi

    lp_run docker compose -f ./template.yaml up -d || return $?
}

wait_for_mysql_ready() {
    lp_step 2 3 "Waiting for MySQL to be ready"
    until docker exec mysql mysql -uroot -proot -e "select 1" &> /dev/null; do
        sleep 1
    done
}

initialize_database() {
    lp_step 3 3 "Creating lportal database"
    lp_run docker exec mysql mysql -uroot -proot -e "drop database if exists lportal;" || return $?
    lp_run docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;" || return $?
}

main() {
    prepare_environment
    start_mysql_container
    wait_for_mysql_ready
    initialize_database
    lp_success "MySQL is ready."
}

main "$@"
