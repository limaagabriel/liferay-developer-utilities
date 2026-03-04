#!/bin/bash
# Usage: lp worktree remove <branch-name>

set -e

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

BRANCH=$1

if [ -z "$BRANCH" ]; then
    echo "Usage: lp bundle remove <branch-name>"
    exit 1
fi

lp_branch_vars "$BRANCH"

read -p "Remove bundle '$BUNDLE_DIR'? [y/N] " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

echo "Removing bundle directory..."
rm -rf "$BUNDLE_DIR"

echo "Done!"
