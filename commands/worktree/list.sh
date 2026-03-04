#!/bin/bash
# Usage: lp worktree list

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "List all active git worktrees and their bundles."
    echo ""
    echo "Usage: lp worktree list"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree list"
    exit 0
fi

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

lp_info "Active Liferay Portal worktrees:"
lp_info "---------------------------------"
git -C "$MAIN_REPO_DIR" worktree list

lp_info ""
lp_info "Bundle directories:"
lp_info "-------------------"
for props in "$BASE_PROJECT_DIR"/liferay-portal*/app.server.me.properties; do
    worktree_dir=$(dirname "$props")
    bundle_dir=$(grep 'app.server.parent.dir' "$props" | cut -d'=' -f2)
    lp_info "  [$worktree_dir] -> $bundle_dir"
done
