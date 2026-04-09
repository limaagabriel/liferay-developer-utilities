#!/bin/bash
# Usage: lp bundle reset [-v] [branch]
# If no branch is given, uses the reference branch.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Reset the bundle database and caches (work, temp, osgi/state)."
    echo ""
    echo "Usage: lp bundle reset [-v] [branch]"
    echo ""
    echo "This command removes the following from the bundle directory:"
    echo "  - Tomcat 'work' and 'temp' directories"
    echo "  - OSGi 'state' and 'work' directories"
    echo "  - Hypersonic 'data' directory"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp bundle reset main"
    echo "  lp bundle reset           # uses reference branch"
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

lp_info "Resetting bundle database and caches for branch '$BRANCH'..."

# Finding the Tomcat directory
TOMCAT_DIR=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" | head -n 1)

if [[ -n "$TOMCAT_DIR" ]]; then
    lp_step 1 2 "Cleaning Tomcat caches ($TOMCAT_DIR)"
    lp_run rm -rf "$TOMCAT_DIR/work" "$TOMCAT_DIR/temp" "$TOMCAT_DIR/osgi/state" "$TOMCAT_DIR/osgi/work" "$TOMCAT_DIR/data"
fi

lp_step 2 2 "Cleaning bundle root caches and data"
# Standard Liferay locations for these if they are siblings to Tomcat
lp_run rm -rf "$BUNDLE_DIR/osgi/state" "$BUNDLE_DIR/osgi/work"

# Handling Hypersonic data.
if [[ -d "$BUNDLE_DIR/data" ]]; then
    lp_run rm -rf "$BUNDLE_DIR/data"
fi

lp_success "Bundle database and caches reset successfully for branch '$BRANCH'."
