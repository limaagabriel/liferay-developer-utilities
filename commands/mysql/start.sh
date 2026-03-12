#!/bin/bash
# Usage: lp mysql start [-v]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Start MySQL via Docker Compose and reset the database."
    echo ""
    echo "Usage: lp mysql start [-v]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full docker output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp mysql start"
    exit 0
fi

VERBOSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *) shift ;;
    esac
done

cd "$_LP_SCRIPTS_DIR/commands/mysql" || exit 1

lp_step 1 1 "Starting MySQL container"

if docker ps -a --format '{{.Names}}' | grep -q '^mysql$'; then
    lp_run docker compose -f ./template.yaml down
    lp_run docker rm -f mysql &> /dev/null || true
fi

lp_run docker compose -f ./template.yaml up -d

lp_step 2 3 "Waiting for MySQL to be ready"
until docker exec mysql mysql -uroot -proot -e "select 1" &> /dev/null; do
    sleep 1
done

lp_step 3 3 "Creating lportal database"
lp_run docker exec mysql mysql -uroot -proot -e "drop database lportal;"
lp_run docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;"

lp_success "MySQL is ready."
