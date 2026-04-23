#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "unset" "$@"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) shift ;;
        esac
    done
}

unset_reference_branch() {
    unset LP_WORKTREE_REFERENCE_BRANCH
    lp_info "Reference branch reset to master"
}

main() {
    # Check if we are being sourced
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to update your session."
        lp_error "Usage: lp worktree unset"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"
    unset_reference_branch
}

main "$@"
