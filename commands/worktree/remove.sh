#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "remove" "$@"

parse_arguments() {
    DELETE_BRANCH=0
    ASSUME_YES=0
    BRANCHES=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch|-b)  DELETE_BRANCH=1; shift ;;
            --yes|-y)     ASSUME_YES=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCHES+=("$1"); shift ;;
        esac
    done

    if [[ ${#BRANCHES[@]} -eq 0 ]]; then
        local fallback="$(lp_get_reference_branch)"
        BRANCHES=("$fallback")
    fi
}

validate_arguments() {
    for branch in "${BRANCHES[@]}"; do
        if [[ "$branch" == "master" || "$branch" == "ee" ]]; then
            lp_error "Cannot remove the $branch branch."
            return 1 2>/dev/null || exit 1
        fi
    done
}

mysql_running() {
    docker ps --format '{{.Names}}' | grep -q '^mysql$'
}

database_exists() {
    local branch="$1"
    mysql_running || return 1
    local result
    result=$(docker exec -e MYSQL_PWD=root mysql mysql -uroot -N -e \
        "show databases like '$branch';" 2>/dev/null)
    [[ -n "$result" ]]
}

session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

confirm_removal() {
    [[ "$ASSUME_YES" -eq 1 ]] && return 0

    lp_info "The following will be removed:"
    for branch in "${BRANCHES[@]}"; do
        lp_branch_vars "$branch"
        echo "  Branch '$branch':"
        echo "    - worktree: $WORKTREE_DIR"
        echo "    - bundle:   $BUNDLE_DIR"
        session_exists "$branch" && echo "    - session:  $branch"
        database_exists "$branch" && echo "    - database: $branch"
        [[ "$DELETE_BRANCH" -eq 1 ]] && echo "    - branch:   $branch"
    done

    local confirm
    read -p " Proceed? [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        exit 0
    fi
}

count_branch_steps() {
    local branch="$1"
    local total=2
    session_exists "$branch" && ((total++))
    database_exists "$branch" && ((total++))
    [[ "$DELETE_BRANCH" -eq 1 ]] && ((total++))
    echo "$total"
}

process_branch() {
    local branch="$1"
    lp_branch_vars "$branch"

    local total
    total=$(count_branch_steps "$branch")
    local step=1

    if session_exists "$branch"; then
        lp_step $step $total "Stopping active session"
        lp_run tmux kill-session -t "$branch"
        ((step++))
    fi

    lp_step $step $total "Removing worktree '$WORKTREE_DIR'"
    lp_run git -C "$MAIN_REPO_DIR" worktree remove "$WORKTREE_DIR" --force
    ((step++))

    lp_step $step $total "Removing bundle '$BUNDLE_DIR'"
    lp_run rm -rf "$BUNDLE_DIR"
    ((step++))

    if database_exists "$branch"; then
        lp_step $step $total "Dropping database '$branch'"
        lp_run docker exec -e MYSQL_PWD=root mysql mysql -uroot -e \
            "drop database if exists \`$branch\`;"
        ((step++))
    fi

    if [[ "$DELETE_BRANCH" -eq 1 ]]; then
        lp_step $step $total "Deleting local branch '$branch'"
        lp_run git -C "$MAIN_REPO_DIR" branch -D "$branch"
        ((step++))
    fi
}

main() {
    parse_arguments "$@"
    validate_arguments
    confirm_removal

    local total=${#BRANCHES[@]}
    local idx=1
    for branch in "${BRANCHES[@]}"; do
        lp_section "$idx" "$total" "Branch '$branch'" \
            process_branch "$branch"
        ((idx++))
    done

    lp_success "Done!"
}

main "$@"
