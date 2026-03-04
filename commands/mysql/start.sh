#!/bin/bash
# Usage: lp mysql start [-v]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

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

ORIGINAL_DIR=$(pwd)

lp_step 1 1 "Starting MySQL container"
lp_run docker compose -f ./template.yaml up -d

lp_step 2 2 "Creating lportal database"
lp_run docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;"

cd "$ORIGINAL_DIR"
lp_success "MySQL is ready."
