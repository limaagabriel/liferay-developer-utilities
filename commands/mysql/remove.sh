#!/bin/bash
# Usage: lp mysql remove [-v]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

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

ORIGINAL_DIR=$(pwd)

lp_step 1 1 "Removing MySQL container"
lp_run docker compose -f template.yaml down

lp_success "MySQL has been removed."
