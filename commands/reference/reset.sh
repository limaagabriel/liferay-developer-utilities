#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "reference" "reset" "$@"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) shift ;;
        esac
    done
}

reset_reference_branch() {
    lp_unset_reference_branch
    lp_info "Reference branch reset to master"
}

main() {
    lp_init_command "reference" "reset" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }

    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        lp_error "Error: this command must be sourced to update your session."
        lp_error "Usage: lp reference reset"
        return 1 2>/dev/null || exit 1
    fi

    parse_arguments "$@"
    reset_reference_branch
}

main "$@"
