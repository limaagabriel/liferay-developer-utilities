#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "path" "$@"

parse_arguments() {
    BRANCH=""
    ALLOW_MISSING=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            --allow-missing) ALLOW_MISSING=1; shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

ensure_worktree_exists() {
    [[ "$ALLOW_MISSING" -eq 1 ]] && return 0
    # WHY: lp_validate_worktree prints its tip via lp_info (stdout); keep stdout a bare path.
    lp_validate_worktree >&2
}

main() {
    lp_init_command "worktree" "path" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }

    parse_arguments "$@" || return $?
    lp_resolve_branch --reference --default-master --vars || return $?
    ensure_worktree_exists || return $?
    printf '%s\n' "$WORKTREE_DIR"
}

main "$@"
