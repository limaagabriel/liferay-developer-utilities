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
        local fallback="${LP_WORKTREE_REFERENCE_BRANCH:-master}"
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

confirm_removal() {
    [[ "$ASSUME_YES" -eq 1 ]] && return 0

    lp_info "The following will be removed:"
    for branch in "${BRANCHES[@]}"; do
        lp_branch_vars "$branch"
        echo "  Branch '$branch':"
        echo "    - worktree: $WORKTREE_DIR"
        echo "    - bundle:   $BUNDLE_DIR"
        echo "    - session:  $branch"
        [[ "$DELETE_BRANCH" -eq 1 ]] && echo "    - branch:   $branch"
    done

    local confirm
    read -p " Proceed? [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        exit 0
    fi
}

count_steps_for_branch() {
    local branch="$1"
    local total=2
    [[ "$DELETE_BRANCH" -eq 1 ]] && ((total++))
    tmux has-session -t "$branch" 2>/dev/null && ((total++))
    docker ps --format '{{.Names}}' | grep -q '^mysql$' && ((total++))
    echo "$total"
}

stop_session() {
    local branch="$1"
    if tmux has-session -t "$branch" 2>/dev/null; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Stopping active session '$branch'"
        lp_run tmux kill-session -t "$branch"
        ((CURRENT_STEP++))
    fi
}

remove_worktree() {
    local wt_dir="$1"
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Removing worktree '$wt_dir'"
    lp_run git -C "$MAIN_REPO_DIR" worktree remove "$wt_dir" --force
    ((CURRENT_STEP++))
}

remove_bundle() {
    local bundle_dir="$1"
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Removing bundle directory '$bundle_dir'"
    lp_run rm -rf "$bundle_dir"
    ((CURRENT_STEP++))
}

drop_database() {
    local branch="$1"
    if docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Dropping database '$branch'"
        lp_run "$_LP_SCRIPTS_DIR/lp.sh" mysql drop --yes "$branch" &> /dev/null
        ((CURRENT_STEP++))
    fi
}

delete_branch() {
    local branch="$1"
    if [[ "$DELETE_BRANCH" -eq 1 ]]; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Deleting local branch '$branch'"
        lp_run git -C "$MAIN_REPO_DIR" branch -D "$branch"
        ((CURRENT_STEP++))
    fi
}

main() {
    parse_arguments "$@"
    validate_arguments
    confirm_removal

    TOTAL_STEPS=0
    for branch in "${BRANCHES[@]}"; do
        TOTAL_STEPS=$((TOTAL_STEPS + $(count_steps_for_branch "$branch")))
    done

    CURRENT_STEP=1
    for branch in "${BRANCHES[@]}"; do
        lp_branch_vars "$branch"
        stop_session "$branch"
        remove_worktree "$WORKTREE_DIR"
        remove_bundle "$BUNDLE_DIR"
        drop_database "$branch"
        delete_branch "$branch"
    done

    lp_success "Done!"
}

main "$@"
