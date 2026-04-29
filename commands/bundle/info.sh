#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "info" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$BRANCH" ]]; then
                    BRANCH="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    lp_resolve_branch --reference --default-master
}

main() {
    parse_arguments "$@" || return $?

    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    [[ -d "$BUNDLE_DIR" ]] || {
        lp_error "Bundle for '$BRANCH' not found at $BUNDLE_DIR."
        lp_error "Run 'lp bundle build $BRANCH' first."
        return 1
    }

    local meta_file="$BUNDLE_DIR/$_LP_BUNDLE_META_FILE"
    lp_info "Bundle: $BRANCH"
    lp_info "Path:   $BUNDLE_DIR"

    if [[ -f "$meta_file" ]]; then
        echo ""
        cat "$meta_file"
    else
        lp_info "(no metadata — bundle was built before provenance tracking was added; rebuild to populate)"
    fi

    print_port_table
}

print_port_table() {
    local offset
    offset=$(lp_bundle_offset "$BRANCH")

    echo ""
    lp_info "Port offset: $offset"

    local prefix kind port
    prefix=$(_lp_prefix)
    while IFS=$'\t' read -r kind port; do
        printf '%s%-13s %s\n' "$prefix" "$kind" "$port"
    done < <(lp_bundle_port_table "$BRANCH")
}

main "$@"
