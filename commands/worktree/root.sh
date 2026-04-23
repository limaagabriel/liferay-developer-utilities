#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "root" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

change_to_worktree_root() {
    if [[ -d "$WORKTREE_DIR" ]]; then
        cd "$WORKTREE_DIR" || { return 1 2>/dev/null || exit 1; }
        lp_info "Moved to worktree root: $WORKTREE_DIR ($BRANCH)"
    else
        lp_error "Error: Worktree directory '$WORKTREE_DIR' does not exist for branch '$BRANCH'."
        return 1 2>/dev/null || exit 1
    fi
}

main() {
    # Check if we are being sourced
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to change your directory."
        lp_error "Usage: lp worktree root [branch]"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"
    lp_resolve_branch --reference --default-master --vars
    change_to_worktree_root
}

main "$@"
