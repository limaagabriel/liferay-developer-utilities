#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "list" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    NAMES_ONLY=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --names)       NAMES_ONLY=1; shift ;;
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                lp_error "Too many arguments: $1"
                return 1 2>/dev/null || exit 1
                ;;
        esac
    done
}

bundle_entries() {
    [[ -d "$BUNDLES_DIR" ]] || return 0
    local entry name
    for entry in "$BUNDLES_DIR"/*/; do
        [[ -d "$entry" ]] || continue
        name=$(basename "$entry")
        [[ "$name" == .* ]] && continue
        echo "$name"
    done
}

list_names() {
    bundle_entries
}

list_table() {
    if [[ ! -d "$BUNDLES_DIR" ]]; then
        lp_info "No bundles directory at $BUNDLES_DIR."
        return 0
    fi

    local entries
    entries=$(bundle_entries)
    if [[ -z "$entries" ]]; then
        lp_info "No bundles. Run 'lp bundle build <branch>' to create one."
        return 0
    fi

    printf "  %-24s %-7s %-6s %-6s %-6s %s\n" "BRANCH" "OFFSET" "HTTP" "OSGI" "AGE" "PATH"

    local branch offset http osgi age built_at path
    while IFS= read -r branch; do
        path="$BUNDLES_DIR/$branch"
        offset=$(lp_bundle_offset "$branch")
        http=$(lp_bundle_port http "$branch")
        osgi=$(lp_bundle_port osgi "$branch")
        built_at=$(_lp_bundle_meta_get "$path" "LP_BUNDLE_BUILT_AT")
        age=$(_lp_bundle_format_age "$built_at")
        printf "  %-24s %-7s %-6s %-6s %-6s %s\n" "$branch" "$offset" "$http" "$osgi" "$age" "$path"
    done <<< "$entries"
}

main() {
    parse_arguments "$@" || return $?

    if [[ $NAMES_ONLY -eq 1 ]]; then
        list_names
    else
        list_table
    fi
}

main "$@"
