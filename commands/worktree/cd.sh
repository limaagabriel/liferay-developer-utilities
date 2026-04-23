#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "cd" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

change_directory() {
    cd "$WORKTREE_DIR" || { return 1 2>/dev/null || exit 1; }
    lp_info "Moved to worktree: $WORKTREE_DIR ($BRANCH)"
}

update_reference() {
    export LP_WORKTREE_REFERENCE_BRANCH="$BRANCH"
}

main() {
    # Check if we are being sourced
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to change your directory."
        lp_error "Usage: lp worktree cd [branch]"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"
    lp_resolve_branch --reference --default-master --vars
    lp_validate_worktree
    change_directory
    update_reference
}

main "$@"
