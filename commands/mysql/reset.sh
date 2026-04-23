#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "reset" "$@"

drop_database() {
    lp_step 1 2 "Dropping lportal database"
    lp_run docker exec mysql mysql -uroot -proot -e "drop database if exists lportal;"
}

create_database() {
    lp_step 2 2 "Creating lportal database"
    lp_run docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;"
}

main() {
    drop_database
    create_database
    lp_success "Database reset complete."
}

main "$@"
