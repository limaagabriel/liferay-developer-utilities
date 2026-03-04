#!/bin/bash
# Usage: lp worktree clean [branch-name]
# If no branch is given, uses the current directory.

set -e

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

BRANCH=$1

if [ -z "$BRANCH" ]; then
    WORKTREE_DIR=$(pwd)
else
    lp_branch_vars "$BRANCH"
fi

cd "$WORKTREE_DIR"

echo "Cleaning worktree at '$WORKTREE_DIR'..."

echo " [1/2] Running ant clean..."
ant clean

echo " [2/2] Cleaning git artifacts..."
git clean -fdx -e .idea -e "*.iml" -e app.server.me.properties -e build.me.properties

echo "Worktree cleaned successfully."
