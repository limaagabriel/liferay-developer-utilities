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

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

confirm_removal() {
    if ! lp_confirm "Remove bundle '$BUNDLE_DIR'?"; then
        lp_info "Aborted."
        return 1
    fi
}

remove_bundle() {
    lp_step 1 1 "Removing bundle directory"
    lp_run rm -rf "$BUNDLE_DIR"
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    confirm_removal || return 0
    remove_bundle
    lp_success "Done!"
}

main "$@"
