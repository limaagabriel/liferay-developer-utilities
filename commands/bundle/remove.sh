#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "remove" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
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

confirm_removal() {
    local confirm
    read -p " Remove bundle '$BUNDLE_DIR'? [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 0 2>/dev/null || exit 0
    fi
}

remove_bundle() {
    lp_step 1 1 "Removing bundle directory"
    lp_run rm -rf "$BUNDLE_DIR"
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    confirm_removal
    remove_bundle
    lp_success "Done!"
}

main "$@"
