#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "remove" "$@"

parse_arguments() {
    DELETE_BRANCH=0
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch|-b)  DELETE_BRANCH=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
    BRANCH="${BRANCH:-master}"
}

validate_arguments() {
    if [[ "$BRANCH" == "master" || "$BRANCH" == "ee" ]]; then
        lp_error "Cannot remove the $BRANCH branch."
        return 1 2>/dev/null || exit 1
    fi
}

confirm_removal() {
    local confirm
    if [[ "$DELETE_BRANCH" -eq 1 ]]; then
        read -p " Remove worktree '$WORKTREE_DIR', bundle '$BUNDLE_DIR', session '$BRANCH' AND branch '$BRANCH'? [y/N] " confirm
    else
        read -p " Remove worktree '$WORKTREE_DIR', bundle '$BUNDLE_DIR' and session '$BRANCH'? [y/N] " confirm
    fi

    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 0 2>/dev/null || exit 0
    fi
}

get_total_steps() {
    local total=2
    [[ "$DELETE_BRANCH" -eq 1 ]] && ((total++))
    tmux has-session -t "$BRANCH" 2>/dev/null && ((total++))
    echo "$total"
}

stop_session() {
    if tmux has-session -t "$BRANCH" 2>/dev/null; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Stopping active session '$BRANCH'"
        lp_run tmux kill-session -t "$BRANCH"
        ((CURRENT_STEP++))
    fi
}

remove_worktree() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Removing worktree"
    lp_run git -C "$MAIN_REPO_DIR" worktree remove "$WORKTREE_DIR" --force
    ((CURRENT_STEP++))
}

remove_bundle() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Removing bundle directory"
    lp_run rm -rf "$BUNDLE_DIR"
    ((CURRENT_STEP++))
}

delete_branch() {
    if [[ "$DELETE_BRANCH" -eq 1 ]]; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Deleting local branch '$BRANCH'"
        lp_run git -C "$MAIN_REPO_DIR" branch -D "$BRANCH"
    fi
}

drop_database() {
    if docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Dropping database '$BRANCH'"
        docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "drop database if exists \`$BRANCH\`;" &> /dev/null
        ((CURRENT_STEP++))
    fi
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    validate_arguments
    confirm_removal
    
    TOTAL_STEPS=$(get_total_steps)
    # Add step for database if mysql is running
    if docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        ((TOTAL_STEPS++))
    fi

    CURRENT_STEP=1
    
    stop_session
    remove_worktree
    remove_bundle
    drop_database
    delete_branch
    
    lp_success "Done!"
}

main "$@"
