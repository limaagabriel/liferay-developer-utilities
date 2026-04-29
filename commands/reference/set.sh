#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "reference" "set" "$@"

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
    lp_resolve_branch --require
    set_reference_branch
}

main "$@"
