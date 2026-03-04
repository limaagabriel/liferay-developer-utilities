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

source "$_LP_SCRIPTS_DIR/config.sh"

BRANCH=$1

if [ -z "$BRANCH" ]; then
    echo "Usage: lp bundle cd <branch-name>"
    return 1
fi

lp_branch_vars "$BRANCH"
PROPS_FILE=$WORKTREE_DIR/app.server.me.properties

if [ ! -f "$PROPS_FILE" ]; then
    echo "app.server.me.properties not found at '$WORKTREE_DIR'."
    return 1
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$PROPS_FILE" | cut -d'=' -f2)

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Bundle directory '$BUNDLE_DIR' does not exist."
    return 1
fi

echo "Changing directory to $BUNDLE_DIR..."
cd "$BUNDLE_DIR"
