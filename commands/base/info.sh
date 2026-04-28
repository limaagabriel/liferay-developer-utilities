#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "info" "$@"
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
        lp_error "Usage: lp base info <name>"
        return 1 2>/dev/null || exit 1
    fi
}

main() {
    parse_arguments "$@" || return $?

    local target="$BASE_BUNDLES_DIR/$NAME"
    [[ -d "$target" ]] || { lp_error "Base bundle '$NAME' not found at $target."; return 1; }

    local meta_file="$target/$_LP_BUNDLE_META_FILE"
    lp_info "Base bundle: $NAME"
    lp_info "Path:        $target"

    if [[ -f "$meta_file" ]]; then
        echo ""
        cat "$meta_file"
    else
        lp_info "(no metadata file)"
    fi
}

main "$@"
