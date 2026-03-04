#!/bin/bash
# Usage: source lp bundle cd <branch-name>
# NOTE: This script must be sourced (via `lp bundle cd`) to change the current
#       shell directory. The `lp` function handles this automatically.

# Guard: detect if the script is being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced to change your current directory."
    echo "Run it as:  lp bundle cd <branch-name>"
    exit 1
fi

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Change the current directory to a bundle."
    echo ""
    echo "Usage: lp bundle cd <branch>"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp bundle cd main"
    return 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || return 1

BRANCH=$1

if [[ -z "$BRANCH" ]]; then
    lp_error "Usage: lp bundle cd <branch>"
    return 1
fi

lp_branch_vars "$BRANCH"
PROPS_FILE=$WORKTREE_DIR/app.server.me.properties

if [[ ! -f "$PROPS_FILE" ]]; then
    lp_error "app.server.me.properties not found at '$WORKTREE_DIR'."
    return 1
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$PROPS_FILE" | cut -d'=' -f2)

if [[ ! -d "$BUNDLE_DIR" ]]; then
    lp_error "Bundle directory '$BUNDLE_DIR' does not exist."
    return 1
fi

lp_info "Changing directory to $BUNDLE_DIR..."
cd "$BUNDLE_DIR"
