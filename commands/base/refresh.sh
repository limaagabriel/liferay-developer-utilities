#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "refresh" "$@"

parse_arguments() {
    NAME=""
    SOURCE_BRANCH_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch|-b)
                if [[ -n "$2" && "$2" != -* ]]; then
                    SOURCE_BRANCH_ARGS=(-b "$2"); shift 2
                else
                    lp_error "Option $1 requires a branch name."
                    return 1 2>/dev/null || exit 1
                fi
                ;;
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$NAME" ]]; then
                    NAME="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$NAME" ]]; then
        lp_error "Usage: lp base refresh [-b <branch>] <name>"
        return 1 2>/dev/null || exit 1
    fi
}

main() {
    parse_arguments "$@" || return $?
    "$_LP_SCRIPTS_DIR/commands/base/build.sh" --yes "${SOURCE_BRANCH_ARGS[@]}" "$NAME"
}

main "$@"
