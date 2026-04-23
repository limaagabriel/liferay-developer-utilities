#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "cd" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
}

check_sourced() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "This script must be sourced to change your current directory."
        lp_info "Run it as:  lp bundle cd <branch-name>"
        return 1 2>/dev/null || exit 1
    fi
}

validate_bundle() {
    local props_file="$WORKTREE_DIR/app.server.${LIFERAY_USER}.properties"

    if [[ ! -f "$props_file" ]]; then
        lp_error "app.server.${LIFERAY_USER}.properties not found at '$WORKTREE_DIR'."
        return 1 2>/dev/null || exit 1
    fi

    BUNDLE_DIR=$(grep 'app.server.parent.dir' "$props_file" | cut -d'=' -f2)

    if [[ ! -d "$BUNDLE_DIR" ]]; then
        lp_error "Bundle directory '$BUNDLE_DIR' does not exist."
        return 1 2>/dev/null || exit 1
    fi
}

change_directory() {
    lp_info "Changing directory to $BUNDLE_DIR..."
    cd "$BUNDLE_DIR" || return 1
}

main() {
    check_sourced
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    validate_bundle
    change_directory
}

main "$@"
