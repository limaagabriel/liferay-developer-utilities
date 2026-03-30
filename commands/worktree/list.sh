#!/bin/bash
# Usage: lp worktree list

source "$_LP_SCRIPTS_DIR/lib/output.sh"

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

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_info "Active Liferay Portal (Master) worktrees:"
lp_info "-----------------------------------------"
git -C "$MAIN_REPO_DIR" worktree list

if [[ -d "$EE_REPO_DIR" ]]; then
    lp_info ""
    lp_info "Active Liferay Portal (EE) worktrees:"
    lp_info "-------------------------------------"
    git -C "$EE_REPO_DIR" worktree list
fi

lp_info ""
lp_info "Bundle directories:"
lp_info "-------------------"
# Master and its worktrees
for props in "$MAIN_REPO_DIR"/app.server.me.properties "$BASE_PROJECT_DIR"/"$MAIN_REPO_NAME"-*/app.server.me.properties; do
    [[ -f "$props" ]] || continue
    worktree_dir=$(dirname "$props")
    # Exclude EE repo if it was matched by the glob (since it's handled below)
    [[ "$worktree_dir" == "$EE_REPO_DIR" ]] && continue
    bundle_dir=$(grep 'app.server.parent.dir' "$props" | cut -d'=' -f2)
    lp_info "  [$worktree_dir] -> $bundle_dir"
done

# EE and its worktrees
if [[ -d "$EE_REPO_DIR" ]]; then
    for props in "$EE_REPO_DIR"/app.server.me.properties "$BASE_PROJECT_DIR"/"$(basename "$EE_REPO_DIR")"-*/app.server.me.properties; do
        [[ -f "$props" ]] || continue
        worktree_dir=$(dirname "$props")
        bundle_dir=$(grep 'app.server.parent.dir' "$props" | cut -d'=' -f2)
        lp_info "  [$worktree_dir] -> $bundle_dir"
    done
fi
