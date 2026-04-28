#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "remove" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    NAME=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
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
        lp_error "Usage: lp base remove <name>"
        return 1 2>/dev/null || exit 1
    fi
}

main() {
    parse_arguments "$@" || return $?

    local target="$BASE_BUNDLES_DIR/$NAME"
    if [[ ! -d "$target" ]]; then
        lp_error "Base bundle '$NAME' does not exist at $target."
        return 1
    fi

    lp_step 1 1 "Removing base bundle '$NAME'"
    lp_run rm -rf "$target" || return $?

    lp_success "Base bundle '$NAME' removed."
}

main "$@"
