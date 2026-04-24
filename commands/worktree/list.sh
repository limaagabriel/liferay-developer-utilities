#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "list" "$@"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) shift ;;
        esac
    done
}

list_git_worktrees() {
    lp_info "Active Liferay Portal (Master) worktrees:"
    lp_info "-----------------------------------------"
    git -C "$MAIN_REPO_DIR" worktree list | while read -r line; do
        lp_info "    $line"
    done

    if [[ -d "$EE_REPO_DIR" ]]; then
        lp_info ""
        lp_info "Active Liferay Portal (EE) worktrees:"
        lp_info "-------------------------------------"
        git -C "$EE_REPO_DIR" worktree list | while read -r line; do
            lp_info "    $line"
        done
    fi
}

list_bundle_mappings() {
    lp_info ""
    lp_info "Bundle directories:"
    lp_info "-------------------"
    
    list_bundle_mappings_for_repo "$MAIN_REPO_DIR" "$MAIN_REPO_NAME" "$EE_REPO_DIR"
    
    if [[ -d "$EE_REPO_DIR" ]]; then
        list_bundle_mappings_for_repo "$EE_REPO_DIR" "$(basename "$EE_REPO_DIR")"
    fi
}

list_bundle_mappings_for_repo() {
    local repo_dir="$1"
    local repo_name="$2"
    local exclude_dir="$3"

    for props in "$repo_dir"/app.server.${LIFERAY_USER}.properties "$BASE_PROJECT_DIR"/"$repo_name"-*/app.server.${LIFERAY_USER}.properties; do
        [[ -f "$props" ]] || continue
        
        local worktree_dir
        worktree_dir=$(dirname "$props")
        
        if [[ -n "$exclude_dir" ]] && [[ "$worktree_dir" == "$exclude_dir" ]]; then
            continue
        fi
        
        # We don't want the helper to exit the script if it fails for one entry
        # and we want to suppress its error messages since we're just listing.
        local bundle_dir
        bundle_dir=$(sed -n 's/^[[:space:]]*app.server.parent.dir[[:space:]]*=[[:space:]]*\(.*\)$/\1/p' "$props" | tail -n 1 | tr -d '\r' | xargs)
        
        lp_info "  [$worktree_dir] -> ${bundle_dir:-Unknown}"
    done
}

main() {
    parse_arguments "$@"
    list_git_worktrees
    list_bundle_mappings
}

main "$@"
