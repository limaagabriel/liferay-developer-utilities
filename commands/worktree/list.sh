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

get_bundle_dir() {
    local worktree_dir="$1"
    local props="$worktree_dir/app.server.${LIFERAY_USER}.properties"

    [[ -f "$props" ]] || return 0

    sed -n 's/^[[:space:]]*app.server.parent.dir[[:space:]]*=[[:space:]]*\(.*\)$/\1/p' "$props" \
        | tail -n 1 | tr -d '\r' | xargs
}

print_worktree_list() {
    local repo_dir="$1"
    local paths=() shas=() branches=() bundles=()
    local path="" sha="" branch="" key value
    local branch_w=0 sha_w=0 path_w=0

    flush() {
        [[ -z "$path" ]] && return
        paths+=("$path")
        shas+=("${sha:0:8}")
        branches+=("[${branch:-detached}]")
        bundles+=("$(get_bundle_dir "$path")")
        path="" sha="" branch=""
    }

    while IFS=' ' read -r key value; do
        case "$key" in
            worktree) path="$value" ;;
            HEAD)     sha="$value" ;;
            branch)   branch="${value#refs/heads/}" ;;
            "")       flush ;;
        esac
    done < <(git -C "$repo_dir" worktree list --porcelain)
    flush

    local i
    for i in "${!paths[@]}"; do
        (( ${#branches[$i]} > branch_w )) && branch_w=${#branches[$i]}
        (( ${#shas[$i]} > sha_w )) && sha_w=${#shas[$i]}
        (( ${#paths[$i]} > path_w )) && path_w=${#paths[$i]}
    done

    for i in "${!paths[@]}"; do
        local bundle="${bundles[$i]}"
        if [[ -n "$bundle" ]]; then
            lp_info "$(printf '    %-*s  %-*s  %-*s  -> %s' \
                "$branch_w" "${branches[$i]}" \
                "$sha_w" "${shas[$i]}" \
                "$path_w" "${paths[$i]}" \
                "$bundle")"
        else
            lp_info "$(printf '    %-*s  %-*s  %s' \
                "$branch_w" "${branches[$i]}" \
                "$sha_w" "${shas[$i]}" \
                "${paths[$i]}")"
        fi
    done
}

list_git_worktrees() {
    lp_info "Active Liferay Portal (Master) worktrees:"
    lp_info "-----------------------------------------"
    print_worktree_list "$MAIN_REPO_DIR"

    if [[ -d "$EE_REPO_DIR" ]]; then
        lp_info ""
        lp_info "Active Liferay Portal (EE) worktrees:"
        lp_info "-------------------------------------"
        print_worktree_list "$EE_REPO_DIR"
    fi
}

main() {
    parse_arguments "$@"
    list_git_worktrees
}

main "$@"
