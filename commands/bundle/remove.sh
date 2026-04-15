#!/bin/bash
# Usage: lp bundle remove [-v] <branch>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Remove a bundle directory."
    echo ""
    echo "Usage: lp bundle remove [-v] <branch>"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp bundle remove main"
    exit 0
fi

VERBOSE=0
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"

read -p " Remove bundle '$BUNDLE_DIR'? [y/N] " confirm
if [[ "$confirm" != "y" ]]; then
    lp_info "Aborted."
    exit 0
fi

lp_step 1 1 "Removing bundle directory"
lp_run rm -rf "$BUNDLE_DIR" || { _lp_exit=$?; return $_lp_exit 2>/dev/null || exit $_lp_exit; }

lp_success "Done!"
