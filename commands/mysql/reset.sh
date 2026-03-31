#!/bin/bash
# Usage: lp mysql reset [-v]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Reset the lportal database (drop and recreate)."
    echo ""
    echo "Usage: lp mysql reset [-v]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full docker output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp mysql reset"
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

lp_step 1 2 "Dropping lportal database"
lp_run docker exec mysql mysql -uroot -proot -e "drop database if exists lportal;"

lp_step 2 2 "Creating lportal database"
lp_run docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;"

lp_success "Database reset complete."
