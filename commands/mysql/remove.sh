#!/bin/bash
# Usage: lp mysql remove [-v]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Remove MySQL via Docker Compose."
    echo ""
    echo "Usage: lp mysql remove [-v]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full docker output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp mysql remove"
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

lp_step 1 1 "Removing MySQL container"
lp_run docker compose -f template.yaml down || { _lp_exit=$?; return $_lp_exit 2>/dev/null || exit $_lp_exit; }
lp_run docker rm -f mysql &> /dev/null || true

lp_success "MySQL has been removed."
