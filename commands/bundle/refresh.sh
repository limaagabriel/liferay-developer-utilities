#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "refresh" "$@"

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

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

run_portal_setup() {
    lp_section "$STEP" "$TOTAL_STEPS" "Running portal setup" \
        "$_LP_SCRIPTS_DIR/commands/portal/setup.sh" "$BRANCH"
    STEP=$((STEP + 1))
}

run_ant_deploy() {
    cd "$WORKTREE_DIR" || return 1

    lp_step "$STEP" "$TOTAL_STEPS" "Running ant deploy"
    lp_run ant deploy || return $?
    STEP=$((STEP + 1))
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    if [[ ! -d "$BUNDLE_DIR" ]]; then
        lp_error "Bundle directory '$BUNDLE_DIR' does not exist. Run 'lp bundle build' first."
        return 1
    fi

    TOTAL_STEPS=2
    STEP=1

    run_portal_setup || return $?
    run_ant_deploy || return $?

    lp_success "Bundle '$BUNDLE_DIR' refreshed."
}

main "$@"
