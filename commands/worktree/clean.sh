#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "clean" "$@"

parse_arguments() {
    BRANCH=""
    ASSUME_YES=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            --yes|-y)     ASSUME_YES=1; shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)            BRANCH="$1"; shift ;;
        esac
    done
}

clean_build_artifacts() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning build artifacts"
    lp_run ant clean || return $?
    ((CURRENT_STEP++))
}

PRESERVED_FILE_PATTERNS=(
    "app.server.*.properties"
    "build.*.properties"
    ".idea"
    "*.iml"
)

clean_git_artifacts() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning untracked and ignored files from git"

    local backup
    backup=$(mktemp -d)

    local pattern
    for pattern in "${PRESERVED_FILE_PATTERNS[@]}"; do
        cp -rp $pattern "$backup/" 2>/dev/null || true
    done

    local clean_status
    lp_run git clean -fdX
    clean_status=$?

    for pattern in "${PRESERVED_FILE_PATTERNS[@]}"; do
        cp -rp "$backup"/$pattern . 2>/dev/null || true
    done

    rm -rf "$backup"

    ((CURRENT_STEP++))
    return "$clean_status"
}

main() {
    parse_arguments "$@" || return $?
    lp_resolve_branch --reference --default-master --vars || return $?
    lp_validate_worktree || return $?
    cd "$WORKTREE_DIR" || return $?

    if [[ $ASSUME_YES -eq 0 ]]; then
        if ! lp_confirm "Clean worktree '$WORKTREE_DIR' (ant clean + git clean -fdX)?"; then
            lp_info "Aborted."
            exit 0
        fi
    fi

    TOTAL_STEPS=2
    CURRENT_STEP=1

    clean_build_artifacts || return $?
    clean_git_artifacts || return $?
    lp_success "Worktree cleaned successfully."
}

main "$@"
