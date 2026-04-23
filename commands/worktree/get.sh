#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "get" "$@"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            *) shift ;;
        esac
    done
}

display_reference_branch() {
    lp_info "${LP_WORKTREE_REFERENCE_BRANCH:-master}"
}

main() {
    parse_arguments "$@"
    display_reference_branch
}

main "$@"
