#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "set" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

set_reference_branch() {
    export LP_WORKTREE_REFERENCE_BRANCH="$BRANCH"
    lp_info "Reference branch set to: $LP_WORKTREE_REFERENCE_BRANCH"
}

main() {
    # Check if we are being sourced
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to update your session."
        lp_error "Usage: lp worktree set [branch]"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"
    lp_resolve_branch --require
    set_reference_branch
}

main "$@"
