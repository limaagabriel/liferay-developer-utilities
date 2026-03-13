#!/bin/bash
# Usage: lp hypersonic clean [-v] [branch]
# If no branch is given, uses the reference branch.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Clean the Hypersonic database in a bundle."
    echo ""
    echo "Usage: lp hypersonic clean [-v] [branch]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp hypersonic clean main"
    echo "  lp hypersonic clean           # uses reference branch"
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

# If no branch is provided, use the reference branch or default to master
BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"

if [[ ! -d "$BUNDLE_DIR" ]]; then
    lp_error "Bundle directory '$BUNDLE_DIR' does not exist."
    exit 1
fi

lp_info "Cleaning Hypersonic database for branch '$BRANCH'..."

# Hypersonic data can be in 'data/hypersonic' or 'data/hsql'
cleaned=0

if [[ -d "$BUNDLE_DIR/data/hypersonic" ]]; then
    lp_step 1 1 "Removing $BUNDLE_DIR/data/hypersonic"
    lp_run rm -rf "$BUNDLE_DIR/data/hypersonic"
    cleaned=1
fi

if [[ -d "$BUNDLE_DIR/data/hsql" ]]; then
    lp_step 1 1 "Removing $BUNDLE_DIR/data/hsql"
    lp_run rm -rf "$BUNDLE_DIR/data/hsql"
    cleaned=1
fi

if [[ $cleaned -eq 0 ]]; then
    lp_info "No Hypersonic database found in '$BUNDLE_DIR/data/'."
else
    lp_success "Hypersonic database cleaned successfully."
fi
