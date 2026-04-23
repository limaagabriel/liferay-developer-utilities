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
    lp_info "Cleaning build artifacts..."
    lp_run ant clean
}

clean_git_artifacts() {
    lp_info "Cleaning untracked and ignored files from git..."
    lp_run git clean -fdX
}

main() {
    parse_arguments "$@"
    lp_resolve_branch --reference --default-master --vars
    lp_validate_worktree
    lp_info "Cleaning worktree at '$WORKTREE_DIR'..."
    clean_build_artifacts
    clean_git_artifacts
    lp_success "Worktree cleaned successfully."
}

main "$@"
