#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "reference" "set" "$@"

parse_arguments() {
    BRANCH=""
    USE_THIS=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            -t|--this|this) USE_THIS=1; shift ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

resolve_this_worktree() {
    if ! lp_detect_worktree; then
        lp_error "Error: --this requires being inside a managed worktree."
        lp_info "Tip: cd into a worktree directory, or pass a branch name explicitly."
        return 1 2>/dev/null || exit 1
    fi
    BRANCH="$LP_DETECTED_BRANCH"
}

set_reference_branch() {
    lp_set_reference_branch "$BRANCH"
    lp_info "Reference branch set to: $(lp_get_reference_branch)"
}

main() {
    lp_init_command "reference" "set" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }

    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to update your session."
        lp_error "Usage: lp reference set [branch]"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"

    if [[ "$USE_THIS" -eq 1 ]]; then
        if [[ -n "$BRANCH" ]]; then
            lp_error "Error: --this cannot be combined with a branch argument."
            return 1 2>/dev/null || exit 1
        fi
        resolve_this_worktree || return $?
    else
        lp_resolve_branch --require
    fi

    set_reference_branch
}

main "$@"
