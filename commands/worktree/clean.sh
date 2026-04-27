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

    lp_run git clean -fdX

    for pattern in "${PRESERVED_FILE_PATTERNS[@]}"; do
        cp -rp "$backup"/$pattern . 2>/dev/null || true
    done

    rm -rf "$backup"

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
