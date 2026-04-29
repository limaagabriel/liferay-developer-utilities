#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "portal" "setup" "$@"

parse_arguments() {
    VERBOSE=1
    BRANCH=""
    SNAPSHOTS_INCLUDED=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)              VERBOSE=0; shift ;;
            --verbose|-v)            shift ;;
            --snapshots-included|-s) SNAPSHOTS_INCLUDED=1; shift ;;
            --help|-h)               shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?

    cd "$WORKTREE_DIR" || return 1

    local total_steps=2
    [[ $SNAPSHOTS_INCLUDED -eq 1 ]] && total_steps=3
    local step=1

    lp_step "$step" "$total_steps" "Running ant setup-profile-dxp"
    lp_run ant setup-profile-dxp || return $?
    step=$((step + 1))

    lp_step "$step" "$total_steps" "Running ant compile (tooling + portal-kernel snapshot + portal compile)"
    lp_run ant compile || return $?
    step=$((step + 1))

    if [[ $SNAPSHOTS_INCLUDED -eq 1 ]]; then
        lp_step "$step" "$total_steps" "Installing full portal SNAPSHOT set to local .m2 (impl, test, web, util-*)"
        lp_run ant install-portal-snapshots || return $?
    fi

    lp_success "Portal tooling installed in '$WORKTREE_DIR'."
}

main "$@"
