#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "reference" "get" "$@"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) shift ;;
        esac
    done
}

display_reference_branch() {
    lp_info "$(lp_get_reference_branch)"
}

main() {
    lp_init_command "reference" "get" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }
    parse_arguments "$@" || return $?
    display_reference_branch
}

main "$@"
