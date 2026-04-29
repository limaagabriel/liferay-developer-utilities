#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "portal" "setup" "$@"

parse_arguments() {
    VERBOSE=1
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)   VERBOSE=0; shift ;;
            --verbose|-v) shift ;;
            --help|-h)    shift ;;
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

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?

    cd "$WORKTREE_DIR" || return 1

    local total_steps=2
    local step=1

    lp_step "$step" "$total_steps" "Running ant setup-profile-dxp"
    lp_run ant setup-profile-dxp || return $?
    step=$((step + 1))

    lp_step "$step" "$total_steps" "Installing portal tooling (sdk, libs, sass, yarn)"
    lp_run ant setup-sdk setup-libs setup-nodejs-sass setup-yarn || return $?

    lp_success "Portal tooling installed in '$WORKTREE_DIR'."
}

main "$@"
