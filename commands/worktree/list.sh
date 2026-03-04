#!/bin/bash
# Usage: lp worktree list

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

echo "Active Liferay Portal worktrees:"
echo "---------------------------------"
git -C "$MAIN_REPO_DIR" worktree list

echo ""
echo "Bundle directories:"
echo "-------------------"
for props in "$BASE_PROJECT_DIR"/liferay-portal*/app.server.me.properties; do
    worktree_dir=$(dirname "$props")
    bundle_dir=$(grep 'app.server.parent.dir' "$props" | cut -d'=' -f2)
    echo "  [$worktree_dir] -> $bundle_dir"
done
