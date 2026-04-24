#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "clean" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

clean_build_artifacts() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning build artifacts"
    lp_run ant clean
    ((CURRENT_STEP++))
}

clean_git_artifacts() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning untracked and ignored files from git"
    lp_run git clean -fdX
    ((CURRENT_STEP++))
}

main() {
    parse_arguments "$@"
    lp_resolve_branch --reference --default-master --vars
    lp_validate_worktree

    TOTAL_STEPS=2
    CURRENT_STEP=1

    clean_build_artifacts
    clean_git_artifacts
    lp_success "Worktree cleaned successfully."
}

main "$@"
