#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "path" "$@"

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
}

main() {
    lp_init_command "worktree" "path" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }

    parse_arguments "$@" || return $?
    lp_resolve_branch --reference --default-master --vars
    # WHY: lp_validate_worktree prints its tip via lp_info (stdout); keep stdout a bare path.
    lp_validate_worktree >&2 || return $?
    printf '%s\n' "$WORKTREE_DIR"
}

main "$@"
