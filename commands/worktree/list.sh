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
    lp_run git -C "$MAIN_REPO_DIR" worktree list

    if [[ -d "$EE_REPO_DIR" ]]; then
        lp_info ""
        lp_info "Active Liferay Portal (EE) worktrees:"
        lp_info "-------------------------------------"
        lp_run git -C "$EE_REPO_DIR" worktree list
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
        
        local bundle_dir
        bundle_dir=$(grep 'app.server.parent.dir' "$props" | cut -d'=' -f2)
        lp_info "  [$worktree_dir] -> $bundle_dir"
    done
}

main() {
    parse_arguments "$@"
    list_git_worktrees
    list_bundle_mappings
}

main "$@"
